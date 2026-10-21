import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zloy_app/features/settings/general_settings_screen.dart';
import 'package:zloy_app/features/settings/personality_settings_screen.dart';
import 'package:zloy_app/features/settings/privacy_screen.dart';
import 'package:zloy_app/features/settings/voice_settings_screen.dart';
import 'package:zloy_app/models/enums.dart';
import 'package:zloy_app/models/user_profile.dart';

import '../helpers.dart';

void main() {
  testWidgets('personality and profanity settings are saved locally', (
    tester,
  ) async {
    final harness = await createHarness(profile: onboardedProfile());
    await pumpScreen(tester, harness, const PersonalitySettingsScreen());

    expect(find.text('Strict'), findsOneWidget);
    await tester.tap(find.text('Roast'));
    await settle(tester);
    expect(harness.settings.settings.personality, PersonalityMode.roast);

    final toggle = find.byType(SwitchListTile);
    await tester.ensureVisible(toggle);
    await settle(tester);
    await tester.tap(toggle);
    await settle(tester);
    expect(harness.settings.settings.profanityEnabled, isTrue);

    // Persisted, not just in memory.
    final stored = harness.prefs.readJson(harness.prefs.settingsKey)!;
    expect(stored['personality'], 'roast');
    expect(stored['profanityEnabled'], isTrue);
  });

  testWidgets('voice settings persist sliders and switches', (tester) async {
    final harness = await createHarness(profile: onboardedProfile());
    await pumpScreen(tester, harness, const VoiceSettingsScreen());

    final switches = find.byType(SwitchListTile);
    final count = switches.evaluate().length;
    expect(count, greaterThanOrEqualTo(4));

    // Turn off microphone input.
    await tester.ensureVisible(switches.at(2));
    await settle(tester);
    await tester.tap(switches.at(2));
    await settle(tester);
    expect(harness.settings.settings.voiceInputEnabled, isFalse);

    // Drag the speed slider.
    final slider = find.byType(Slider).first;
    await tester.ensureVisible(slider);
    await settle(tester);
    await tester.drag(slider, const Offset(60, 0));
    await settle(tester);
    expect(harness.settings.settings.speechRate, greaterThan(0.5));
  });

  testWidgets('backend URL can be saved and tested against a mock server', (
    tester,
  ) async {
    final mock = MockClient((request) async {
      expect(request.url.path, '/api/v1/health');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'status': 'ok',
            'provider': 'openrouter',
            'model': 'vendor/free-model',
            'mock': false,
          }),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final harness = await createHarness(profile: onboardedProfile());
    await pumpScreen(
      tester,
      await createHarness(
        profile: onboardedProfile(),
        settings: const AppSettings(backendBaseUrl: 'https://backend.test'),
        httpClient: mock,
      ),
      const GeneralSettingsScreen(),
    );
    harness.dispose();

    await tester.ensureVisible(find.text('Save & test'));
    await settle(tester);
    await tester.tap(find.text('Save & test'));
    await settle(tester, frames: 20);

    expect(find.textContaining('Connected'), findsOneWidget);
    expect(find.textContaining('vendor/free-model'), findsOneWidget);
  });

  testWidgets('backend test failure is reported honestly', (tester) async {
    final mock = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'detail': {'code': 'config', 'message': 'API key is not configured.'},
        }),
        503,
      ),
    );
    await pumpScreen(
      tester,
      await createHarness(
        profile: onboardedProfile(),
        settings: const AppSettings(backendBaseUrl: 'https://backend.test'),
        httpClient: mock,
      ),
      const GeneralSettingsScreen(),
    );

    await tester.ensureVisible(find.text('Save & test'));
    await settle(tester);
    await tester.tap(find.text('Save & test'));
    await settle(tester, frames: 20);

    expect(find.text('API key is not configured.'), findsOneWidget);
  });

  testWidgets('privacy screen explains local storage and AI forwarding', (
    tester,
  ) async {
    final harness = await createHarness(profile: onboardedProfile());
    await pumpScreen(tester, harness, const PrivacyScreen());

    expect(find.text('Stored on this device'), findsOneWidget);
    expect(find.text('Never collected'), findsOneWidget);
    expect(find.textContaining('No raw voice recordings'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await settle(tester);
    expect(find.textContaining('may forward your text'), findsOneWidget);
    expect(find.text('Voice recognition and synthesis'), findsOneWidget);
  });

  testWidgets('general settings can switch the explanation language', (
    tester,
  ) async {
    final harness = await createHarness(profile: onboardedProfile());
    await pumpScreen(tester, harness, const GeneralSettingsScreen());

    await tester.tap(find.text('Explanation language'));
    await settle(tester);
    await tester.tap(find.text('Русский  ·  Russian'));
    await settle(tester);

    expect(
      harness.settings.profile.explanationLanguage,
      ExplanationLanguage.russian,
    );
  });
}
