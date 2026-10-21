import 'enums.dart';

/// A single message in the tutor conversation.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.correction,
    this.source,
    this.error,
    this.pending = false,
  });

  factory ChatMessage.user({
    required String id,
    required String text,
    DateTime? at,
  }) => ChatMessage(
    id: id,
    role: ChatRole.user,
    text: text,
    createdAt: at ?? DateTime.now(),
  );

  factory ChatMessage.tutor({
    required String id,
    required String text,
    TutorSource? source,
    Correction? correction,
    String? error,
    DateTime? at,
  }) => ChatMessage(
    id: id,
    role: ChatRole.tutor,
    text: text,
    correction: correction,
    source: source,
    error: error,
    createdAt: at ?? DateTime.now(),
  );

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final Correction? correction;

  /// Null while a request is still in flight.
  final TutorSource? source;

  /// Human-readable problem description when the request failed.
  final String? error;
  final bool pending;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({
    String? text,
    Correction? correction,
    TutorSource? source,
    String? error,
    bool? pending,
  }) => ChatMessage(
    id: id,
    role: role,
    text: text ?? this.text,
    createdAt: createdAt,
    correction: correction ?? this.correction,
    source: source ?? this.source,
    error: error ?? this.error,
    pending: pending ?? this.pending,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'source': source?.name,
  };
}

enum ChatRole { user, tutor }

/// A structured grammar correction.
///
/// The backend returns exactly this shape so the UI never has to parse prose.
class Correction {
  const Correction({
    required this.original,
    required this.corrected,
    required this.explanation,
    this.rule,
    this.examples = const [],
    this.exercise,
    this.alternatives = const [],
    this.confidence = CorrectionConfidence.high,
  });

  final String original;
  final String corrected;

  /// Explanation rendered in the user's chosen explanation language.
  final String explanation;

  /// Optional grammar rule name, also in the explanation language.
  final String? rule;

  /// One or two extra model sentences.
  final List<String> examples;

  /// Optional short practice prompt.
  final String? exercise;

  /// Other acceptable readings when the original sentence was ambiguous.
  final List<String> alternatives;

  /// How sure the checker is that it found *the* intended meaning.
  final CorrectionConfidence confidence;

  bool get changed =>
      original.trim().toLowerCase() != corrected.trim().toLowerCase();

  factory Correction.fromJson(Map<String, Object?> json) => Correction(
    original: json['original'] as String? ?? '',
    corrected: json['corrected'] as String? ?? '',
    explanation: json['explanation'] as String? ?? '',
    rule: json['rule'] as String?,
    examples: _stringList(json['examples']),
    exercise: json['exercise'] as String?,
    alternatives: _stringList(json['alternatives']),
    confidence: CorrectionConfidence.fromId(json['confidence'] as String?),
  );

  Map<String, Object?> toJson() => {
    'original': original,
    'corrected': corrected,
    'explanation': explanation,
    'rule': rule,
    'examples': examples,
    'exercise': exercise,
    'alternatives': alternatives,
    'confidence': confidence.id,
  };
}

enum CorrectionConfidence {
  high('high'),
  medium('medium'),
  low('low');

  const CorrectionConfidence(this.id);
  final String id;

  static CorrectionConfidence fromId(String? id) => CorrectionConfidence.values
      .firstWhere((c) => c.id == id, orElse: () => CorrectionConfidence.high);
}

/// Full tutor reply: a conversational message plus an optional correction.
class TutorReply {
  const TutorReply({
    required this.reply,
    required this.source,
    this.correction,
    this.followUp,
    this.latencyMs,
    this.model,
  });

  final String reply;
  final TutorSource source;
  final Correction? correction;

  /// One suggested next thing to say / practise.
  final String? followUp;
  final int? latencyMs;

  /// Model id reported by the backend, shown in debug detail (never a key).
  final String? model;

  factory TutorReply.fromJson(
    Map<String, Object?> json, {
    required TutorSource fallbackSource,
  }) {
    final rawCorrection = json['correction'];
    return TutorReply(
      reply: json['reply'] as String? ?? '',
      source: TutorSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => fallbackSource,
      ),
      correction: rawCorrection is Map<String, Object?>
          ? Correction.fromJson(rawCorrection)
          : null,
      followUp: json['follow_up'] as String?,
      latencyMs: (json['latency_ms'] as num?)?.toInt(),
      model: json['model'] as String?,
    );
  }
}

/// Vocabulary / grammar item used by the offline practice engine.
class PracticeItem {
  const PracticeItem({
    required this.id,
    required this.prompt,
    required this.answer,
    this.hint,
    this.explanation,
    this.acceptedAnswers = const [],
    this.choiceAnswers = const [],
  });

  final String id;

  /// The question shown to the learner (may be a sentence with a blank).
  final String prompt;
  final String answer;
  final String? hint;

  /// Explanation in the user's explanation language, shown after answering.
  final String? explanation;

  /// Other spellings accepted as correct.
  final List<String> acceptedAnswers;

  /// If non-empty, render as multiple choice instead of free text.
  final List<String> choiceAnswers;

  bool get isMultipleChoice => choiceAnswers.isNotEmpty;

  bool check(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return false;
    if (normalized == _normalize(answer)) return true;
    return acceptedAnswers.any((a) => _normalize(a) == normalized);
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[.,!?;:"“”]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// A lesson groups practice items with metadata.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.level,
    required this.items,
    this.emoji = '📘',
  });

  final String id;
  final String title;
  final String subtitle;
  final LessonKind kind;
  final ProficiencyLevel level;
  final List<PracticeItem> items;
  final String emoji;
}

enum LessonKind { vocabulary, grammar, reading, translation, challenge }

/// A reading-comprehension passage bundled offline.
class ReadingPassage {
  const ReadingPassage({
    required this.id,
    required this.title,
    required this.text,
    required this.questions,
    required this.level,
  });

  final String id;
  final String title;
  final String text;
  final List<PracticeItem> questions;
  final ProficiencyLevel level;
}

/// One recorded mistake, used for the review queue.
class MistakeRecord {
  const MistakeRecord({
    required this.id,
    required this.original,
    required this.corrected,
    required this.explanation,
    required this.createdAt,
    this.rule,
    this.reviewed = false,
  });

  final String id;
  final String original;
  final String corrected;
  final String explanation;
  final String? rule;
  final DateTime createdAt;
  final bool reviewed;

  Map<String, Object?> toJson() => {
    'id': id,
    'original': original,
    'corrected': corrected,
    'explanation': explanation,
    'rule': rule,
    'createdAt': createdAt.toIso8601String(),
    'reviewed': reviewed,
  };

  factory MistakeRecord.fromJson(Map<String, Object?> json) => MistakeRecord(
    id: json['id'] as String? ?? '',
    original: json['original'] as String? ?? '',
    corrected: json['corrected'] as String? ?? '',
    explanation: json['explanation'] as String? ?? '',
    rule: json['rule'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    reviewed: json['reviewed'] as bool? ?? false,
  );

  MistakeRecord copyWith({bool? reviewed}) => MistakeRecord(
    id: id,
    original: original,
    corrected: corrected,
    explanation: explanation,
    rule: rule,
    createdAt: createdAt,
    reviewed: reviewed ?? this.reviewed,
  );
}

List<String> _stringList(Object? raw) {
  if (raw is List) {
    return raw.whereType<String>().toList(growable: false);
  }
  return const [];
}
