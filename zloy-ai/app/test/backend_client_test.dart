import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zloy_app/models/chat_models.dart';
import 'package:zloy_app/models/enums.dart';
import 'package:zloy_app/models/user_profile.dart';
import 'package:zloy_app/services/backend_client.dart';

void main() {
  const profile = UserProfile(
    targetLanguage: TargetLanguage.english,
    explanationLanguage: ExplanationLanguage.tajik,
    level: ProficiencyLevel.beginner,
  );
  const settings = AppSettings(
    backendBaseUrl: 'https://example.test',
    personality: PersonalityMode.strict,
  );

  group('BackendClient', () {
    test('is not configured without a URL and refuses calls', () async {
      final client = BackendClient(baseUrl: '');
      expect(client.isConfigured, isFalse);
      expect(
        () => client.correct(text: 'hi', profile: profile, settings: settings),
        throwsA(
          isA<TutorException>().having(
            (e) => e.kind,
            'kind',
            TutorErrorKind.notConfigured,
          ),
        ),
      );
    });

    test('parses a successful correction reply', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/v1/tutor/correct');
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['target_language'], 'en');
        expect(body['explanation_language'], 'tg');
        expect(body['personality'], 'strict');
        expect(body['profanity'], false);
        // The client must never send credentials.
        expect(
          request.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('authorization')),
        );
        expect(request.body.toLowerCase(), isNot(contains('api_key')));
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'reply': 'Ин нодуруст аст.',
              'source': 'ai',
              'model': 'test/model',
              'correction': {
                'original': 'I would to school.',
                'corrected': 'I would go to school.',
                'explanation': 'Баъди would феъл бе to меояд.',
                'rule': 'modal + bare infinitive',
                'examples': ['I would go.'],
                'exercise': 'Fix: I would to eat.',
                'alternatives': ['I went to school.'],
                'confidence': 'low',
              },
            }),
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = BackendClient(
        baseUrl: 'https://example.test/',
        httpClient: mock,
      );
      late TutorReply reply;
      try {
        reply = await client.correct(
          text: 'I would to school.',
          profile: profile,
          settings: settings,
        );
      } on TutorException catch (e) {
        fail('unexpected ${e.kind}: ${e.detail}');
      }

      expect(reply.source, TutorSource.ai);
      expect(reply.correction, isNotNull);
      expect(reply.correction!.corrected, 'I would go to school.');
      expect(reply.correction!.confidence, CorrectionConfidence.low);
      expect(reply.correction!.alternatives, hasLength(1));
      expect(reply.model, 'test/model');
    });

    test('maps 429 to rate limited', () async {
      final mock = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': {'code': 'rate_limited', 'message': 'Slow down.'},
          }),
          429,
        ),
      );
      final client = BackendClient(baseUrl: 'https://x.test', httpClient: mock);
      await expectLater(
        client.correct(text: 'hi', profile: profile, settings: settings),
        throwsA(
          isA<TutorException>()
              .having((e) => e.kind, 'kind', TutorErrorKind.rateLimited)
              .having((e) => e.message, 'message', 'Slow down.'),
        ),
      );
    });

    test('maps 503 to model unavailable', () async {
      final mock = MockClient((_) async => http.Response('{}', 503));
      final client = BackendClient(baseUrl: 'https://x.test', httpClient: mock);
      await expectLater(
        client.correct(text: 'hi', profile: profile, settings: settings),
        throwsA(
          isA<TutorException>().having(
            (e) => e.kind,
            'kind',
            TutorErrorKind.modelUnavailable,
          ),
        ),
      );
    });

    test('rejects unreadable JSON without leaking internals', () async {
      final mock = MockClient(
        (_) async => http.Response('<html>oops</html>', 200),
      );
      final client = BackendClient(baseUrl: 'https://x.test', httpClient: mock);
      await expectLater(
        client.correct(text: 'hi', profile: profile, settings: settings),
        throwsA(
          isA<TutorException>()
              .having((e) => e.kind, 'kind', TutorErrorKind.badResponse)
              .having(
                (e) => e.message.contains('Stack'),
                'mentions stack',
                false,
              ),
        ),
      );
    });

    test('reports network failures as offline', () async {
      final mock = MockClient(
        (_) async => throw http.ClientException('no route'),
      );
      final client = BackendClient(baseUrl: 'https://x.test', httpClient: mock);
      await expectLater(
        client.correct(text: 'hi', profile: profile, settings: settings),
        throwsA(
          isA<TutorException>().having(
            (e) => e.kind,
            'kind',
            TutorErrorKind.offline,
          ),
        ),
      );
    });

    test('health probe reports provider and mock flag', () async {
      final mock = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'status': 'ok',
            'provider': 'openrouter',
            'model': 'some/free-model',
            'mock': true,
          }),
          200,
        ),
      );
      final client = BackendClient(baseUrl: 'https://x.test', httpClient: mock);
      final health = await client.health();
      expect(health.ok, isTrue);
      expect(health.provider, 'openrouter');
      expect(health.mock, isTrue);
    });
  });
}
