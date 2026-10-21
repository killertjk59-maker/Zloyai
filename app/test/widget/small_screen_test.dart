import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zloy_app/features/home/home_screen.dart';
import 'package:zloy_app/features/settings/about_screen.dart';
import 'package:zloy_app/features/settings/general_settings_screen.dart';
import 'package:zloy_app/features/settings/voice_settings_screen.dart';
import 'package:zloy_app/features/voice/voice_screen.dart';

import '../helpers.dart';

/// Small, cheap Android phones are the target device. Any RenderFlex overflow
/// throws in tests, so this validates the narrow layout for real.
void main() {
  const small = Size(320, 568);

  testWidgets('all main tabs render without overflow at 320 width', (
    tester,
  ) async {
    final harness = await createHarness(profile: onboardedProfile());
    usePhoneSurface(tester, size: small);
    await tester.pumpWidget(harness.buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await settle(tester);

    for (final tab in ['Tutor', 'Practice', 'Progress', 'Settings', 'Home']) {
      await tester.tap(find.text(tab));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'tab $tab');
    }
    harness.dispose();
  });

  testWidgets('practice runner and voice screens fit at 320 width', (
    tester,
  ) async {
    final harness = await createHarness(profile: onboardedProfile());
    await pumpScreen(tester, harness, const VoiceScreen());
    expect(find.text('Read aloud'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpScreen(tester, harness, const GeneralSettingsScreen());
    expect(find.text('Learning language'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpScreen(tester, harness, const VoiceSettingsScreen());
    expect(find.text('Speak tutor answers'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await settle(tester);
    expect(find.text('ENGINE STATUS'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpScreen(tester, harness, const AboutScreen());
    expect(find.text('Version 1.0.0 (build 1)'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await settle(tester);
    }
    expect(find.text('Open source licenses'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text scale does not break the dashboard', (tester) async {
    final harness = await createHarness(profile: onboardedProfile());
    usePhoneSurface(tester, size: const Size(360, 780));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: harness.buildApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    harness.dispose();
  });
}
