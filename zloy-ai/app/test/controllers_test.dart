import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zloy_app/models/chat_models.dart';
import 'package:zloy_app/models/enums.dart';
import 'package:zloy_app/models/progress_models.dart';
import 'package:zloy_app/services/preferences_service.dart';
import 'package:zloy_app/state/progress_controller.dart';
import 'package:zloy_app/state/settings_controller.dart';

Future<PreferencesService> freshPrefs([Map<String, Object>? seed]) async {
  SharedPreferences.setMockInitialValues(seed ?? {});
  return PreferencesService.create();
}

String dayKey(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController', () {
    test('normalises backend URLs without inventing localhost', () async {
      final controller = SettingsController(await freshPrefs());
      await controller.load();

      await controller.setBackendUrl('example.com/api/');
      expect(controller.settings.backendBaseUrl, 'https://example.com/api');

      await controller.setBackendUrl('http://10.0.2.2:8000');
      expect(controller.settings.backendBaseUrl, 'http://10.0.2.2:8000');

      await controller.setBackendUrl('   ');
      expect(controller.settings.backendBaseUrl, '');
      expect(controller.settings.hasBackend, isFalse);
    });

    test('persists profile and settings across reloads', () async {
      final prefs = await freshPrefs();
      final controller = SettingsController(prefs);
      await controller.load();
      await controller.setTargetLanguage(TargetLanguage.english);
      await controller.setExplanationLanguage(ExplanationLanguage.russian);
      await controller.setLevel(ProficiencyLevel.upperIntermediate);
      await controller.setPersonality(PersonalityMode.roast);
      await controller.setProfanity(true);
      await controller.setDailyGoalMinutes(30);
      await controller.completeOnboarding();

      final reloaded = SettingsController(prefs);
      await reloaded.load();
      expect(reloaded.profile.explanationLanguage, ExplanationLanguage.russian);
      expect(reloaded.profile.level, ProficiencyLevel.upperIntermediate);
      expect(reloaded.settings.personality, PersonalityMode.roast);
      expect(reloaded.settings.profanityEnabled, isTrue);
      expect(reloaded.profile.dailyGoalMinutes, 30);
      expect(reloaded.needsOnboarding, isFalse);
    });

    test('clamps the daily goal to a sane range', () async {
      final controller = SettingsController(await freshPrefs());
      await controller.load();
      await controller.setDailyGoalMinutes(1000);
      expect(controller.profile.dailyGoalMinutes, 120);
      await controller.setDailyGoalMinutes(1);
      expect(controller.profile.dailyGoalMinutes, 5);
    });

    test('starts with no backend and offline-friendly defaults', () async {
      final controller = SettingsController(await freshPrefs());
      await controller.load();
      expect(controller.settings.hasBackend, isFalse);
      expect(controller.settings.profanityEnabled, isFalse);
      expect(controller.settings.personality, PersonalityMode.strict);
      expect(controller.settings.voiceOutputEnabled, isTrue);
    });
  });

  group('ProgressController', () {
    test('records answers and computes accuracy from real data', () async {
      final prefs = await freshPrefs();
      final progress = ProgressController(prefs);
      await progress.load();
      expect(progress.totalItemsAnswered, 0);
      expect(progress.overallAccuracy, 0);

      await progress.recordAnswer(correct: true);
      await progress.recordAnswer(correct: true);
      await progress.recordAnswer(correct: false);

      expect(progress.totalItemsAnswered, 3);
      expect(progress.totalItemsCorrect, 2);
      expect(progress.overallAccuracy, closeTo(2 / 3, 0.001));
      expect(progress.today.itemsAnswered, 3);
    });

    test('persists activity, sessions and mistakes', () async {
      final prefs = await freshPrefs();
      final progress = ProgressController(prefs);
      await progress.load();
      await progress.recordAnswer(correct: true);
      await progress.addMinutes(10);
      await progress.recordAiMessage();
      await progress.recordSession(
        SessionResult(
          id: 's1',
          kind: LessonKind.grammar,
          title: 'Present Simple',
          correct: 4,
          total: 5,
          completedAt: DateTime.now(),
        ),
      );
      await progress.recordMistake(
        MistakeRecord(
          id: 'm1',
          original: 'He go.',
          corrected: 'He goes.',
          explanation: 'Third person -s.',
          createdAt: DateTime.now(),
        ),
      );

      final reloaded = ProgressController(prefs);
      await reloaded.load();
      expect(reloaded.totalItemsAnswered, 1);
      expect(reloaded.today.minutes, 10);
      expect(reloaded.totalAiMessages, 1);
      expect(reloaded.sessionsCompleted, 1);
      expect(reloaded.mistakes, hasLength(1));
      expect(reloaded.unreviewedMistakes, hasLength(1));
    });

    test('ignores duplicate mistakes but keeps distinct ones', () async {
      final progress = ProgressController(await freshPrefs());
      await progress.load();
      final record = MistakeRecord(
        id: 'a',
        original: 'He go.',
        corrected: 'He goes.',
        explanation: 'x',
        createdAt: DateTime.now(),
      );
      await progress.recordMistake(record);
      await progress.recordMistake(record);
      expect(progress.mistakes, hasLength(1));
      await progress.recordMistake(
        MistakeRecord(
          id: 'b',
          original: 'I have 20 years.',
          corrected: 'I am 20 years old.',
          explanation: 'y',
          createdAt: DateTime.now(),
        ),
      );
      expect(progress.mistakes, hasLength(2));
    });

    test('misleading streak is never invented', () async {
      final progress = ProgressController(await freshPrefs());
      await progress.load();
      expect(progress.streakDays, 0);
    });

    test('streak counts consecutive days with recorded activity', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final prefs = await freshPrefs({
        'zloy.activity.v1':
            '''
        [
          {"date":"${dayKey(twoDaysAgo)}","minutes":5,"itemsAnswered":3,"itemsCorrect":2},
          {"date":"${dayKey(yesterday)}","minutes":7,"itemsAnswered":4,"itemsCorrect":3},
          {"date":"${dayKey(now)}","minutes":2,"itemsAnswered":1,"itemsCorrect":1}
        ]
        ''',
      });
      final progress = ProgressController(prefs);
      await progress.load();
      expect(progress.streakDays, 3);
      expect(progress.lastSevenDays, hasLength(7));
      expect(progress.totalMinutes, 14);
      expect(progress.weeklyAccuracy, closeTo(6 / 8, 0.001));
    });

    test('vocabulary boxes promote on correct and reset on wrong', () async {
      final progress = ProgressController(await freshPrefs());
      await progress.load();
      await progress.recordVocabResult('v1', correct: true);
      expect(progress.vocabProgress('v1')!.box, 1);
      await progress.recordVocabResult('v1', correct: true);
      await progress.recordVocabResult('v1', correct: true);
      expect(progress.vocabProgress('v1')!.box, 3);
      expect(progress.masteredWordCount, 1);
      await progress.recordVocabResult('v1', correct: false);
      expect(progress.vocabProgress('v1')!.box, 0);
      expect(progress.masteredWordCount, 0);
    });

    test('challenge completion is scoped to today', () async {
      final progress = ProgressController(await freshPrefs());
      await progress.load();
      expect(progress.challengeCompletedToday, isFalse);
      await progress.completeChallenge(correct: 5, total: 8);
      expect(progress.challengeCompletedToday, isTrue);
      expect(progress.challengeState!.correct, 5);
    });

    test('reset clears everything', () async {
      final prefs = await freshPrefs();
      final progress = ProgressController(prefs);
      await progress.load();
      await progress.recordAnswer(correct: true);
      await progress.recordVocabResult('v', correct: true);
      await progress.completeChallenge(correct: 1, total: 1);
      await progress.reset();
      expect(progress.totalItemsAnswered, 0);
      expect(progress.wordsPractised, 0);
      expect(progress.challengeCompletedToday, isFalse);
    });

    test('suggested level hint avoids judgement without data', () async {
      final progress = ProgressController(await freshPrefs());
      await progress.load();
      final hint = progress.suggestedLevelHint(
        ProficiencyLevel.beginner,
        ExplanationLanguage.english,
      );
      expect(hint.toLowerCase(), contains('not enough'));
    });
  });
}
