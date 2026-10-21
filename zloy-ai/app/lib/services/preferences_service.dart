import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper around SharedPreferences.
///
/// Everything here stays on the device. No secrets are ever written: the
/// OpenRouter key lives on the backend only.
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PreferencesService> create() async =>
      PreferencesService(await SharedPreferences.getInstance());

  static const _kProfile = 'zloy.profile.v1';
  static const _kSettings = 'zloy.settings.v1';
  static const _kActivity = 'zloy.activity.v1';
  static const _kSessions = 'zloy.sessions.v1';
  static const _kMistakes = 'zloy.mistakes.v1';
  static const _kVocab = 'zloy.vocab.v1';
  static const _kChallenge = 'zloy.challenge.v1';
  static const _kChat = 'zloy.chat.v1';

  Map<String, Object?>? readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, Object?> ? decoded : null;
    } catch (_) {
      // Corrupt payload: drop it rather than crashing at boot.
      _prefs.remove(key);
      return null;
    }
  }

  Future<void> writeJson(String key, Map<String, Object?> value) =>
      _prefs.setString(key, jsonEncode(value));

  List<Map<String, Object?>> readJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map<String, Object?>>().toList();
      }
    } catch (_) {
      _prefs.remove(key);
    }
    return const [];
  }

  Future<void> writeJsonList(String key, List<Map<String, Object?>> value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<void> clearAll() => _prefs.clear();

  // Keys exposed for the controllers.
  String get profileKey => _kProfile;
  String get settingsKey => _kSettings;
  String get activityKey => _kActivity;
  String get sessionsKey => _kSessions;
  String get mistakesKey => _kMistakes;
  String get vocabKey => _kVocab;
  String get challengeKey => _kChallenge;
  String get chatKey => _kChat;
}
