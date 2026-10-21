import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/chat_models.dart';
import '../models/enums.dart';
import '../models/progress_models.dart';
import '../services/preferences_service.dart';
import 'settings_controller.dart';

/// Local, honest progress tracking.
///
/// Every number on the progress screen is derived from recorded answers and
/// completed sessions on this device. Nothing is seeded with demo data.
class ProgressController extends ChangeNotifier implements ProgressStore {
  ProgressController(this._prefs);

  final PreferencesService _prefs;

  final Map<String, DailyActivity> _activity = {};
  final List<SessionResult> _sessions = [];
  final List<MistakeRecord> _mistakes = [];
  final Map<String, VocabularyProgress> _vocab = {};
  ChallengeState? _challenge;
  bool _loaded = false;

  bool get loaded => _loaded;

  static DateTime _todayKey() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> load() async {
    for (final raw in _prefs.readJsonList(_prefs.activityKey)) {
      final day = DailyActivity.fromJson(raw);
      _activity[day.dayKey.toIso8601String()] = day;
    }
    for (final raw in _prefs.readJsonList(_prefs.sessionsKey)) {
      _sessions.add(SessionResult.fromJson(raw));
    }
    for (final raw in _prefs.readJsonList(_prefs.mistakesKey)) {
      _mistakes.add(MistakeRecord.fromJson(raw));
    }
    for (final raw in _prefs.readJsonList(_prefs.vocabKey)) {
      final v = VocabularyProgress.fromJson(raw);
      if (v.itemId.isNotEmpty) _vocab[v.itemId] = v;
    }
    final rawChallenge = _prefs.readJson(_prefs.challengeKey);
    if (rawChallenge != null) {
      _challenge = ChallengeState.fromJson(rawChallenge);
    }
    _loaded = true;
    notifyListeners();
  }

  // ------------------------------------------------------------------ getters

  DailyActivity get today =>
      _activity[_todayKey().toIso8601String()] ??
      DailyActivity(date: _todayKey());

  DailyActivity activityFor(DateTime day) {
    final key = DateTime(day.year, day.month, day.day).toIso8601String();
    return _activity[key] ??
        DailyActivity(date: DateTime(day.year, day.month, day.day));
  }

  /// Last seven days, oldest first — always exactly seven entries.
  List<DailyActivity> get lastSevenDays {
    final today = _todayKey();
    return [
      for (var i = 6; i >= 0; i--)
        activityFor(today.subtract(Duration(days: i))),
    ];
  }

  int get totalItemsAnswered =>
      _activity.values.fold(0, (sum, a) => sum + a.itemsAnswered);

  int get totalItemsCorrect =>
      _activity.values.fold(0, (sum, a) => sum + a.itemsCorrect);

  int get totalMinutes => _activity.values.fold(0, (sum, a) => sum + a.minutes);

  int get totalAiMessages =>
      _activity.values.fold(0, (sum, a) => sum + a.aiMessages);

  double get overallAccuracy =>
      totalItemsAnswered == 0 ? 0 : totalItemsCorrect / totalItemsAnswered;

  int get sessionsCompleted => _sessions.length;

  int get masteredWordCount => _vocab.values.where((v) => v.box >= 3).length;

  int get wordsPractised => _vocab.length;

  List<SessionResult> get sessions => List.unmodifiable(_sessions.reversed);

  List<MistakeRecord> get mistakes => List.unmodifiable(_mistakes.reversed);

  List<MistakeRecord> get unreviewedMistakes =>
      _mistakes.where((m) => !m.reviewed).toList().reversed.toList();

  VocabularyProgress? vocabProgress(String itemId) => _vocab[itemId];

  ChallengeState? get challengeState => _challenge;

  bool get challengeCompletedToday {
    final state = _challenge;
    if (state == null) return false;
    return state.completed &&
        DateTime(state.date.year, state.date.month, state.date.day) ==
            _todayKey();
  }

  /// Consecutive days (ending today or yesterday) with any real activity.
  int get streakDays {
    var streak = 0;
    var cursor = _todayKey();
    if (activityFor(cursor).isEmpty) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (activityFor(cursor).isEmpty) return 0;
    }
    while (!activityFor(cursor).isEmpty) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
      if (streak > 3650) break; // safety valve
    }
    return streak;
  }

  /// Best accuracy over the last 7 days (0 when there is no data).
  double get weeklyAccuracy {
    final days = lastSevenDays;
    final answered = days.fold(0, (s, d) => s + d.itemsAnswered);
    final correct = days.fold(0, (s, d) => s + d.itemsCorrect);
    return answered == 0 ? 0 : correct / answered;
  }

  /// A rough "can-do" hint derived only from recorded accuracy and volume.
  String suggestedLevelHint(
    ProficiencyLevel current,
    ExplanationLanguage lang,
  ) {
    if (totalItemsAnswered < 20) {
      return _hint(lang, 'notEnough');
    }
    final acc = overallAccuracy;
    if (acc >= 0.85 && totalItemsAnswered >= 60) {
      return _hint(lang, 'readyUp');
    }
    if (acc < 0.5) return _hint(lang, 'slowDown');
    return _hint(lang, 'hold');
  }

  String _hint(ExplanationLanguage lang, String key) {
    const messages = {
      'notEnough': {
        'tg':
            'Ҳанӯз маълумот кам аст. Камаш 20 ҷавоб диҳед, то тавсияи '
            'сатҳ пайдо шавад.',
        'ru':
            'Данных пока мало. Ответьте хотя бы на 20 заданий, чтобы '
            'появилась рекомендация по уровню.',
        'en':
            'Not enough data yet. Answer at least 20 items to get a level '
            'recommendation.',
      },
      'readyUp': {
        'tg': 'Дақиқии шумо баланд аст — метавонед ба сатҳи баландтар гузаред.',
        'ru': 'У вас высокая точность — можно перейти на уровень выше.',
        'en': 'Your accuracy is high — you can try the next level up.',
      },
      'slowDown': {
        'tg': 'Дақиқӣ паст аст. Суръатро кам кунед ва қоидаҳоро такрор кунед.',
        'ru': 'Точность низкая. Снизьте темп и повторите правила.',
        'en': 'Accuracy is low. Slow down and review the rules.',
      },
      'hold': {
        'tg': 'Ҳоло сатҳи шумо муносиб аст. Идома диҳед.',
        'ru': 'Ваш текущий уровень подходит. Продолжайте.',
        'en': 'Your current level fits. Keep going.',
      },
    };
    return messages[key]![lang.code]!;
  }

  // ------------------------------------------------------------------ mutation

  Future<void> _persistActivity() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 120));
    _activity.removeWhere((k, v) => v.dayKey.isBefore(cutoff));
    await _prefs.writeJsonList(
      _prefs.activityKey,
      _activity.values.map((a) => a.toJson()).toList(),
    );
  }

  Future<void> _persistSessions() async {
    while (_sessions.length > 100) {
      _sessions.removeAt(0);
    }
    await _prefs.writeJsonList(
      _prefs.sessionsKey,
      _sessions.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> _persistMistakes() async {
    while (_mistakes.length > 100) {
      _mistakes.removeAt(0);
    }
    await _prefs.writeJsonList(
      _prefs.mistakesKey,
      _mistakes.map((m) => m.toJson()).toList(),
    );
  }

  Future<void> recordAnswer({required bool correct}) async {
    final key = _todayKey().toIso8601String();
    final current = _activity[key] ?? DailyActivity(date: _todayKey());
    _activity[key] = current.copyWith(
      itemsAnswered: current.itemsAnswered + 1,
      itemsCorrect: current.itemsCorrect + (correct ? 1 : 0),
    );
    notifyListeners();
    await _persistActivity();
  }

  /// Records elapsed practice time, ignoring absurd values from backgrounding.
  Future<void> addMinutes(int minutes) async {
    if (minutes <= 0 || minutes > 180) return;
    final key = _todayKey().toIso8601String();
    final current = _activity[key] ?? DailyActivity(date: _todayKey());
    _activity[key] = current.copyWith(minutes: current.minutes + minutes);
    notifyListeners();
    await _persistActivity();
  }

  Future<void> recordAiMessage() async {
    final key = _todayKey().toIso8601String();
    final current = _activity[key] ?? DailyActivity(date: _todayKey());
    _activity[key] = current.copyWith(aiMessages: current.aiMessages + 1);
    notifyListeners();
    await _persistActivity();
  }

  Future<void> recordSpeakingSeconds(int seconds) async {
    if (seconds <= 0) return;
    final key = _todayKey().toIso8601String();
    final current = _activity[key] ?? DailyActivity(date: _todayKey());
    _activity[key] = current.copyWith(
      speakingSeconds: current.speakingSeconds + min(seconds, 600),
    );
    notifyListeners();
    await _persistActivity();
  }

  Future<void> recordSession(SessionResult result) async {
    _sessions.add(result);
    notifyListeners();
    await _persistSessions();
  }

  Future<void> recordMistake(MistakeRecord mistake) async {
    // Avoid flooding the queue with duplicates of the same correction.
    if (_mistakes.any(
      (m) =>
          m.original.toLowerCase() == mistake.original.toLowerCase() &&
          m.corrected.toLowerCase() == mistake.corrected.toLowerCase(),
    )) {
      return;
    }
    _mistakes.add(mistake);
    notifyListeners();
    await _persistMistakes();
  }

  Future<void> markMistakeReviewed(String id) async {
    final index = _mistakes.indexWhere((m) => m.id == id);
    if (index == -1) return;
    _mistakes[index] = _mistakes[index].copyWith(reviewed: true);
    notifyListeners();
    await _persistMistakes();
  }

  Future<void> clearMistakes() async {
    _mistakes.clear();
    notifyListeners();
    await _persistMistakes();
  }

  Future<void> recordVocabResult(String itemId, {required bool correct}) async {
    final existing = _vocab[itemId];
    final box = existing == null
        ? (correct ? 1 : 0)
        : (correct ? min(existing.box + 1, 4) : 0);
    _vocab[itemId] = VocabularyProgress(
      itemId: itemId,
      box: box,
      correct: (existing?.correct ?? 0) + (correct ? 1 : 0),
      wrong: (existing?.wrong ?? 0) + (correct ? 0 : 1),
      lastSeen: DateTime.now(),
    );
    notifyListeners();
    await _prefs.writeJsonList(
      _prefs.vocabKey,
      _vocab.values.map((v) => v.toJson()).toList(),
    );
  }

  Future<void> completeChallenge({
    required int correct,
    required int total,
  }) async {
    _challenge = ChallengeState(
      date: _todayKey(),
      completed: true,
      correct: correct,
      total: total,
    );
    await _prefs.writeJson(_prefs.challengeKey, _challenge!.toJson());
    notifyListeners();
  }

  @override
  Future<void> reset() async {
    _activity.clear();
    _sessions.clear();
    _mistakes.clear();
    _vocab.clear();
    _challenge = null;
    await _prefs.writeJsonList(_prefs.activityKey, const []);
    await _prefs.writeJsonList(_prefs.sessionsKey, const []);
    await _prefs.writeJsonList(_prefs.mistakesKey, const []);
    await _prefs.writeJsonList(_prefs.vocabKey, const []);
    notifyListeners();
  }
}
