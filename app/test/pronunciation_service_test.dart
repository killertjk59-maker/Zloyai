import 'package:flutter_test/flutter_test.dart';
import 'package:zloy_app/models/enums.dart';
import 'package:zloy_app/services/pronunciation_service.dart';

void main() {
  const service = PronunciationService();

  test('perfect match is 100% word match', () {
    final result = service.assess(
      expected: 'I go to school every day.',
      heard: 'I go to school every day',
    );
    expect(result.matchRate, 1.0);
    expect(result.missedWords, isEmpty);
    expect(result.summary(ExplanationLanguage.english), contains('100%'));
  });

  test('partial match marks only missing words', () {
    final result = service.assess(
      expected: 'I go to school every day.',
      heard: 'I go to school',
    );
    expect(result.matchedWords, 4);
    expect(result.missedWords, containsAll(['every', 'day']));
    expect(result.matchRate, closeTo(4 / 6, 0.001));
  });

  test('extra words from the recogniser are reported', () {
    final result = service.assess(
      expected: 'I like tea.',
      heard: 'I really like tea',
    );
    expect(result.extraWords, contains('really'));
    expect(result.matchRate, 1.0);
  });

  test('contractions are expanded before comparing', () {
    final result = service.assess(
      expected: "I don't like coffee.",
      heard: 'I do not like coffee',
    );
    // Don't -> do + not, so all four words should match.
    expect(result.matchRate, 1.0);
  });

  test('complete failure reports zero and says it is not a score', () {
    final result = service.assess(
      expected: 'The weather is cold.',
      heard: 'banana',
    );
    expect(result.matchRate, 0);
    expect(
      result.summary(ExplanationLanguage.english).toLowerCase(),
      contains('recognis'),
    );
  });

  test('empty expectation never divides by zero', () {
    final result = service.assess(expected: '', heard: 'hello');
    expect(result.matchRate, 0);
  });

  test('summaries are localised', () {
    final result = service.assess(expected: 'I go home', heard: 'I go home');
    expect(
      RegExp(r'[\u0400-\u04FF]')
          .hasMatch(result.summary(ExplanationLanguage.tajik)),
      isTrue,
    );
    expect(
      RegExp(r'[\u0400-\u04FF]')
          .hasMatch(result.summary(ExplanationLanguage.russian)),
      isTrue,
    );
  });
}
