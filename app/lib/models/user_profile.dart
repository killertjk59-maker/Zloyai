import 'enums.dart';

/// Everything the learner told us about themselves.
///
/// Persisted locally only (SharedPreferences). No account, no server copy.
class UserProfile {
  const UserProfile({
    this.onboardingComplete = false,
    this.targetLanguage = TargetLanguage.english,
    this.explanationLanguage = ExplanationLanguage.tajik,
    this.level = ProficiencyLevel.beginner,
    this.goals = const {},
    this.learningStyle = LearningStyle.examples,
    this.dailyGoalMinutes = 15,
    this.displayName = '',
  });

  final bool onboardingComplete;
  final TargetLanguage targetLanguage;
  final ExplanationLanguage explanationLanguage;
  final ProficiencyLevel level;
  final Set<LearningGoal> goals;
  final LearningStyle learningStyle;
  final int dailyGoalMinutes;
  final String displayName;

  UserProfile copyWith({
    bool? onboardingComplete,
    TargetLanguage? targetLanguage,
    ExplanationLanguage? explanationLanguage,
    ProficiencyLevel? level,
    Set<LearningGoal>? goals,
    LearningStyle? learningStyle,
    int? dailyGoalMinutes,
    String? displayName,
  }) {
    return UserProfile(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      explanationLanguage: explanationLanguage ?? this.explanationLanguage,
      level: level ?? this.level,
      goals: goals ?? this.goals,
      learningStyle: learningStyle ?? this.learningStyle,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, Object?> toJson() => {
    'onboardingComplete': onboardingComplete,
    'targetLanguage': targetLanguage.code,
    'explanationLanguage': explanationLanguage.code,
    'level': level.id,
    'goals': goals.map((g) => g.id).toList(),
    'learningStyle': learningStyle.id,
    'dailyGoalMinutes': dailyGoalMinutes,
    'displayName': displayName,
  };

  factory UserProfile.fromJson(Map<String, Object?> json) {
    final rawGoals = (json['goals'] as List?) ?? const [];
    return UserProfile(
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      targetLanguage: TargetLanguage.fromCode(
        json['targetLanguage'] as String?,
      ),
      explanationLanguage: ExplanationLanguage.fromCode(
        json['explanationLanguage'] as String?,
      ),
      level: ProficiencyLevel.fromId(json['level'] as String?),
      goals: rawGoals
          .map((g) => LearningGoal.tryFromId(g as String?))
          .whereType<LearningGoal>()
          .toSet(),
      learningStyle: LearningStyle.fromId(json['learningStyle'] as String?),
      dailyGoalMinutes: json['dailyGoalMinutes'] as int? ?? 15,
      displayName: json['displayName'] as String? ?? '',
    );
  }
}

/// User-facing app behaviour settings (personality, voice, backend URL).
class AppSettings {
  const AppSettings({
    this.personality = PersonalityMode.strict,
    this.profanityEnabled = false,
    this.voiceInputEnabled = true,
    this.voiceOutputEnabled = true,
    this.speechRate = 0.5,
    this.speechPitch = 1.0,
    this.soundEffectsEnabled = true,
    this.hapticsEnabled = true,
    this.autoSpeakTutorReplies = false,
    this.backendBaseUrl = defaultBackendUrl,
    this.preferOfflineOnly = false,
    this.allowPlatformSpeechRecognition = true,
  });

  /// Empty by default: the app then navigates in offline mode and tells the
  /// user they must point it at their own backend to talk to the AI.
  /// Production URLs are never hardcoded and localhost is never assumed.
  static const String defaultBackendUrl = '';

  final PersonalityMode personality;
  final bool profanityEnabled;
  final bool voiceInputEnabled;
  final bool voiceOutputEnabled;

  /// 0.25 (slow) .. 1.0 (fast) — platform TTS range.
  final double speechRate;

  /// 0.5 (low) .. 2.0 (high) — platform TTS range.
  final double speechPitch;
  final bool soundEffectsEnabled;
  final bool hapticsEnabled;
  final bool autoSpeakTutorReplies;
  final String backendBaseUrl;
  final bool preferOfflineOnly;

  /// Android's SpeechRecognizer may send audio to the platform provider.
  /// Users can opt out and type instead.
  final bool allowPlatformSpeechRecognition;

  bool get hasBackend => backendBaseUrl.trim().isNotEmpty;

  AppSettings copyWith({
    PersonalityMode? personality,
    bool? profanityEnabled,
    bool? voiceInputEnabled,
    bool? voiceOutputEnabled,
    double? speechRate,
    double? speechPitch,
    bool? soundEffectsEnabled,
    bool? hapticsEnabled,
    bool? autoSpeakTutorReplies,
    String? backendBaseUrl,
    bool? preferOfflineOnly,
    bool? allowPlatformSpeechRecognition,
  }) {
    return AppSettings(
      personality: personality ?? this.personality,
      profanityEnabled: profanityEnabled ?? this.profanityEnabled,
      voiceInputEnabled: voiceInputEnabled ?? this.voiceInputEnabled,
      voiceOutputEnabled: voiceOutputEnabled ?? this.voiceOutputEnabled,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      autoSpeakTutorReplies:
          autoSpeakTutorReplies ?? this.autoSpeakTutorReplies,
      backendBaseUrl: backendBaseUrl ?? this.backendBaseUrl,
      preferOfflineOnly: preferOfflineOnly ?? this.preferOfflineOnly,
      allowPlatformSpeechRecognition:
          allowPlatformSpeechRecognition ?? this.allowPlatformSpeechRecognition,
    );
  }

  Map<String, Object?> toJson() => {
    'personality': personality.id,
    'profanityEnabled': profanityEnabled,
    'voiceInputEnabled': voiceInputEnabled,
    'voiceOutputEnabled': voiceOutputEnabled,
    'speechRate': speechRate,
    'speechPitch': speechPitch,
    'soundEffectsEnabled': soundEffectsEnabled,
    'hapticsEnabled': hapticsEnabled,
    'autoSpeakTutorReplies': autoSpeakTutorReplies,
    'backendBaseUrl': backendBaseUrl,
    'preferOfflineOnly': preferOfflineOnly,
    'allowPlatformSpeechRecognition': allowPlatformSpeechRecognition,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) => AppSettings(
    personality: PersonalityMode.fromId(json['personality'] as String?),
    profanityEnabled: json['profanityEnabled'] as bool? ?? false,
    voiceInputEnabled: json['voiceInputEnabled'] as bool? ?? true,
    voiceOutputEnabled: json['voiceOutputEnabled'] as bool? ?? true,
    speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
    speechPitch: (json['speechPitch'] as num?)?.toDouble() ?? 1.0,
    soundEffectsEnabled: json['soundEffectsEnabled'] as bool? ?? true,
    hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    autoSpeakTutorReplies: json['autoSpeakTutorReplies'] as bool? ?? false,
    backendBaseUrl: (json['backendBaseUrl'] as String?) ?? defaultBackendUrl,
    preferOfflineOnly: json['preferOfflineOnly'] as bool? ?? false,
    allowPlatformSpeechRecognition:
        json['allowPlatformSpeechRecognition'] as bool? ?? true,
  );
}
