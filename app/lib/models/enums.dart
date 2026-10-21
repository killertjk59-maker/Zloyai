/// Domain enums shared across the app.
///
/// Every enum carries its wire value (used with the backend) and its
/// human-readable label so persistence and UI stay in sync.
library;

/// A language the user can learn (target language).
///
/// The architecture is deliberately data-driven: adding a language means
/// adding one entry here (plus bundled content and a backend prompt entry).
enum TargetLanguage {
  english('en', 'English', 'Англисӣ', 'Английский', '🇬🇧'),
  russian('ru', 'Russian', 'Русский', 'Русский', '🇷🇺'),
  tajik('tg', 'Tajik', 'Тоҷикӣ', 'Таджикский', '🇹🇯');

  const TargetLanguage(
    this.code,
    this.englishName,
    this.tajikName,
    this.russianName,
    this.flag,
  );

  final String code;
  final String englishName;
  final String tajikName;
  final String russianName;
  final String flag;

  String get displayName => englishName;

  static TargetLanguage fromCode(String? code) => TargetLanguage.values
      .firstWhere((l) => l.code == code, orElse: () => TargetLanguage.english);
}

/// The language used to explain grammar and corrections.
enum ExplanationLanguage {
  tajik('tg', 'Тоҷикӣ', 'Tajik'),
  russian('ru', 'Русский', 'Russian'),
  english('en', 'English', 'English');

  const ExplanationLanguage(this.code, this.nativeName, this.englishName);

  final String code;
  final String nativeName;
  final String englishName;

  /// BCP-47 tag used for Text-to-Speech.
  String get ttsLocale => switch (this) {
    ExplanationLanguage.tajik => 'tg-TJ',
    ExplanationLanguage.russian => 'ru-RU',
    ExplanationLanguage.english => 'en-US',
  };

  static ExplanationLanguage fromCode(String? code) =>
      ExplanationLanguage.values.firstWhere(
        (l) => l.code == code,
        orElse: () => ExplanationLanguage.tajik,
      );
}

/// CEFR-style proficiency levels.
enum ProficiencyLevel {
  beginner('beginner', 'Beginner', 'A1', 'Starting from zero'),
  elementary('elementary', 'Elementary', 'A2', 'Short sentences, basic words'),
  intermediate('intermediate', 'Intermediate', 'B1', 'Can hold a conversation'),
  upperIntermediate(
    'upper_intermediate',
    'Upper-intermediate',
    'B2',
    'Comfortable, working on precision',
  ),
  advanced('advanced', 'Advanced', 'C1', 'Polishing nuance and style');

  const ProficiencyLevel(this.id, this.label, this.cefr, this.description);

  final String id;
  final String label;
  final String cefr;
  final String description;

  static ProficiencyLevel fromId(String? id) => ProficiencyLevel.values
      .firstWhere((l) => l.id == id, orElse: () => ProficiencyLevel.beginner);
}

/// How much attitude ZLOY applies.
enum PersonalityMode {
  normal('normal', 'Normal', 'Patient and friendly. Fixes mistakes kindly.'),
  strict('strict', 'Strict', 'Demanding and direct. No excuses accepted.'),
  roast('roast', 'Roast', 'Sarcastic jokes about the grammar, not about you.'),
  shout('shout', 'Shout', 'Angry-teacher energy, CAPS and all.');

  const PersonalityMode(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  static PersonalityMode fromId(String? id) => PersonalityMode.values
      .firstWhere((m) => m.id == id, orElse: () => PersonalityMode.strict);
}

/// Reasons the user is learning.
enum LearningGoal {
  travel('travel', 'Travel', '✈️'),
  work('work', 'Work & career', '💼'),
  exams('exams', 'Exams', '📝'),
  conversation('conversation', 'Everyday conversation', '💬'),
  media('media', 'Movies & music', '🎬'),
  migration('migration', 'Living abroad', '🏠');

  const LearningGoal(this.id, this.label, this.emoji);

  final String id;
  final String label;
  final String emoji;

  static LearningGoal? tryFromId(String? id) {
    for (final g in LearningGoal.values) {
      if (g.id == id) return g;
    }
    return null;
  }
}

/// Preferred way of learning.
enum LearningStyle {
  examples('examples', 'Examples first', 'Show me sentences, then the rule'),
  rules('rules', 'Rules first', 'Explain the rule, then the example'),
  dialogue('dialogue', 'Chat & dialogue', 'Teach me through conversation'),
  drills('drills', 'Drills', 'Give me lots of short exercises');

  const LearningStyle(this.id, this.label, this.description);

  final String id;
  final String label;
  final String description;

  static LearningStyle fromId(String? id) => LearningStyle.values.firstWhere(
    (l) => l.id == id,
    orElse: () => LearningStyle.examples,
  );
}

/// Mascot emotional states. The mascot painter interpolates between them.
enum MascotMood {
  idle,
  listening,
  thinking,
  speaking,
  correct,
  incorrect,
  encourage,
  angry,
  celebrate,
}

/// Where an AI answer came from — shown honestly in the UI.
enum TutorSource {
  /// Real model output from the OpenRouter-backed backend.
  ai,

  /// Local, deterministic checker that runs on-device without a network.
  offline,

  /// Backend mock provider (development / demo). Never presented as a model.
  mock,
}
