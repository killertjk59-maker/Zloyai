import 'package:flutter_test/flutter_test.dart';
import 'package:zloy_app/data/bundled_content.dart';
import 'package:zloy_app/models/chat_models.dart';
import 'package:zloy_app/models/enums.dart';
import 'package:zloy_app/models/user_profile.dart';

void main() {
  group('PracticeItem.check', () {
    const item = PracticeItem(
      id: 'x',
      prompt: 'She ___ (work).',
      answer: 'works',
      acceptedAnswers: ['is working'],
    );

    test('accepts answer ignoring case and punctuation', () {
      expect(item.check('Works'), isTrue);
      expect(item.check('works.'), isTrue);
      expect(item.check('  works  '), isTrue);
    });

    test('accepts alternatives', () {
      expect(item.check('is working'), isTrue);
    });

    test('rejects wrong and empty answers', () {
      expect(item.check('work'), isFalse);
      expect(item.check(''), isFalse);
      expect(item.check('   '), isFalse);
    });
  });

  group('UserProfile', () {
    test('round trips through JSON', () {
      const profile = UserProfile(
        onboardingComplete: true,
        targetLanguage: TargetLanguage.english,
        explanationLanguage: ExplanationLanguage.russian,
        level: ProficiencyLevel.intermediate,
        goals: {LearningGoal.work, LearningGoal.exams},
        learningStyle: LearningStyle.drills,
        dailyGoalMinutes: 25,
        displayName: 'Farid',
      );
      final restored = UserProfile.fromJson(profile.toJson());
      expect(restored.onboardingComplete, isTrue);
      expect(restored.explanationLanguage, ExplanationLanguage.russian);
      expect(restored.level, ProficiencyLevel.intermediate);
      expect(
        restored.goals,
        containsAll([LearningGoal.work, LearningGoal.exams]),
      );
      expect(restored.learningStyle, LearningStyle.drills);
      expect(restored.dailyGoalMinutes, 25);
      expect(restored.displayName, 'Farid');
    });

    test('falls back to safe defaults for unknown values', () {
      final restored = UserProfile.fromJson({
        'targetLanguage': 'klingon',
        'explanationLanguage': null,
        'level': 'nope',
        'goals': ['unknown'],
      });
      expect(restored.targetLanguage, TargetLanguage.english);
      expect(restored.explanationLanguage, ExplanationLanguage.tajik);
      expect(restored.level, ProficiencyLevel.beginner);
      expect(restored.goals, isEmpty);
    });
  });

  group('Correction', () {
    test('parses backend shape and reports change', () {
      final correction = Correction.fromJson({
        'original': 'I would to school.',
        'corrected': 'I would go to school.',
        'explanation': 'Modal + bare verb.',
        'rule': 'modals',
        'examples': ['I would go.'],
        'exercise': 'Fix it.',
        'confidence': 'low',
      });
      expect(correction.changed, isTrue);
      expect(correction.confidence, CorrectionConfidence.low);
      expect(correction.examples, hasLength(1));
    });

    test('detects no change', () {
      final correction = Correction.fromJson({
        'original': 'I went home.',
        'corrected': 'I went home.',
        'explanation': '',
      });
      expect(correction.changed, isFalse);
    });
  });

  group('bundled content', () {
    test('vocabulary lessons use the selected explanation language', () {
      final tajik = BundledContent.vocabularyLessons(ExplanationLanguage.tajik);
      final russian = BundledContent.vocabularyLessons(
        ExplanationLanguage.russian,
      );
      expect(tajik, isNotEmpty);
      expect(
        tajik.first.items.first.answer,
        isNot(russian.first.items.first.answer),
      );
      expect(tajik.first.items.first.choiceAnswers.length, 4);
      // The correct answer must be among the choices.
      for (final item in tajik.first.items) {
        expect(item.choiceAnswers, contains(item.answer));
      }
    });

    test('grammar lessons have checkable answers', () {
      for (final lesson in BundledContent.grammarLessons(
        ExplanationLanguage.english,
      )) {
        expect(lesson.items, isNotEmpty);
        for (final item in lesson.items) {
          expect(item.check(item.answer), isTrue);
          expect(item.explanation, isNotNull);
        }
      }
    });

    test('daily challenge is stable within a day and adapts to level', () {
      final day = DateTime(2026, 3, 14);
      final first = BundledContent.dailyChallenge(
        day: day,
        lang: ExplanationLanguage.tajik,
        level: ProficiencyLevel.intermediate,
      );
      final second = BundledContent.dailyChallenge(
        day: day,
        lang: ExplanationLanguage.tajik,
        level: ProficiencyLevel.intermediate,
      );
      expect(
        first.items.map((i) => i.id).toList(),
        second.items.map((i) => i.id).toList(),
      );

      final beginner = BundledContent.dailyChallenge(
        day: day,
        lang: ExplanationLanguage.tajik,
        level: ProficiencyLevel.beginner,
      );
      expect(beginner.items.length, lessThanOrEqualTo(first.items.length));
    });

    test('reading passages include answerable questions', () {
      for (final passage in BundledContent.readingPassages(
        ExplanationLanguage.tajik,
      )) {
        expect(passage.text, isNotEmpty);
        for (final question in passage.questions) {
          expect(question.check(question.answer), isTrue);
        }
      }
    });

    test('translation drills accept the canonical English answer', () {
      final lessons = BundledContent.translationLessons(
        ExplanationLanguage.russian,
      );
      for (final item in lessons.first.items) {
        expect(item.check(item.answer), isTrue);
        // Prompts are Russian for Russian learners.
        expect(RegExp(r'[А-Яа-я]').hasMatch(item.prompt), isTrue);
      }
    });
  });
}
