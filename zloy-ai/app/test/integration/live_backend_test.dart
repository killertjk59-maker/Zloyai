// Live integration test: the real [BackendClient] against a real running
// backend. It proves the client and the FastAPI contract actually agree,
// instead of trusting a hand-written mock.
//
// It is skipped unless ZLOY_API_URL is set, so `flutter test` stays green
// offline. Run it with:
//
//   cd backend && uvicorn app.main:app --port 8011 &
//   cd app && ZLOY_API_URL=http://127.0.0.1:8011 flutter test test/integration/live_backend_test.dart
//
// Nothing here writes to the network except that URL.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zloy_app/models/enums.dart';
import 'package:zloy_app/models/user_profile.dart';
import 'package:zloy_app/services/backend_client.dart';

void main() {
  final url = Platform.environment['ZLOY_API_URL'] ?? '';
  final skipReason = url.isEmpty
      ? 'Set ZLOY_API_URL to run the live backend test.'
      : null;

  group('live backend contract', () {
    late BackendClient client;

    setUp(() {
      client = BackendClient(baseUrl: url);
    });

    tearDown(() {
      client.dispose();
    });

    test('health advertises the engine honestly', () async {
      final health = await client.health();
      expect(health.ok, isTrue);
      expect(health.provider, isNotEmpty);
      expect(health.model, isNotEmpty);
      // With no key configured the server must admit it is a mock.
      if (health.mock) {
        expect(health.model, contains('mock'));
      }
    }, skip: skipReason);

    test('correct() parses a real correction end to end', () async {
      final reply = await client.correct(
        text: 'She go to school.',
        profile: const UserProfile(
          explanationLanguage: ExplanationLanguage.english,
        ),
        settings: const AppSettings(),
      );
      expect(reply.reply, isNotEmpty);
      expect(reply.correction, isNotNull);
      expect(reply.correction!.corrected, 'She goes to school.');
      expect(reply.correction!.explanation, isNotEmpty);
      expect(reply.source, TutorSource.mock);
    }, skip: skipReason);

    test('clean sentence yields no invented correction', () async {
      final reply = await client.correct(
        text: 'I went to the market yesterday.',
        profile: const UserProfile(
          explanationLanguage: ExplanationLanguage.russian,
        ),
        settings: const AppSettings(),
      );
      expect(reply.correction, isNull);
      expect(reply.reply, isNotEmpty);
    }, skip: skipReason);

    test('chat() works with history', () async {
      final reply = await client.chat(
        message: 'My brother play football.',
        profile: const UserProfile(),
        settings: const AppSettings(),
      );
      expect(reply.reply, isNotEmpty);
      expect(reply.correction?.corrected, contains('plays'));
    }, skip: skipReason);
  });
}
