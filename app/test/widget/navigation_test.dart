import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zloy_app/features/shell/root_shell.dart';

import '../helpers.dart';

void main() {
  testWidgets('home dashboard renders real (empty) state and quick actions', (
    tester,
  ) async {
    await pumpApp(tester, profile: onboardedProfile());

    expect(find.byType(RootShell), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Daily challenge'), findsWidgets);
    expect(find.text('AI tutor'), findsOneWidget);
    expect(find.text('Speaking'), findsOneWidget);
    // Fresh install: no invented numbers.
    expect(find.text('No practice recorded yet today.'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    // No backend configured -> honest offline notice.
    expect(find.textContaining('offline mode'), findsOneWidget);
  });

  testWidgets('bottom navigation switches all five tabs', (tester) async {
    await pumpApp(tester, profile: onboardedProfile());

    NavigationBar bar() =>
        tester.widget<NavigationBar>(find.byType(NavigationBar));

    expect(bar().selectedIndex, 0);

    await tester.tap(find.text('Tutor'));
    await settle(tester);
    expect(bar().selectedIndex, 1);
    expect(find.text('ZLOY tutor'), findsOneWidget);

    await tester.tap(find.text('Practice'));
    await settle(tester);
    expect(bar().selectedIndex, 2);
    expect(find.text('Everything here works offline.'), findsOneWidget);

    await tester.tap(find.text('Progress'));
    await settle(tester);
    expect(bar().selectedIndex, 3);

    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(bar().selectedIndex, 4);
    expect(find.text('Personality'), findsOneWidget);
  });

  testWidgets('home quick action opens the practice list screens', (
    tester,
  ) async {
    await pumpApp(tester, profile: onboardedProfile());

    final vocabTile = find.text('Vocabulary');
    await tester.ensureVisible(vocabTile);
    await settle(tester);
    await tester.tap(vocabTile);
    await settle(tester);
    expect(find.text('Vocabulary'), findsWidgets);
    expect(find.text('WORD SETS'), findsOneWidget);
    expect(find.text('Weak words'), findsNothing);

    await tester.pageBack();
    await settle(tester);

    final grammarTile = find.text('Grammar');
    await tester.ensureVisible(grammarTile);
    await settle(tester);
    await tester.tap(grammarTile);
    await settle(tester);
    expect(find.text('Grammar practice'), findsOneWidget);
    expect(find.text('LESSONS'), findsOneWidget);
  });

  testWidgets('empty states are shown for progress and history', (
    tester,
  ) async {
    await pumpApp(tester, profile: onboardedProfile());
    await tester.tap(find.text('Progress'));
    await settle(tester);
    expect(find.text('No data yet'), findsOneWidget);
  });
}
