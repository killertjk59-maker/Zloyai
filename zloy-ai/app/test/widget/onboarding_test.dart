import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zloy_app/features/home/home_screen.dart';
import 'package:zloy_app/features/onboarding/onboarding_flow.dart';
import 'package:zloy_app/models/enums.dart';

import '../helpers.dart';

void main() {
  testWidgets('splash routes a new user into onboarding', (tester) async {
    await pumpApp(tester);
    expect(find.byType(OnboardingFlow), findsOneWidget);
    expect(find.text('I am ZLOY.'), findsOneWidget);
    expect(find.text('Free · no account · works offline'), findsOneWidget);
  });

  testWidgets('onboarding walks through every step and lands on home', (
    tester,
  ) async {
    final harness = await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await settle(tester);
    expect(find.text('What do you want to learn?'), findsOneWidget);

    // Target language -> explanation language -> level
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    expect(find.text('How should I explain?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    expect(find.text('Your current level'), findsOneWidget);

    await tester.tap(find.text('Intermediate · B1'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);

    // Goals step blocks progress until at least one goal is chosen.
    expect(find.text('Why are you learning?'), findsOneWidget);
    final continueButton = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    await tester.tap(find.text('Everyday conversation'));
    await settle(tester);
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

    await tester.tap(continueButton);
    await settle(tester);
    expect(find.text('How do you learn best?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
    await settle(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(harness.settings.needsOnboarding, isFalse);
    expect(harness.settings.profile.level, ProficiencyLevel.intermediate);
    expect(harness.settings.profile.goals, contains(LearningGoal.conversation));
  });

  testWidgets('onboarding selection is persisted to local storage', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await settle(tester);

    await tester.tap(find.text('🇷🇺'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    await tester.tap(find.text('Русский').last);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    await tester.tap(find.text('Beginner · A1'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    await tester.tap(find.text('Travel'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
    await settle(tester);

    expect(harness.settings.profile.targetLanguage, TargetLanguage.russian);
    expect(
      harness.settings.profile.explanationLanguage,
      ExplanationLanguage.russian,
    );

    // The values really reached local storage, not just memory.
    final stored = harness.prefs.readJson(harness.prefs.profileKey);
    expect(stored, isNotNull);
    expect(stored!['targetLanguage'], 'ru');
    expect(stored['explanationLanguage'], 'ru');
    expect(stored['onboardingComplete'], isTrue);
    expect(stored['goals'], contains('travel'));
  });
}
