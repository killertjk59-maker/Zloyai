import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/chat_models.dart';
import '../models/enums.dart';
import '../services/backend_client.dart';
import '../services/preferences_service.dart';
import '../services/tutor_repository.dart';
import 'progress_controller.dart';
import 'settings_controller.dart';

/// Owns the tutor conversation: sending, retrying, offline fallback and the
/// mascot's reaction.
class TutorController extends ChangeNotifier {
  TutorController({
    required PreferencesService prefs,
    required TutorRepository repository,
    required SettingsController settings,
    required ProgressController progress,
  }) {
    _prefs = prefs;
    _repository = repository;
    _settings = settings;
    _progress = progress;
  }

  late final PreferencesService _prefs;
  late final TutorRepository _repository;
  late final SettingsController _settings;
  late final ProgressController _progress;
  final Random _random = Random();

  final List<ChatMessage> _messages = [];
  bool _sending = false;
  TutorException? _lastException;
  MascotMood _mood = MascotMood.idle;
  Timer? _moodTimer;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _sending;
  TutorException? get lastException => _lastException;
  MascotMood get mood => _mood;

  /// True when the last reply came from the on-device checker rather than a
  /// model — the UI labels this everywhere.
  bool get lastWasOffline =>
      _messages.isNotEmpty && _messages.last.source == TutorSource.offline;

  int get _nextId => DateTime.now().microsecondsSinceEpoch % 100000000;

  Future<void> load() async {
    final raw = _prefs.readJson(_prefs.chatKey);
    if (raw == null) return;
    final list = raw['messages'];
    if (list is! List) return;
    for (final item in list) {
      if (item is! Map<String, Object?>) continue;
      _messages.add(
        ChatMessage(
          id: item['id'] as String? ?? '$_nextId',
          role: item['role'] == 'user' ? ChatRole.user : ChatRole.tutor,
          text: item['text'] as String? ?? '',
          createdAt:
              DateTime.tryParse(item['createdAt'] as String? ?? '') ??
              DateTime.now(),
          source: _sourceFromName(item['source'] as String?),
        ),
      );
    }
    notifyListeners();
  }

  TutorSource? _sourceFromName(String? name) {
    if (name == null) return null;
    for (final source in TutorSource.values) {
      if (source.name == name) return source;
    }
    return null;
  }

  Future<void> _persist() async {
    final tail = _messages.length > 40
        ? _messages.sublist(_messages.length - 40)
        : _messages;
    await _prefs.writeJson(_prefs.chatKey, {
      'messages': tail
          .where((m) => m.error == null)
          .map(
            (m) => {
              'id': m.id,
              'role': m.isUser ? 'user' : 'tutor',
              'text': m.text,
              'createdAt': m.createdAt.toIso8601String(),
              'source': m.source?.name,
            },
          )
          .toList(),
    });
  }

  void _setMood(MascotMood mood, {Duration? revertAfter}) {
    _mood = mood;
    notifyListeners();
    _moodTimer?.cancel();
    if (revertAfter != null) {
      _moodTimer = Timer(revertAfter, () {
        _mood = MascotMood.idle;
        notifyListeners();
      });
    }
  }

  /// Sends a message. [grammarFocus] routes to the correction endpoint.
  Future<void> send(String text, {bool grammarFocus = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    _messages.add(ChatMessage.user(id: 'u$_nextId', text: trimmed));
    _sending = true;
    _lastException = null;
    _setMood(MascotMood.thinking);
    notifyListeners();
    await _persist();

    final profile = _settings.profile;
    final appSettings = _settings.settings;

    try {
      final reply = grammarFocus
          ? await _repository.correct(
              text: trimmed,
              profile: profile,
              settings: appSettings,
              history: _historyForRequest(),
            )
          : await _repository.chat(
              message: trimmed,
              profile: profile,
              settings: appSettings,
              history: _historyForRequest(),
            );
      _applyReply(reply);
      await _progress.recordAiMessage();
      final correction = reply.correction;
      if (correction != null && correction.changed) {
        await _progress.recordMistake(
          MistakeRecord(
            id: 'm${DateTime.now().microsecondsSinceEpoch}',
            original: correction.original,
            corrected: correction.corrected,
            explanation: correction.explanation,
            rule: correction.rule,
            createdAt: DateTime.now(),
          ),
        );
      }
    } on TutorException catch (e) {
      _lastException = e;
      _messages.add(
        ChatMessage.tutor(id: 't$_nextId', text: '', error: e.message),
      );
      _setMood(MascotMood.incorrect, revertAfter: const Duration(seconds: 3));
    } catch (e) {
      _lastException = TutorException(
        TutorErrorKind.unknown,
        'Unexpected error while contacting the tutor.',
        detail: e.runtimeType.toString(),
      );
      _messages.add(
        ChatMessage.tutor(
          id: 't$_nextId',
          text: '',
          error: _lastException!.message,
        ),
      );
      _setMood(MascotMood.incorrect, revertAfter: const Duration(seconds: 3));
    } finally {
      _sending = false;
      notifyListeners();
      await _persist();
    }
  }

  List<ChatMessage> _historyForRequest() {
    final cleaned = _messages
        .where((m) => m.error == null && !m.pending)
        .toList();
    return cleaned.length > 10 ? cleaned.sublist(cleaned.length - 10) : cleaned;
  }

  void _applyReply(TutorReply reply) {
    final correction = reply.correction;
    final madeMistake = correction != null && correction.changed;
    _messages.add(
      ChatMessage.tutor(
        id: 't$_nextId',
        text: reply.reply,
        correction: correction,
        source: reply.source,
      ),
    );
    if (madeMistake) {
      _setMood(MascotMood.incorrect, revertAfter: const Duration(seconds: 5));
    } else if (reply.source == TutorSource.offline) {
      _setMood(MascotMood.encourage, revertAfter: const Duration(seconds: 3));
    } else {
      _setMood(MascotMood.correct, revertAfter: const Duration(seconds: 4));
    }
  }

  /// Re-runs the request that produced the most recent error message.
  Future<void> retryLast() async {
    final errorIndex = _messages.lastIndexWhere((m) => m.error != null);
    if (errorIndex == -1 || _sending) return;
    // Find the user message that triggered it.
    var userIndex = errorIndex - 1;
    while (userIndex >= 0 && !_messages[userIndex].isUser) {
      userIndex--;
    }
    if (userIndex < 0) return;
    final text = _messages[userIndex].text;
    _messages.removeRange(userIndex, _messages.length);
    notifyListeners();
    await send(text);
  }

  /// Explicit, user-triggered offline check for the failed message.
  Future<void> useOfflineFallback() async {
    final errorIndex = _messages.lastIndexWhere((m) => m.error != null);
    if (errorIndex == -1) return;
    var userIndex = errorIndex - 1;
    while (userIndex >= 0 && !_messages[userIndex].isUser) {
      userIndex--;
    }
    if (userIndex < 0) return;
    final text = _messages[userIndex].text;
    _messages.removeRange(userIndex + 1, _messages.length);
    final reply = _repository.correctOffline(
      text: text,
      profile: _settings.profile,
      settings: _settings.settings,
    );
    _applyReply(reply);
    _moodTimer?.cancel();
    _mood = MascotMood.encourage;
    notifyListeners();
    await _persist();
  }

  /// Local-only check without touching the network (used by "Check offline").
  Future<void> checkOffline(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _messages.add(ChatMessage.user(id: 'u$_nextId', text: trimmed));
    final reply = _repository.correctOffline(
      text: trimmed,
      profile: _settings.profile,
      settings: _settings.settings,
    );
    _applyReply(reply);
    notifyListeners();
    await _persist();
  }

  void setVoiceMood(MascotMood mood) {
    _setMood(mood, revertAfter: const Duration(seconds: 4));
  }

  /// A friendly opening line, localised and personality aware.
  String greeting(ExplanationLanguage lang, PersonalityMode mode, String name) {
    final who = name.trim().isEmpty ? '' : ', ${name.trim()}';
    final options = <PersonalityMode, Map<ExplanationLanguage, String>>{
      PersonalityMode.normal: {
        ExplanationLanguage.tajik:
            'Салом$who! Ман ZLOY ҳастам. Ҷумла нависед — ман ислоҳ мекунам ва '
            'шарҳ медиҳам.',
        ExplanationLanguage.russian:
            'Привет$who! Я ZLOY. Напиши предложение — я исправлю и объясню.',
        ExplanationLanguage.english:
            'Hi$who! I am ZLOY. Write a sentence — I will correct it and '
            'explain why.',
      },
      PersonalityMode.strict: {
        ExplanationLanguage.tajik:
            'Салом$who. Ман ZLOY ҳастам. Ҷумла нависед. Хато бошад — ислоҳ '
            'мекунам, баҳона нашунавам.',
        ExplanationLanguage.russian:
            'Привет$who. Я ZLOY. Пиши предложение. Будет ошибка — исправлю, '
            'отговорки не слушаю.',
        ExplanationLanguage.english:
            'Hello$who. I am ZLOY. Write a sentence. If it has a mistake, I fix '
            'it. No excuses.',
      },
      PersonalityMode.roast: {
        ExplanationLanguage.tajik:
            'Салом$who! ZLOY омад. Ҷумла нависед — грамматикаатонро бо завқ '
            'месанҷем.',
        ExplanationLanguage.russian:
            'Привет$who! ZLOY на месте. Пиши предложение — проверим твою '
            'грамматику с удовольствием.',
        ExplanationLanguage.english:
            'Hi$who! ZLOY is here. Write a sentence — we will inspect your '
            'grammar with great pleasure.',
      },
      PersonalityMode.shout: {
        ExplanationLanguage.tajik:
            'САЛОМ$who! ZLOY омад! ҶУМЛА НАВИСЕД! Хато бошад — МЕИСЛОҲАМ!',
        ExplanationLanguage.russian:
            'ПРИВЕТ$who! ZLOY здесь! ПИШИ ПРЕДЛОЖЕНИЕ! Будет ошибка — ИСПРАВЛЮ!',
        ExplanationLanguage.english:
            'HELLO$who! ZLOY IS HERE! WRITE A SENTENCE! Mistakes WILL be fixed!',
      },
    }[mode]![lang]!;
    return options;
  }

  String randomEncouragement(ExplanationLanguage lang) {
    const lines = {
      ExplanationLanguage.tajik: [
        'Хуб! Идома деҳ.',
        'Ана ҳамин тавр! Як қадам наздиктар.',
        'Офарин, вале ҳанӯз кор ҳаст.',
      ],
      ExplanationLanguage.russian: [
        'Хорошо! Продолжай.',
        'Вот так! Ещё один шаг.',
        'Молодец, но работы ещё много.',
      ],
      ExplanationLanguage.english: [
        'Good! Keep going.',
        'That is it! One step closer.',
        'Nice, but there is still work to do.',
      ],
    };
    final list = lines[lang]!;
    return list[_random.nextInt(list.length)];
  }

  Future<void> clear() async {
    _messages.clear();
    _lastException = null;
    notifyListeners();
    await _persist();
  }

  @override
  void dispose() {
    _moodTimer?.cancel();
    super.dispose();
  }
}
