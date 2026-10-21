import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Outcome of asking the platform Text-to-Speech engine to speak.
enum SpeechStartResult { speaking, engineUnavailable, languageMissing, error }

/// Wrapper around Android TextToSpeech.
///
/// Limitations are surfaced honestly: if the device has no voice for the
/// requested language we fall back (and say so) instead of pretending the
/// voice is correct. There is no "angry voice" — SHOUT mode only changes text.
class TtsService {
  TtsService({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;

  bool _initialized = false;
  bool _available = false;
  bool _speaking = false;
  Set<String> _languages = {};
  String? _lastError;

  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();

  Stream<bool> get speakingStream => _speakingController.stream;
  bool get isSpeaking => _speaking;
  bool get isAvailable => _available;
  String? get lastError => _lastError;
  Set<String> get languages => _languages;

  Future<bool> initialize() async {
    if (_initialized) return _available;
    _initialized = true;
    try {
      _tts.setStartHandler(() {
        _speaking = true;
        _speakingController.add(true);
      });
      _tts.setCompletionHandler(() {
        _speaking = false;
        _speakingController.add(false);
      });
      _tts.setCancelHandler(() {
        _speaking = false;
        _speakingController.add(false);
      });
      _tts.setErrorHandler((message) {
        _speaking = false;
        _lastError = '$message';
        _speakingController.add(false);
        debugPrint('tts error: $message');
      });
      await _tts.awaitSpeakCompletion(false);
      final rawLanguages = await _tts.getLanguages;
      if (rawLanguages is List) {
        _languages = rawLanguages
            .map((e) => e.toString().replaceAll('_', '-').toLowerCase())
            .toSet();
      }
      _available = true;
    } catch (e) {
      _available = false;
      _lastError = e.toString();
      debugPrint('tts init failed: $e');
    }
    return _available;
  }

  /// Whether the engine reports a voice for [locale] (e.g. `en-US`).
  bool supportsLocale(String locale) {
    if (_languages.isEmpty) return false;
    final normalized = locale.replaceAll('_', '-').toLowerCase();
    if (_languages.contains(normalized)) return true;
    final base = normalized.split('-').first;
    return _languages.any((l) => l.split('-').first == base);
  }

  /// Best-effort locale resolution: exact -> same language -> null.
  String? resolveLocale(String preferred) {
    final normalized = preferred.replaceAll('_', '-').toLowerCase();
    if (_languages.contains(normalized)) return normalized;
    final base = normalized.split('-').first;
    final sameLanguage = _languages.where((l) => l.split('-').first == base);
    if (sameLanguage.isNotEmpty) return sameLanguage.first;
    return null;
  }

  Future<SpeechStartResult> speak(
    String text, {
    required String locale,
    double rate = 0.5,
    double pitch = 1.0,
  }) async {
    if (text.trim().isEmpty) return SpeechStartResult.error;
    final ready = await initialize();
    if (!ready) return SpeechStartResult.engineUnavailable;

    var resolved = resolveLocale(locale);
    if (resolved == null) {
      // No voice for this language on the device: fall back to English so the
      // user still hears something, and report that it was a fallback.
      resolved = resolveLocale('en-US');
      if (resolved == null) return SpeechStartResult.languageMissing;
      _lastError = 'No voice installed for "$locale"; using "$resolved".';
    }

    try {
      await _tts.stop();
      await _tts.setLanguage(resolved);
      await _tts.setSpeechRate(rate.clamp(0.1, 1.0));
      await _tts.setPitch(pitch.clamp(0.5, 2.0));
      await _tts.setVolume(1.0);
      await _tts.speak(text);
      return SpeechStartResult.speaking;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('tts speak failed: $e');
      return SpeechStartResult.error;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('tts stop failed: $e');
    }
    _speaking = false;
  }

  void dispose() {
    stop();
    _speakingController.close();
  }
}
