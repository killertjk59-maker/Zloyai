import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zloy_app/features/tutor/tutor_screen.dart';
import 'package:zloy_app/models/enums.dart';
import 'package:zloy_app/models/user_profile.dart';

import '../helpers.dart';

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await settle(tester);
  await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
  await settle(tester, frames: 20);
  // Let the mascot's temporary mood timer finish so no timers stay pending.
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  testWidgets('offline mode answers with a labelled offline correction', (
    tester,
  ) async {
    final harness = await createHarness(profile: onboardedProfile());
    expect(harness.settings.settings.hasBackend, isFalse);
    await pumpScreen(tester, harness, const TutorScreen());

    await _send(tester, 'He go to work every day.');

    // Result is honest about its source.
    expect(find.text('OFFLINE CHECK'), findsOneWidget);
    expect(find.text('He goes to work every day.'), findsOneWidget);
    expect(find.text('You wrote'), findsOneWidget);
    // And it is saved into the mistake history for later review.
    expect(harness.progress.mistakes, hasLength(1));
    expect(harness.progress.today.aiMessages, 1);
  });

  testWidgets('ambiguous input is not silently guessed', (tester) async {
    final harness = await createHarness(profile: onboardedProfile());
    await pumpScreen(tester, harness, const TutorScreen());
    await _send(tester, 'I would to school.');

    expect(find.text('Ambiguous — possible meanings'), findsOneWidget);
    expect(find.textContaining('Confidence: low'), findsOneWidget);
  });

  testWidgets('backend errors show an honest error state with a way forward', (
    tester,
  ) async {
    final mock = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'detail': {'code': 'upstream_error', 'message': 'Model is down.'},
        }),
        503,
      ),
    );
    final harness = await createHarness(
      profile: onboardedProfile(),
      settings: const AppSettings(backendBaseUrl: 'https://backend.test'),
      httpClient: mock,
    );
    await pumpScreen(tester, harness, const TutorScreen());
    await _send(tester, 'He go to work.');

    expect(find.text('AI unavailable'), findsOneWidget);
    expect(find.text('Model is down.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

    // No fake AI answer was inserted.
    expect(find.text('OFFLINE CHECK'), findsNothing);

    // The explicit offline fallback works and is labelled.
    await tester.tap(find.text('Check offline'));
    await settle(tester);
    expect(find.text('OFFLINE CHECK'), findsOneWidget);
    expect(find.text('He goes to work.'), findsOneWidget);
  });

  testWidgets('a real backend reply is rendered and marked as AI', (
    tester,
  ) async {
    final mock = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, Object?>;
      expect(body['text'], 'I would to school.');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'reply': 'Ин ҷумла нодуруст аст.',
            'source': 'ai',
            'model': 'test/free-model',
            'correction': {
              'original': 'I would to school.',
              'corrected': 'I would go to school.',
              'explanation': 'Баъди would феъл бе to меояд.',
              'rule': 'modals',
              'examples': ['I would go home.'],
              'confidence': 'low',
              'alternatives': ['I went to school.'],
            },
          }),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final harness = await createHarness(
      profile: onboardedProfile(),
      settings: const AppSettings(
        backendBaseUrl: 'https://backend.test',
        personality: PersonalityMode.strict,
      ),
      httpClient: mock,
    );
    await pumpScreen(tester, harness, const TutorScreen());
    await _send(tester, 'I would to school.');

    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Ин ҷумла нодуруст аст.'), findsOneWidget);
    expect(find.text('I would go to school.'), findsOneWidget);
    expect(find.text('modals'), findsOneWidget);
  });

  testWidgets('microphone is refused politely when voice input is disabled', (
    tester,
  ) async {
    final harness = await createHarness(
      profile: onboardedProfile(),
      settings: const AppSettings(voiceInputEnabled: false),
    );
    await pumpScreen(tester, harness, const TutorScreen());

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await settle(tester);

    expect(
      find.text('Voice input is disabled in Settings → Voice.'),
      findsOneWidget,
    );
    // Nothing was sent.
    expect(harness.progress.today.aiMessages, 0);
  });

  testWidgets('suggestion chips fill the composer', (tester) async {
    final harness = await createHarness(
      profile: onboardedProfile(explanation: ExplanationLanguage.english),
    );
    await pumpScreen(tester, harness, const TutorScreen());

    expect(find.text('TRY ONE OF THESE'), findsOneWidget);
    await tester.tap(find.text('Yesterday I buy a new phone.'));
    await settle(tester, frames: 20);
    await tester.pump(const Duration(seconds: 6));

    expect(find.text('OFFLINE CHECK'), findsOneWidget);
    expect(find.text('Yesterday I bought a new phone.'), findsOneWidget);
  });

  testWidgets('clearing the conversation removes messages', (tester) async {
    final harness = await createHarness(profile: onboardedProfile());
    await pumpScreen(tester, harness, const TutorScreen());
    await _send(tester, 'He go to work.');
    expect(harness.tutor.messages, isNotEmpty);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(harness.tutor.messages, isEmpty);
    expect(find.text('TRY ONE OF THESE'), findsOneWidget);
  });
}
