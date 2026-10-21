import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Result of trying to start the microphone.
enum ListenStartResult {
  started,
  unavailable,
  permissionDenied,
  disabledByUser,
  busy,
}

/// Thin, defensive wrapper around Android's SpeechRecognizer.
///
/// Nothing here stores audio: the plugin hands us text only. On most Android
/// devices the recogniser is provided by Google and may send audio to that
/// service — this is documented in the Privacy screen and can be disabled.
class SpeechInputService {
  SpeechInputService({stt.SpeechToText? engine})
    : _speech = engine ?? stt.SpeechToText();

  final stt.SpeechToText _speech;

  bool _initialized = false;
  bool _available = false;
  String? _lastError;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;
  String? get lastError => _lastError;

  /// Initialises the platform recogniser once. Returns whether speech input is
  /// actually usable on this device.
  Future<bool> initialize() async {
    if (_initialized) return _available;
    _initialized = true;
    try {
      _available = await _speech.initialize(
        onStatus: (status) => debugPrint('speech status: $status'),
        onError: (error) {
          _lastError = error.errorMsg;
          debugPrint('speech error: ${error.errorMsg}');
        },
        finalTimeout: const Duration(seconds: 2),
      );
    } catch (e) {
      // Missing plugin / unsupported platform / denied permission.
      _available = false;
      _lastError = e.toString();
      debugPrint('speech init failed: $e');
    }
    return _available;
  }

  /// Locales the platform recogniser reports as installed.
  Future<List<stt.LocaleName>> locales() async {
    try {
      final list = await _speech.locales();
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Picks the best available locale for a BCP-47 language code.
  Future<String?> localeFor(String languageCode) async {
    final all = await locales();
    if (all.isEmpty) return null;
    final wanted = languageCode.toLowerCase();
    final exact = all.where(
      (l) =>
          l.localeId.toLowerCase() == wanted ||
          l.localeId.toLowerCase().startsWith('${wanted}_'),
    );
    if (exact.isNotEmpty) return exact.first.localeId;
    final loose = all.where((l) => l.localeId.toLowerCase().startsWith(wanted));
    return loose.isEmpty ? null : loose.first.localeId;
  }

  /// Starts a listening session.
  ///
  /// [onText] is called with partial and final transcripts; [onDone] fires when
  /// the recogniser stops (silence, timeout or explicit stop).
  Future<ListenStartResult> listen({
    required void Function(String text, bool isFinal) onText,
    required void Function() onDone,
    String? localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (_speech.isListening) {
      await stop();
    }
    final ready = await initialize();
    if (!ready) {
      return ListenStartResult.unavailable;
    }
    try {
      await _speech.listen(
        onResult: (result) {
          onText(result.recognizedWords, result.finalResult);
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
          listenFor: listenFor,
          pauseFor: pauseFor,
          localeId: localeId,
        ),
      );
      return ListenStartResult.started;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('listen failed: $e');
      return ListenStartResult.permissionDenied;
    }
  }

  Future<void> stop() async {
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (e) {
      debugPrint('speech stop failed: $e');
    }
  }

  Future<void> cancel() async {
    try {
      if (_speech.isListening) await _speech.cancel();
    } catch (e) {
      debugPrint('speech cancel failed: $e');
    }
  }
}
