import '../data/offline_rules.dart';
import '../models/chat_models.dart';
import '../models/enums.dart';

/// On-device grammar checker. No network, no model, no invented confidence.
///
/// Its scope is deliberately narrow and it says so in the UI: it covers a
/// fixed set of common English mistakes. It is **not** a language model.
class OfflineTutor {
  const OfflineTutor();

  /// The rule set is English-only for now.
  bool supports(TargetLanguage language) => language == TargetLanguage.english;

  /// Returns `null` when the checker finds nothing to fix (which does not
  /// mean the sentence is perfect — only that no rule matched).
  Correction? check({
    required String text,
    required ExplanationLanguage explanationLanguage,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    var current = trimmed;
    final applied = <GrammarRule>[];

    for (final rule in offlineEnglishRules) {
      final result = rule.apply(current);
      if (result != null && result != current) {
        current = result;
        applied.add(rule);
      }
    }

    if (applied.isEmpty) return null;

    final lang = explanationLanguage.code;
    final explanations = applied
        .take(3)
        .map((r) => r.explanation[lang] ?? r.explanation['en']!)
        .toList();
    final names = applied
        .map((r) => r.ruleName[lang] ?? r.ruleName['en']!)
        .toSet()
        .join(' • ');
    final examples = <String>[];
    for (final rule in applied) {
      for (final example
          in rule.examples[lang] ?? rule.examples['en'] ?? const []) {
        if (!examples.contains(example)) examples.add(example);
        if (examples.length >= 3) break;
      }
      if (examples.length >= 3) break;
    }
    final alternatives = <String>[];
    for (final rule in applied) {
      final alts = rule.alternatives?[lang] ?? rule.alternatives?['en'];
      if (alts != null) alternatives.addAll(alts);
    }

    final isLowConfidence = applied.any((r) => r.lowConfidence);

    return Correction(
      original: trimmed,
      corrected: current,
      explanation: explanations.join('\n\n'),
      rule: names,
      examples: examples,
      exercise: applied.first.exercise[lang] ?? applied.first.exercise['en'],
      alternatives: alternatives,
      confidence: isLowConfidence
          ? CorrectionConfidence.low
          : CorrectionConfidence.high,
    );
  }

  /// Conversational wrapper so offline answers look like tutor replies.
  TutorReply buildReply({
    required String text,
    required PersonalityMode personality,
    required ExplanationLanguage explanationLanguage,
    required TargetLanguage targetLanguage,
  }) {
    final correction = check(
      text: text,
      explanationLanguage: explanationLanguage,
    );

    if (!supports(targetLanguage)) {
      return TutorReply(
        reply: _unsupportedMessage(explanationLanguage),
        source: TutorSource.offline,
      );
    }

    if (correction == null) {
      return TutorReply(
        reply: _cleanMessage(personality, explanationLanguage),
        source: TutorSource.offline,
      );
    }

    return TutorReply(
      reply: _introMessage(
        personality,
        explanationLanguage,
        correction.corrected,
      ),
      correction: correction,
      source: TutorSource.offline,
      followUp: correction.exercise,
    );
  }

  String _unsupportedMessage(ExplanationLanguage lang) => switch (lang) {
    ExplanationLanguage.tajik =>
      'Тафтиши офлайн ҳоло танҳо барои забони англисӣ кор мекунад. '
          'Барои дигар забонҳо ба интернет ва backend ниёз аст.',
    ExplanationLanguage.russian =>
      'Офлайн-проверка сейчас работает только для английского языка. '
          'Для других языков нужен интернет и backend.',
    ExplanationLanguage.english =>
      'The offline checker currently supports English only. '
          'Other languages need the online backend.',
  };

  String _cleanMessage(PersonalityMode mode, ExplanationLanguage lang) {
    final messages = {
      PersonalityMode.normal: {
        ExplanationLanguage.tajik:
            'Тафтиши офлайн хатоеро ки ман мешиносам пайдо накард. '
            'Ин маънои он нест, ки ҷумла комил аст — барои таҳлили пурра '
            'AI лозим аст.',
        ExplanationLanguage.russian:
            'Офлайн-проверка не нашла известных ей ошибок. Это не значит, '
            'что предложение идеально — для полного разбора нужен AI.',
        ExplanationLanguage.english:
            'The offline checker found none of the mistakes it knows about. '
            'That does not mean the sentence is perfect — full analysis '
            'needs the AI.',
      },
      PersonalityMode.strict: {
        ExplanationLanguage.tajik:
            'Тафтиши офлайн хатое наёфт. Хуб. Аммо ин ҳанӯз баҳои ниҳоӣ нест — '
            'барои санҷиши дақиқ AI лозим аст.',
        ExplanationLanguage.russian:
            'Офлайн-проверка ошибок не нашла. Хорошо. Но это не финальная '
            'оценка — для точной проверки нужен AI.',
        ExplanationLanguage.english:
            'The offline checker found nothing. Fine. But that is not a final '
            'grade — exact checking needs the AI.',
      },
      PersonalityMode.roast: {
        ExplanationLanguage.tajik:
            'Ҳатто тафтиши офлайни ман хатое наёфт. Ё ту воқеан хуб навиштӣ, '
            'ё қоидаҳои ман хеле кам ҳастанд. Эҳтимол ҳарду.',
        ExplanationLanguage.russian:
            'Даже моя офлайн-проверка ничего не нашла. Либо ты молодец, либо '
            'мои правила слишком короткие. Скорее всего, и то и другое.',
        ExplanationLanguage.english:
            'Even my offline checker found nothing. Either you actually wrote '
            'it well, or my rule list is small. Probably both.',
      },
      PersonalityMode.shout: {
        ExplanationLanguage.tajik:
            'ТАФТИШИ ОФЛАЙН ХАТО НАЁФТ! Аммо ин ҲАНӮЗ баҳои ниҳоӣ НЕСТ! '
            'Барои санҷиши комил AI лозим аст!',
        ExplanationLanguage.russian:
            'ОФЛАЙН-ПРОВЕРКА ОШИБОК НЕ НАШЛА! Но это НЕ финальная оценка! '
            'Для полной проверки нужен AI!',
        ExplanationLanguage.english:
            'OFFLINE CHECKER FOUND NOTHING! But that is NOT a final grade! '
            'Full checking needs the AI!',
      },
    };
    return messages[mode]![lang]!;
  }

  String _introMessage(
    PersonalityMode mode,
    ExplanationLanguage lang,
    String corrected,
  ) {
    final messages = {
      PersonalityMode.normal: {
        ExplanationLanguage.tajik:
            'Хуб, як чизи хурдро ислоҳ мекунем: «$corrected».',
        ExplanationLanguage.russian:
            'Хорошо, давай немного поправим: «$corrected».',
        ExplanationLanguage.english:
            'Alright, let us fix a small thing: "$corrected".',
      },
      PersonalityMode.strict: {
        ExplanationLanguage.tajik:
            'Ин нодуруст аст. Дуруст: «$corrected». Қоидаро аз нав хон.',
        ExplanationLanguage.russian:
            'Это неверно. Правильно: «$corrected». Прочитай правило заново.',
        ExplanationLanguage.english:
            'That is wrong. Correct: "$corrected". Read the rule again.',
      },
      PersonalityMode.roast: {
        ExplanationLanguage.tajik:
            'Ин грамматика аз ту кӯмак пурсид! Дуруст: «$corrected». Биё, '
            'якҷоя ислоҳаш мекунем.',
        ExplanationLanguage.russian:
            'Эта грамматика взывала о помощи! Правильно: «$corrected». '
            'Давай исправим вместе.',
        ExplanationLanguage.english:
            'That grammar was begging for help! Correct: "$corrected". '
            'Let us fix it together.',
      },
      PersonalityMode.shout: {
        ExplanationLanguage.tajik:
            'ИСТ! Дуруст: «$corrected». Аввал қоидаро санҷ, баъд нависед!',
        ExplanationLanguage.russian:
            'СТОП! Правильно: «$corrected». Сначала проверь правило!',
        ExplanationLanguage.english:
            'STOP! Correct: "$corrected". Check the rule first!',
      },
    };
    return messages[mode]![lang]!;
  }
}
