import 'package:flutter_test/flutter_test.dart';
import 'package:zloy_app/models/chat_models.dart';
import 'package:zloy_app/models/enums.dart';
import 'package:zloy_app/services/offline_tutor.dart';

void main() {
  const tutor = OfflineTutor();

  Correction? check(
    String text, {
    ExplanationLanguage lang = ExplanationLanguage.tajik,
  }) => tutor.check(text: text, explanationLanguage: lang);

  group('offline checker', () {
    test('flags "I would to school." without inventing one meaning', () {
      final result = check('I would to school.');
      expect(result, isNotNull);
      expect(result!.changed, isTrue);
      // The minimal grammatical fix keeps the modal.
      expect(result.corrected.toLowerCase(), contains('would'));
      expect(result.corrected.toLowerCase(), isNot(contains('would to')));
      // Ambiguity must be surfaced, not guessed away.
      expect(result.confidence, CorrectionConfidence.low);
      expect(result.alternatives, isNotEmpty);
      expect(result.alternatives.join(' ').toLowerCase(), contains('went'));
      // Explanation must be Tajik for a Tajik explanation language.
      expect(result.explanation, contains('would'));
      expect(result.explanation, contains('Past Simple'));
      expect(RegExp(r'[\u0400-\u04FF]').hasMatch(result.explanation), isTrue);
      expect(result.examples, isNotEmpty);
      expect(result.exercise, isNotNull);
    });

    test('fixes third person -s', () {
      final result = check('He go to work every day.');
      expect(result, isNotNull);
      expect(result!.corrected, 'He goes to work every day.');
      expect(result.rule, isNotNull);
      expect(result.rule, contains('-s'));
      expect(result.confidence, CorrectionConfidence.high);
    });

    test('fixes age construction', () {
      final result = check('I have 20 years old.');
      expect(result?.corrected, 'I am 20 years old.');
    });

    test('fixes auxiliary + past tense', () {
      final result = check("I didn't went to school.");
      expect(result?.corrected, "I didn't go to school.");
    });

    test('fixes lowercase pronoun i and capitalises', () {
      final result = check('i live in khujand.');
      expect(result, isNotNull);
      expect(result!.corrected.startsWith('I '), isTrue);
    });

    test('explains in Russian when selected', () {
      final result = check(
        'He go to work every day.',
        lang: ExplanationLanguage.russian,
      );
      expect(result!.explanation, contains('Present Simple'));
      expect(result.explanation.contains('аз'), isFalse);
    });

    test('explains in English when selected', () {
      final result = check(
        'I have 20 years old.',
        lang: ExplanationLanguage.english,
      );
      expect(result!.explanation, contains('age'));
    });

    test('returns null when nothing matches (no false confidence)', () {
      expect(check('This sentence is perfectly fine.'), isNull);
    });

    test('empty input returns null', () {
      expect(check('   '), isNull);
    });

    test('supports English only and says so', () {
      expect(tutor.supports(TargetLanguage.english), isTrue);
      expect(tutor.supports(TargetLanguage.russian), isFalse);
      final reply = tutor.buildReply(
        text: 'Привет',
        personality: PersonalityMode.normal,
        explanationLanguage: ExplanationLanguage.tajik,
        targetLanguage: TargetLanguage.russian,
      );
      expect(reply.source, TutorSource.offline);
      expect(reply.reply, contains('англисӣ'));
    });
  });

  group('offline reply wrapper', () {
    test('never claims to be AI', () {
      final reply = tutor.buildReply(
        text: 'He go to work.',
        personality: PersonalityMode.strict,
        explanationLanguage: ExplanationLanguage.tajik,
        targetLanguage: TargetLanguage.english,
      );
      expect(reply.source, TutorSource.offline);
      expect(reply.correction, isNotNull);
      expect(reply.reply, contains('Дуруст'));
    });

    test('personality changes wording but not facts', () {
      final strict = tutor.buildReply(
        text: 'He go to work.',
        personality: PersonalityMode.strict,
        explanationLanguage: ExplanationLanguage.english,
        targetLanguage: TargetLanguage.english,
      );
      final roast = tutor.buildReply(
        text: 'He go to work.',
        personality: PersonalityMode.roast,
        explanationLanguage: ExplanationLanguage.english,
        targetLanguage: TargetLanguage.english,
      );
      expect(strict.reply, isNot(equals(roast.reply)));
      expect(strict.correction!.corrected, roast.correction!.corrected);
    });
  });
}
