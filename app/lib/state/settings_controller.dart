import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/user_profile.dart';
import '../services/preferences_service.dart';

/// Owns the learner profile and app settings. Everything persists locally.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs);

  final PreferencesService _prefs;

  UserProfile _profile = const UserProfile();
  AppSettings _settings = const AppSettings();
  bool _loaded = false;

  UserProfile get profile => _profile;
  AppSettings get settings => _settings;
  bool get loaded => _loaded;
  bool get needsOnboarding => !_profile.onboardingComplete;

  Future<void> load() async {
    final rawProfile = _prefs.readJson(_prefs.profileKey);
    final rawSettings = _prefs.readJson(_prefs.settingsKey);
    if (rawProfile != null) _profile = UserProfile.fromJson(rawProfile);
    if (rawSettings != null) _settings = AppSettings.fromJson(rawSettings);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveProfile() async {
    await _prefs.writeJson(_prefs.profileKey, _profile.toJson());
  }

  Future<void> _saveSettings() async {
    await _prefs.writeJson(_prefs.settingsKey, _settings.toJson());
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setTargetLanguage(TargetLanguage language) =>
      updateProfile(_profile.copyWith(targetLanguage: language));

  Future<void> setExplanationLanguage(ExplanationLanguage language) =>
      updateProfile(_profile.copyWith(explanationLanguage: language));

  Future<void> setLevel(ProficiencyLevel level) =>
      updateProfile(_profile.copyWith(level: level));

  Future<void> setGoals(Set<LearningGoal> goals) =>
      updateProfile(_profile.copyWith(goals: goals));

  Future<void> setLearningStyle(LearningStyle style) =>
      updateProfile(_profile.copyWith(learningStyle: style));

  Future<void> setDailyGoalMinutes(int minutes) =>
      updateProfile(_profile.copyWith(dailyGoalMinutes: minutes.clamp(5, 120)));

  Future<void> setDisplayName(String name) =>
      updateProfile(_profile.copyWith(displayName: name.trim()));

  Future<void> completeOnboarding() =>
      updateProfile(_profile.copyWith(onboardingComplete: true));

  Future<void> setPersonality(PersonalityMode mode) =>
      updateSettings(_settings.copyWith(personality: mode));

  Future<void> setProfanity(bool enabled) =>
      updateSettings(_settings.copyWith(profanityEnabled: enabled));

  Future<void> setVoiceInputEnabled(bool enabled) =>
      updateSettings(_settings.copyWith(voiceInputEnabled: enabled));

  Future<void> setVoiceOutputEnabled(bool enabled) =>
      updateSettings(_settings.copyWith(voiceOutputEnabled: enabled));

  Future<void> setSpeechRate(double rate) =>
      updateSettings(_settings.copyWith(speechRate: rate));

  Future<void> setSpeechPitch(double pitch) =>
      updateSettings(_settings.copyWith(speechPitch: pitch));

  Future<void> setSoundEffects(bool enabled) =>
      updateSettings(_settings.copyWith(soundEffectsEnabled: enabled));

  Future<void> setHaptics(bool enabled) =>
      updateSettings(_settings.copyWith(hapticsEnabled: enabled));

  Future<void> setAutoSpeak(bool enabled) =>
      updateSettings(_settings.copyWith(autoSpeakTutorReplies: enabled));

  Future<void> setBackendUrl(String url) =>
      updateSettings(_settings.copyWith(backendBaseUrl: _normalizeUrl(url)));

  Future<void> setPreferOfflineOnly(bool value) =>
      updateSettings(_settings.copyWith(preferOfflineOnly: value));

  Future<void> setAllowPlatformSpeechRecognition(bool value) =>
      updateSettings(_settings.copyWith(allowPlatformSpeechRecognition: value));

  /// Accepts "host", "host:port" or a full URL; never injects localhost.
  static String _normalizeUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) return '';
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'https://$value';
    }
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  /// Wipes every stored preference and progress record on this device.
  Future<void> resetEverything({required ProgressStore progress}) async {
    await _prefs.clearAll();
    _profile = const UserProfile();
    _settings = const AppSettings();
    await progress.reset();
    notifyListeners();
  }
}

/// Tiny interface so the settings screen can reset progress without importing
/// the whole progress controller.
abstract class ProgressStore {
  Future<void> reset();
}
