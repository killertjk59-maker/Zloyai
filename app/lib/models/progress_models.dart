import 'chat_models.dart' show LessonKind;

/// Per-day activity counters. Only real, recorded activity is stored — nothing
/// is estimated or invented.
class DailyActivity {
  const DailyActivity({
    required this.date,
    this.minutes = 0,
    this.itemsAnswered = 0,
    this.itemsCorrect = 0,
    this.aiMessages = 0,
    this.speakingSeconds = 0,
  });

  /// Local calendar date normalised to midnight.
  final DateTime date;
  final int minutes;
  final int itemsAnswered;
  final int itemsCorrect;
  final int aiMessages;
  final int speakingSeconds;

  double get accuracy => itemsAnswered == 0 ? 0 : itemsCorrect / itemsAnswered;

  bool get isEmpty =>
      minutes == 0 &&
      itemsAnswered == 0 &&
      aiMessages == 0 &&
      speakingSeconds == 0;

  DateTime get dayKey => DateTime(date.year, date.month, date.day);

  DailyActivity copyWith({
    int? minutes,
    int? itemsAnswered,
    int? itemsCorrect,
    int? aiMessages,
    int? speakingSeconds,
  }) => DailyActivity(
    date: dayKey,
    minutes: minutes ?? this.minutes,
    itemsAnswered: itemsAnswered ?? this.itemsAnswered,
    itemsCorrect: itemsCorrect ?? this.itemsCorrect,
    aiMessages: aiMessages ?? this.aiMessages,
    speakingSeconds: speakingSeconds ?? this.speakingSeconds,
  );

  Map<String, Object?> toJson() => {
    'date': dayKey.toIso8601String(),
    'minutes': minutes,
    'itemsAnswered': itemsAnswered,
    'itemsCorrect': itemsCorrect,
    'aiMessages': aiMessages,
    'speakingSeconds': speakingSeconds,
  };

  factory DailyActivity.fromJson(Map<String, Object?> json) => DailyActivity(
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    minutes: json['minutes'] as int? ?? 0,
    itemsAnswered: json['itemsAnswered'] as int? ?? 0,
    itemsCorrect: json['itemsCorrect'] as int? ?? 0,
    aiMessages: json['aiMessages'] as int? ?? 0,
    speakingSeconds: json['speakingSeconds'] as int? ?? 0,
  );
}

/// A completed practice session (one lesson, one challenge, one drill).
class SessionResult {
  const SessionResult({
    required this.id,
    required this.kind,
    required this.title,
    required this.correct,
    required this.total,
    required this.completedAt,
    this.detail,
  });

  final String id;
  final LessonKind kind;
  final String title;
  final int correct;
  final int total;
  final DateTime completedAt;
  final String? detail;

  double get score => total == 0 ? 0 : correct / total;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'correct': correct,
    'total': total,
    'completedAt': completedAt.toIso8601String(),
    'detail': detail,
  };

  factory SessionResult.fromJson(Map<String, Object?> json) => SessionResult(
    id: json['id'] as String? ?? '',
    kind: LessonKind.values.firstWhere(
      (k) => k.name == json['kind'],
      orElse: () => LessonKind.vocabulary,
    ),
    title: json['title'] as String? ?? '',
    correct: json['correct'] as int? ?? 0,
    total: json['total'] as int? ?? 0,
    completedAt:
        DateTime.tryParse(json['completedAt'] as String? ?? '') ??
        DateTime.now(),
    detail: json['detail'] as String?,
  );
}

/// Spaced-repetition-ish vocabulary state (Leitner box, 0-4).
class VocabularyProgress {
  const VocabularyProgress({
    required this.itemId,
    this.box = 0,
    this.correct = 0,
    this.wrong = 0,
    required this.lastSeen,
  });

  final String itemId;

  /// 0 = new/again, 4 = mastered. Wrong answers push back to 0.
  final int box;
  final int correct;
  final int wrong;
  final DateTime lastSeen;

  VocabularyProgress copyWith({
    int? box,
    int? correct,
    int? wrong,
    DateTime? lastSeen,
  }) => VocabularyProgress(
    itemId: itemId,
    box: box ?? this.box,
    correct: correct ?? this.correct,
    wrong: wrong ?? this.wrong,
    lastSeen: lastSeen ?? this.lastSeen,
  );

  Map<String, Object?> toJson() => {
    'itemId': itemId,
    'box': box,
    'correct': correct,
    'wrong': wrong,
    'lastSeen': lastSeen.toIso8601String(),
  };

  factory VocabularyProgress.fromJson(Map<String, Object?> json) =>
      VocabularyProgress(
        itemId: json['itemId'] as String? ?? '',
        box: json['box'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
        wrong: json['wrong'] as int? ?? 0,
        lastSeen:
            DateTime.tryParse(json['lastSeen'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Daily-challenge completion state so the same challenge is not repeatable
/// for infinite "progress".
class ChallengeState {
  const ChallengeState({
    required this.date,
    this.completed = false,
    this.correct = 0,
    this.total = 0,
  });

  final DateTime date;
  final bool completed;
  final int correct;
  final int total;

  Map<String, Object?> toJson() => {
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'completed': completed,
    'correct': correct,
    'total': total,
  };

  factory ChallengeState.fromJson(Map<String, Object?> json) => ChallengeState(
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    completed: json['completed'] as bool? ?? false,
    correct: json['correct'] as int? ?? 0,
    total: json['total'] as int? ?? 0,
  );
}
