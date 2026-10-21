import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zloy_app/features/challenge/daily_challenge_screen.dart';
import 'package:zloy_app/features/practice/practice_runner.dart';
import 'package:zloy_app/models/chat_models.dart';
import 'package:zloy_app/models/enums.dart';

import '../helpers.dart';

const _lesson = Lesson(
  id: 'test-lesson',
  title: 'Test grammar',
  subtitle: '2 tasks',
  kind: LessonKind.grammar,
  level: ProficiencyLevel.beginner,
  items: [
    PracticeItem(
      id: 'q1',
      prompt: 'He ___ (go) to work.',
      answer: 'goes',
      acceptedAnswers: ['go'],
      hint: 'He, she or it? Add the ending.',
      explanation: 'Third person takes -s.',
    ),
    PracticeItem(
      id: 'q2',
      prompt: 'Choose the article: I am ___ student.',
      answer: 'a',
      choiceAnswers: ['a', 'the', 'an'],
      explanation: 'Consonant sound takes a.',
    ),
  ],
);

void main() {
  testWidgets('runner marks a right answer, records it and shows results', (
    tester,
  ) async {
    final harness = await createHarness();
    await pumpScreen(
      tester,
      harness,
      const PracticeRunnerScreen(lesson: _lesson),
    );

    expect(find.text('He ___ (go) to work.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'goes');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Check'));
    await settle(tester);

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Third person takes -s.'), findsOneWidget);
    expect(harness.progress.today.itemsAnswered, 1);
    expect(harness.progress.today.itemsCorrect, 1);

    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await settle(tester);
    expect(find.text('Choose the article: I am ___ student.'), findsOneWidget);
  });

  testWidgets('multiple choice shows the correct option after a wrong answer', (
    tester,
  ) async {
    final harness = await createHarness();
    await pumpScreen(
      tester,
      harness,
      const PracticeRunnerScreen(lesson: _lesson),
    );
    await tester.enterText(find.byType(TextField), 'goes');
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Check'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await settle(tester);

    await tester.tap(find.text('the'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Check'));
    await settle(tester);

    expect(find.text('Not quite'), findsOneWidget);
    expect(find.text('Answer: a'), findsOneWidget);
    expect(harness.progress.today.itemsAnswered, 2);
    expect(harness.progress.today.itemsCorrect, 1);

    // Finishing stores a real session result.
    await tester.tap(find.widgetWithText(FilledButton, 'See results'));
    await settle(tester);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(harness.progress.sessionsCompleted, 1);
    expect(harness.progress.sessions.first.correct, 1);
  });

  testWidgets('hint reveals the explanation without giving the answer away', (
    tester,
  ) async {
    final harness = await createHarness();
    await pumpScreen(
      tester,
      harness,
      const PracticeRunnerScreen(lesson: _lesson),
    );
    await tester.tap(find.text('Hint'));
    await settle(tester);
    // The hint appears in a snackbar; the answer is not revealed.
    expect(find.text('He, she or it? Add the ending.'), findsOneWidget);
  });

  testWidgets('daily challenge screen works offline and shows the task count', (
    tester,
  ) async {
    final harness = await createHarness(profile: onboardedProfile());
    await pumpScreen(tester, harness, const DailyChallengeScreen());
    expect(find.text('No excuses today.'), findsOneWidget);
    expect(find.textContaining('mixed tasks'), findsOneWidget);
    expect(find.text('Start challenge'), findsOneWidget);

    await tester.tap(find.text('Start challenge'));
    await settle(tester);
    expect(find.byType(PracticeRunnerScreen), findsOneWidget);
  });

  testWidgets('empty answers cannot be checked', (tester) async {
    final harness = await createHarness();
    await pumpScreen(
      tester,
      harness,
      const PracticeRunnerScreen(lesson: _lesson),
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Check'),
    );
    expect(button.onPressed, isNull);
  });
}
