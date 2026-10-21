/// Deterministic, offline English grammar rules.
///
/// This is the honest offline fallback: a small rule engine that runs on the
/// device with no network and no model. It is explicitly labelled as an
/// offline checker in the UI — it is never presented as AI output.
///
/// Rules are collected in a fixed order. Each rule returns the rewritten
/// sentence, or `null` when it does not apply.
library;

class GrammarRule {
  const GrammarRule({
    required this.id,
    required this.ruleName,
    required this.explanation,
    required this.apply,
    this.examples = const {},
    this.exercise = const {},
    this.lowConfidence = false,
    this.alternatives,
  });

  final String id;

  /// Localised rule name: keys `en`, `ru`, `tg`.
  final Map<String, String> ruleName;

  /// Localised explanation: keys `en`, `ru`, `tg`.
  final Map<String, String> explanation;

  final String? Function(String sentence) apply;

  /// Localised extra example sentences.
  final Map<String, List<String>> examples;

  /// Localised practice prompt.
  final Map<String, String> exercise;

  /// True when the rule cannot know the intended meaning (ambiguity).
  final bool lowConfidence;

  /// Localised alternative readings for ambiguous input.
  final Map<String, List<String>>? alternatives;
}

const Map<String, String> _irregularPast = {
  'go': 'went',
  'eat': 'ate',
  'see': 'saw',
  'buy': 'bought',
  'come': 'came',
  'take': 'took',
  'have': 'had',
  'do': 'did',
  'make': 'made',
  'say': 'said',
  'get': 'got',
  'know': 'knew',
  'write': 'wrote',
  'speak': 'spoke',
  'drink': 'drank',
  'give': 'gave',
  'find': 'found',
  'think': 'thought',
};

const Map<String, String> _thirdPerson = {
  'have': 'has',
  'do': 'does',
  'go': 'goes',
  'be': 'is',
  'watch': 'watches',
  'teach': 'teaches',
  'study': 'studies',
  'try': 'tries',
  'fly': 'flies',
  'say': 'says',
};

String _conjugateThirdPerson(String verb) {
  final lower = verb.toLowerCase();
  if (_thirdPerson.containsKey(lower)) return _thirdPerson[lower]!;
  if (lower.endsWith('y') && lower.length > 1) {
    const vowels = {'a', 'e', 'i', 'o', 'u'};
    if (!vowels.contains(lower[lower.length - 2])) {
      return '${verb.substring(0, verb.length - 1)}ies';
    }
  }
  if (lower.endsWith('s') ||
      lower.endsWith('sh') ||
      lower.endsWith('ch') ||
      lower.endsWith('x') ||
      lower.endsWith('o')) {
    return '${verb}es';
  }
  return '${verb}s';
}

String _capitalizeFirst(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

final List<GrammarRule> offlineEnglishRules = [
  // 1. "would to" — ambiguous, so we refuse to guess the meaning.
  GrammarRule(
    id: 'would_to',
    lowConfidence: true,
    ruleName: {
      'en': 'Modal verbs + bare infinitive',
      'ru': 'Модальные глаголы + инфинитив без to',
      'tg': 'Феълҳои модалӣ + масдар бе to',
    },
    explanation: {
      'en':
          'After the modal verb "would" the verb comes without "to": '
          '"would go", not "would to go". But if you meant a finished action '
          'in the past, the correct form is the past simple: "went".',
      'ru':
          'После модального глагола "would" глагол употребляется без "to": '
          '"would go", а не "would to go". Но если речь о завершённом '
          'действии в прошлом, нужен Past Simple: "went".',
      'tg':
          'Баъди феъли модалии "would" феъл бе "to" меояд: "would go", '
          'на "would to go". Аммо агар дар бораи амали гузаштаи анҷомёфта '
          'гап занӣ, шакли Past Simple лозим аст: "went".',
    },
    examples: {
      'en': [
        'I would go to London if I had money. — conditional',
        'I went to school yesterday. — finished past action',
      ],
      'ru': [
        'I would go to London if I had money. — условное',
        'I went to school yesterday. — завершённое действие в прошлом',
      ],
      'tg': [
        'I would go to London if I had money. — шартӣ',
        'I went to school yesterday. — амали гузаштаи анҷомёфта',
      ],
    },
    exercise: {
      'en': 'Fill in: "If I had time, I ___ (go) to the gym."',
      'ru': 'Вставьте: «If I had time, I ___ (go) to the gym.»',
      'tg': 'Пур кунед: «If I had time, I ___ (go) to the gym.»',
    },
    alternatives: {
      'en': [
        'If you meant a finished past action: "I went to school."',
        'If you meant a repeated past habit: "I would go to school (every day)."',
      ],
      'ru': [
        'Если речь о завершённом действии: «I went to school.»',
        'Если речь о привычке в прошлом: «I would go to school (every day).»',
      ],
      'tg': [
        'Агар амали гузаштаи анҷомёфтаро дар назар дошта бошӣ: «I went to school.»',
        'Агар одати гузаштаро дар назар дошта бошӣ: «I would go to school (every day).»',
      ],
    },
    apply: (s) {
      final pattern = RegExp(
        r'\b(would)\s+to\s+([a-z]+)\b',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(s);
      if (match == null) return null;
      final verb = match.group(2)!;
      return s.replaceRange(match.start, match.end, '${match.group(1)} $verb');
    },
  ),

  // 2. subject–verb agreement for he/she/it in the present simple.
  GrammarRule(
    id: 'third_person_s',
    ruleName: {
      'en': 'Present simple: -s for he / she / it',
      'ru': 'Present Simple: -s для he / she / it',
      'tg': 'Ҳозираи оддӣ: -s барои he / she / it',
    },
    explanation: {
      'en':
          'In the present simple, he / she / it takes a verb ending in -s '
          '(or -es): "he goes", "she works".',
      'ru':
          'В Present Simple с he / she / it глагол получает окончание -s '
          '(или -es): "he goes", "she works".',
      'tg':
          'Дар замони ҳозираи оддӣ бо he / she / it феъл бандаки -s '
          '(ё -es) мегирад: "he goes", "she works".',
    },
    examples: {
      'en': ['She works in a hospital.', 'He has two brothers.'],
      'ru': ['She works in a hospital.', 'He has two brothers.'],
      'tg': ['She works in a hospital.', 'He has two brothers.'],
    },
    exercise: {
      'en': 'Correct: "My brother play football every Sunday."',
      'ru': 'Исправьте: «My brother play football every Sunday.»',
      'tg': 'Ислоҳ кунед: «My brother play football every Sunday.»',
    },
    apply: (s) {
      final pattern = RegExp(
        r'\b(he|she|it)\s+(go|like|want|need|know|think|say|do|have|play|work|live|study|eat|make|take|come|see|look|feel|try|watch|read|write|speak|learn|help|love|walk)\b',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(s);
      if (match == null) return null;
      final verb = match.group(2)!.toLowerCase();
      return s.replaceRange(
        match.start,
        match.end,
        '${match.group(1)} ${_conjugateThirdPerson(verb)}',
      );
    },
  ),

  // 3. "I have 20 years old"
  GrammarRule(
    id: 'age_be',
    ruleName: {
      'en': 'Age uses the verb "to be"',
      'ru': 'Возраст: глагол to be',
      'tg': 'Синну сол бо феъли to be',
    },
    explanation: {
      'en':
          'English expresses age with "to be", not "to have": '
          '"I am 20 years old".',
      'ru':
          'Возраст в английском передаётся через to be, а не to have: '
          '"I am 20 years old".',
      'tg':
          'Синну сол бо феъли to be ифода мешавад, на бо to have: '
          '"I am 20 years old".',
    },
    examples: {
      'en': ['My sister is 12 years old.', 'How old are you?'],
      'ru': ['My sister is 12 years old.', 'How old are you?'],
      'tg': ['My sister is 12 years old.', 'How old are you?'],
    },
    exercise: {
      'en': 'Say your age in one sentence using "to be".',
      'ru': 'Скажите свой возраст одним предложением через to be.',
      'tg': 'Синну соли худро бо як ҷумла бо to be гӯед.',
    },
    apply: (s) {
      final pattern = RegExp(
        r'\b(I|i|you|we|they|he|she)\s+(have|has)\s+(\d+)\s+years?\s+old\b',
      );
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      final subject = m.group(1)!;
      final verb = switch (subject.toLowerCase()) {
        'i' => 'am',
        'he' || 'she' => 'is',
        _ => 'are',
      };
      return s.replaceRange(
        m.start,
        m.end,
        '$subject $verb ${m.group(3)} years old',
      );
    },
  ),

  // 4. "I am agree"
  GrammarRule(
    id: 'am_agree',
    ruleName: {
      'en': '"agree" is a verb, not an adjective',
      'ru': '"agree" — глагол, а не прилагательное',
      'tg': '"agree" феъл аст, на сифат',
    },
    explanation: {
      'en':
          'Do not put "to be" before a main verb: "I agree", '
          'not "I am agree".',
      'ru':
          'Не ставьте to be перед смысловым глаголом: "I agree", '
          'а не "I am agree".',
      'tg':
          'Пеш аз феъли асосӣ to be намегузоранд: "I agree", '
          'на "I am agree".',
    },
    examples: {
      'en': ['I agree with you.', 'I completely agree.'],
      'ru': ['I agree with you.', 'I completely agree.'],
      'tg': ['I agree with you.', 'I completely agree.'],
    },
    exercise: {
      'en': 'Translate: «Ман бо ту розӣ ҳастам.»',
      'ru': 'Переведите: «Я с тобой согласен.»',
      'tg': 'Тарҷума кунед: «Ман бо ту розӣ ҳастам.»',
    },
    apply: (s) {
      final pattern = RegExp(r'\b(I|i)\s+am\s+agree\b');
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      return s.replaceRange(m.start, m.end, '${m.group(1)} agree');
    },
  ),

  // 5. uncountable / plural-only mistakes
  GrammarRule(
    id: 'uncountable',
    ruleName: {
      'en': 'Uncountable nouns have no plural',
      'ru': 'Неисчисляемые существительные без множественного числа',
      'tg': 'Исмҳои ношумурданӣ шакли ҷамъ надоранд',
    },
    explanation: {
      'en':
          'Words like information, advice, furniture and equipment are '
          'uncountable: "some information", never "informations".',
      'ru':
          'Слова information, advice, furniture, equipment неисчисляемые: '
          '"some information", а не "informations".',
      'tg':
          'Калимаҳои information, advice, furniture, equipment ношумурданд: '
          '"some information", на "informations".',
    },
    examples: {
      'en': ['I need more information.', 'She gave me good advice.'],
      'ru': ['I need more information.', 'She gave me good advice.'],
      'tg': ['I need more information.', 'She gave me good advice.'],
    },
    exercise: {
      'en': 'Fix: "He gave me two advices."',
      'ru': 'Исправьте: «He gave me two advices.»',
      'tg': 'Ислоҳ кунед: «He gave me two advices.»',
    },
    apply: (s) {
      const fixes = {
        'informations': 'information',
        'advices': 'advice',
        'furnitures': 'furniture',
        'equipments': 'equipment',
        'peoples': 'people',
        'researches': 'research',
        'knowledges': 'knowledge',
      };
      var out = s;
      for (final entry in fixes.entries) {
        out = out.replaceAll(
          RegExp('\\b${entry.key}\\b', caseSensitive: false),
          entry.value,
        );
      }
      return out == s ? null : out;
    },
  ),

  // 6. "didn't went"
  GrammarRule(
    id: 'aux_past',
    ruleName: {
      'en': 'Auxiliary do/does/did + base verb',
      'ru': 'Вспомогательный do/does/did + инфинитив',
      'tg': 'Феъли ёридиҳандаи do/does/did + масдар',
    },
    explanation: {
      'en':
          'After do / does / did the main verb stays in the base form: '
          '"I didn\'t go", not "I didn\'t went".',
      'ru':
          'После do / does / did смысловой глагол стоит в базовой форме: '
          '"I didn\'t go", а не "I didn\'t went".',
      'tg':
          'Баъди do / does / did феъли асосӣ дар шакли аслӣ мемонад: '
          '"I didn\'t go", на "I didn\'t went".',
    },
    examples: {
      'en': ['I didn\'t see him.', 'She doesn\'t have time.'],
      'ru': ['I didn\'t see him.', 'She doesn\'t have time.'],
      'tg': ['I didn\'t see him.', 'She doesn\'t have time.'],
    },
    exercise: {
      'en': 'Fix: "We didn\'t took the bus."',
      'ru': 'Исправьте: «We didn\'t took the bus.»',
      'tg': 'Ислоҳ кунед: «We didn\'t took the bus.»',
    },
    apply: (s) {
      final pattern = RegExp(
        r"\b(did not|didn't|does not|doesn't|do not|don't)\s+([a-z]+ed|[a-z]+)\b",
        caseSensitive: false,
      );
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      final verb = m.group(2)!.toLowerCase();
      String? base;
      for (final entry in _irregularPast.entries) {
        if (entry.value == verb) base = entry.key;
      }
      base ??= (verb.endsWith('ed') && verb.length > 3)
          ? verb.substring(0, verb.length - 2)
          : null;
      if (base == null) return null;
      return s.replaceRange(m.start, m.end, '${m.group(1)} $base');
    },
  ),

  // 7. "more better"
  GrammarRule(
    id: 'double_comparative',
    ruleName: {
      'en': 'One comparative is enough',
      'ru': 'Достаточно одной сравнительной степени',
      'tg': 'Як дараҷаи муқоисавӣ кофист',
    },
    explanation: {
      'en':
          'Short adjectives form the comparative with -er, so "more" is not '
          'needed: "better", "easier".',
      'ru':
          'Короткие прилагательные образуют сравнение с -er, поэтому more '
          'не нужно: "better", "easier".',
      'tg':
          'Сифатҳои кӯтоҳ дараҷаи муқоисавиро бо -er месозанд, бинобар ин '
          'more лозим нест: "better", "easier".',
    },
    examples: {
      'en': ['This exercise is easier than the last one.'],
      'ru': ['This exercise is easier than the last one.'],
      'tg': ['This exercise is easier than the last one.'],
    },
    exercise: {
      'en': 'Fix: "My English is more better now."',
      'ru': 'Исправьте: «My English is more better now.»',
      'tg': 'Ислоҳ кунед: «My English is more better now.»',
    },
    apply: (s) {
      final pattern = RegExp(
        r'\bmore\s+(better|worse|easier|harder|faster|slower|bigger|smaller|happier)\b',
        caseSensitive: false,
      );
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      return s.replaceRange(m.start, m.end, m.group(1)!);
    },
  ),

  // 8. "I don't know nothing"
  GrammarRule(
    id: 'double_negative',
    ruleName: {
      'en': 'Avoid double negatives',
      'ru': 'Не используйте двойное отрицание',
      'tg': 'Инкори дучанда наболед',
    },
    explanation: {
      'en':
          'One negative per clause is enough in English. With "don\'t" use '
          '"anything / anybody / anywhere", not "nothing / nobody / nowhere".',
      'ru':
          'В английском в одном предложении одно отрицание. С "don\'t" '
          'используйте anything / anybody / anywhere.',
      'tg':
          'Дар забони англисӣ дар як ҷумла як инкор кофист. Бо "don\'t" '
          'калимаҳои anything / anybody / anywhere истифода мешаванд.',
    },
    examples: {
      'en': ['I don\'t know anything.', 'Nobody called me.'],
      'ru': ['I don\'t know anything.', 'Nobody called me.'],
      'tg': ['I don\'t know anything.', 'Nobody called me.'],
    },
    exercise: {
      'en': 'Fix: "She doesn\'t say nothing."',
      'ru': 'Исправьте: «She doesn\'t say nothing.»',
      'tg': 'Ислоҳ кунед: «She doesn\'t say nothing.»',
    },
    apply: (s) {
      final negAux = RegExp(
        r"\b(don\'t|doesn\'t|didn\'t|can\'t|won\'t|isn\'t|aren\'t|wasn\'t|weren\'t|not)\b",
        caseSensitive: false,
      );
      if (!negAux.hasMatch(s)) return null;
      const swaps = {
        'nothing': 'anything',
        'nobody': 'anybody',
        'nowhere': 'anywhere',
        'never': 'ever',
      };
      var out = s;
      for (final entry in swaps.entries) {
        out = out.replaceAll(
          RegExp('\\b${entry.key}\\b', caseSensitive: false),
          entry.value,
        );
      }
      return out == s ? null : out;
    },
  ),

  // 9. "since three years"
  GrammarRule(
    id: 'since_for',
    ruleName: {
      'en': 'for + duration, since + starting point',
      'ru': 'for + длительность, since + точка отсчёта',
      'tg': 'for + давомнокӣ, since + нуқтаи оғоз',
    },
    explanation: {
      'en':
          'Use "for" with a length of time (for two years) and "since" with '
          'a start point (since 2020).',
      'ru':
          'Используйте for с длительностью (for two years), а since — с '
          'точкой отсчёта (since 2020).',
      'tg':
          'Бо давомнокӣ "for" (for two years) ва бо нуқтаи оғоз "since" '
          '(since 2020) истифода мешавад.',
    },
    examples: {
      'en': [
        'I have lived here for three years.',
        'I have lived here since 2021.',
      ],
      'ru': [
        'I have lived here for three years.',
        'I have lived here since 2021.',
      ],
      'tg': [
        'I have lived here for three years.',
        'I have lived here since 2021.',
      ],
    },
    exercise: {
      'en': 'Choose: "She has worked here ___ 2019." (for / since)',
      'ru': 'Выберите: «She has worked here ___ 2019.» (for / since)',
      'tg': 'Интихоб кунед: «She has worked here ___ 2019.» (for / since)',
    },
    apply: (s) {
      final pattern = RegExp(
        r'\bsince\s+(\d+|two|three|four|five|six|ten|twenty|a few)\s+(years?|months?|days?|weeks?|hours?)\b',
        caseSensitive: false,
      );
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      return s.replaceRange(m.start, m.end, 'for ${m.group(1)} ${m.group(2)}');
    },
  ),

  // 10. "explain me"
  GrammarRule(
    id: 'explain_to_me',
    ruleName: {
      'en': 'explain something TO somebody',
      'ru': 'explain something TO somebody',
      'tg': 'explain something TO somebody',
    },
    explanation: {
      'en':
          'The verb "explain" needs "to" before the person: '
          '"explain it to me".',
      'ru':
          'После explain перед адресатом нужен предлог to: '
          '"explain it to me".',
      'tg':
          'Баъди explain пеш аз шахс ҳарфи пешоянд "to" лозим аст: '
          '"explain it to me".',
    },
    examples: {
      'en': ['Can you explain this rule to me?'],
      'ru': ['Can you explain this rule to me?'],
      'tg': ['Can you explain this rule to me?'],
    },
    exercise: {
      'en': 'Fix: "Explain me this word."',
      'ru': 'Исправьте: «Explain me this word.»',
      'tg': 'Ислоҳ кунед: «Explain me this word.»',
    },
    apply: (s) {
      final pattern = RegExp(
        r'\b(explain|describe|suggest)\s+(me|him|her|us|them)\b',
        caseSensitive: false,
      );
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      return s.replaceRange(m.start, m.end, '${m.group(1)} to ${m.group(2)}');
    },
  ),

  // 11. "much people"
  GrammarRule(
    id: 'many_people',
    ruleName: {
      'en': 'many + countable, much + uncountable',
      'ru': 'many + исчисляемые, much + неисчисляемые',
      'tg': 'many + шумурданӣ, much + ношумурданӣ',
    },
    explanation: {
      'en':
          'Use "many" with countable nouns (many people) and "much" with '
          'uncountable ones (much water).',
      'ru':
          'Many — с исчисляемыми (many people), much — с неисчисляемыми '
          '(much water).',
      'tg':
          'Many бо исмҳои шумурданӣ (many people) ва much бо '
          'ношумурданӣ (much water) меояд.',
    },
    examples: {
      'en': ['There are many people here.', 'I don\'t have much time.'],
      'ru': ['There are many people here.', 'I don\'t have much time.'],
      'tg': ['There are many people here.', 'I don\'t have much time.'],
    },
    exercise: {
      'en': 'Choose: "How ___ students are in your class?"',
      'ru': 'Выберите: «How ___ students are in your class?»',
      'tg': 'Интихоб кунед: «How ___ students are in your class?»',
    },
    apply: (s) {
      final pattern = RegExp(
        r'\bmuch\s+(people|books|friends|things|students|cars|questions|words|mistakes)\b',
        caseSensitive: false,
      );
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      return s.replaceRange(m.start, m.end, 'many ${m.group(1)}');
    },
  ),

  // 12. "How I can"
  GrammarRule(
    id: 'question_order',
    ruleName: {
      'en': 'Question word order',
      'ru': 'Порядок слов в вопросе',
      'tg': 'Тартиби калимаҳо дар савол',
    },
    explanation: {
      'en':
          'In direct questions the auxiliary verb comes before the subject: '
          '"How can I help you?", not "How I can help you?".',
      'ru':
          'В прямом вопросе вспомогательный глагол стоит перед подлежащим: '
          '"How can I help you?".',
      'tg':
          'Дар саволи мустақим феъли ёридиҳанда пеш аз мубтадо меояд: '
          '"How can I help you?".',
    },
    examples: {
      'en': ['Where can I buy a ticket?', 'What should we do?'],
      'ru': ['Where can I buy a ticket?', 'What should we do?'],
      'tg': ['Where can I buy a ticket?', 'What should we do?'],
    },
    exercise: {
      'en': 'Fix: "Where I can find the station?"',
      'ru': 'Исправьте: «Where I can find the station?»',
      'tg': 'Ислоҳ кунед: «Where I can find the station?»',
    },
    apply: (s) {
      final pattern = RegExp(
        r'\b(how|where|what|when|why|which)\s+(I|we|you|they|he|she)\s+(can|should|must|will|would)\b',
        caseSensitive: false,
      );
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      return s.replaceRange(
        m.start,
        m.end,
        '${m.group(1)} ${m.group(3)} ${m.group(2)}',
      );
    },
  ),

  // 13. "look forward to hear"
  GrammarRule(
    id: 'gerund_after_preposition',
    ruleName: {
      'en': 'Preposition + -ing',
      'ru': 'Предлог + -ing',
      'tg': 'Пешоянд + -ing',
    },
    explanation: {
      'en':
          'After a preposition (to, of, about) the verb takes -ing: '
          '"look forward to hearing", "interested in learning".',
      'ru': 'После предлога глагол принимает -ing: "look forward to hearing".',
      'tg': 'Баъди пешоянд феъл шакли -ing мегирад: "look forward to hearing".',
    },
    examples: {
      'en': ['I look forward to hearing from you.'],
      'ru': ['I look forward to hearing from you.'],
      'tg': ['I look forward to hearing from you.'],
    },
    exercise: {
      'en': 'Fix: "I am interested in learn English."',
      'ru': 'Исправьте: «I am interested in learn English.»',
      'tg': 'Ислоҳ кунед: «I am interested in learn English.»',
    },
    apply: (s) {
      const ingForms = {
        'hear': 'hearing',
        'see': 'seeing',
        'meet': 'meeting',
        'go': 'going',
        'work': 'working',
        'talk': 'talking',
        'visit': 'visiting',
        'learn': 'learning',
        'read': 'reading',
      };
      final pattern = RegExp(
        r'\b(look forward to|looking forward to|interested in|good at|afraid of|instead of)\s+([a-z]+)\b',
        caseSensitive: false,
      );
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      final gerund = ingForms[m.group(2)!.toLowerCase()];
      if (gerund == null) return null;
      return s.replaceRange(m.start, m.end, '${m.group(1)} $gerund');
    },
  ),

  // 14. Missing article before a profession.
  GrammarRule(
    id: 'article_profession',
    ruleName: {
      'en': 'a / an before a singular profession',
      'ru': 'a / an перед профессией в единственном числе',
      'tg': 'a / an пеш аз касб дар шакли танҳо',
    },
    explanation: {
      'en': 'Singular countable nouns need an article: "I am a student".',
      'ru':
          'Исчисляемое существительное в единственном числе требует артикль: '
          '"I am a student".',
      'tg': 'Исми шумурданиаш танҳо артикл талаб мекунад: "I am a student".',
    },
    examples: {
      'en': ['She is a doctor.', 'He is an engineer.'],
      'ru': ['She is a doctor.', 'He is an engineer.'],
      'tg': ['She is a doctor.', 'He is an engineer.'],
    },
    exercise: {
      'en': 'Fix: "My father is engineer."',
      'ru': 'Исправьте: «My father is engineer.»',
      'tg': 'Ислоҳ кунед: «My father is engineer.»',
    },
    apply: (s) {
      final pattern = RegExp(
        r'\b(am|is|are)\s+(student|teacher|doctor|engineer|driver|nurse|programmer|designer|lawyer|waiter|seller)\b',
        caseSensitive: false,
      );
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      final noun = m.group(2)!;
      final article = 'aeiou'.contains(noun[0].toLowerCase()) ? 'an' : 'a';
      return s.replaceRange(m.start, m.end, '${m.group(1)} $article $noun');
    },
  ),

  // 15. he don't
  GrammarRule(
    id: 'third_person_negative',
    ruleName: {
      'en': 'he / she / it + doesn\'t',
      'ru': 'he / she / it + doesn\'t',
      'tg': 'he / she / it + doesn\'t',
    },
    explanation: {
      'en':
          'For he / she / it the negative auxiliary is "doesn\'t": '
          '"he doesn\'t work", not "he don\'t work".',
      'ru':
          'Для he / she / it отрицание образуется через doesn\'t: '
          '"he doesn\'t work".',
      'tg':
          'Барои he / she / it шакли инкорӣ "doesn\'t" аст: '
          '"he doesn\'t work".',
    },
    examples: {
      'en': ['She doesn\'t drink coffee.'],
      'ru': ['She doesn\'t drink coffee.'],
      'tg': ['She doesn\'t drink coffee.'],
    },
    exercise: {
      'en': 'Fix: "He don\'t like fish."',
      'ru': 'Исправьте: «He don\'t like fish.»',
      'tg': 'Ислоҳ кунед: «He don\'t like fish.»',
    },
    apply: (s) {
      final pattern = RegExp(
        r"\b(he|she|it)\s+(don't|do not)\b",
        caseSensitive: false,
      );
      final m = pattern.firstMatch(s);
      if (m == null) return null;
      return s.replaceRange(m.start, m.end, "${m.group(1)} doesn't");
    },
  ),

  // 16. Past time marker + present verb
  GrammarRule(
    id: 'past_marker',
    ruleName: {
      'en': 'Past time marker needs a past verb',
      'ru': 'Маркер прошлого требует глагол в прошедшем времени',
      'tg': 'Нишонаи гузашта феъли гузаштаро талаб мекунад',
    },
    explanation: {
      'en':
          'With "yesterday", "last week" or "…ago" the verb must be in the '
          'past simple: "yesterday I went", not "yesterday I go".',
      'ru':
          'С yesterday, last week, …ago глагол стоит в Past Simple: '
          '"yesterday I went".',
      'tg':
          'Бо yesterday, last week, …ago феъл дар Past Simple меояд: '
          '"yesterday I went".',
    },
    examples: {
      'en': [
        'Yesterday I went to the market.',
        'Last week she bought a phone.',
      ],
      'ru': [
        'Yesterday I went to the market.',
        'Last week she bought a phone.',
      ],
      'tg': [
        'Yesterday I went to the market.',
        'Last week she bought a phone.',
      ],
    },
    exercise: {
      'en': 'Fix: "Last night we eat pizza."',
      'ru': 'Исправьте: «Last night we eat pizza.»',
      'tg': 'Ислоҳ кунед: «Last night we eat pizza.»',
    },
    apply: (s) {
      final marker = RegExp(
        r'\b(yesterday|last night|last week|last month|last year|ago)\b',
        caseSensitive: false,
      );
      if (!marker.hasMatch(s)) return null;
      // Replace only the first present-tense verb we recognise, keeping the
      // rest of the sentence (spacing, punctuation) untouched.
      for (final match in RegExp(r"[A-Za-z']+").allMatches(s)) {
        final token = match.group(0)!.toLowerCase();
        final past = _irregularPast[token];
        if (past != null) {
          return s.replaceRange(match.start, match.end, past);
        }
      }
      return null;
    },
  ),

  // 17. Global: lowercase "i" as a pronoun.
  GrammarRule(
    id: 'capital_i',
    ruleName: {
      'en': 'The pronoun "I" is always capitalised',
      'ru': 'Местоимение "I" всегда с заглавной буквы',
      'tg': 'Ҷонишини "I" ҳамеша бо ҳарфи калон навишта мешавад',
    },
    explanation: {
      'en':
          'In English the pronoun "I" is always written with a capital '
          'letter, wherever it stands in the sentence.',
      'ru': 'В английском местоимение I всегда пишется с заглавной буквы.',
      'tg':
          'Дар забони англисӣ ҷонишини I ҳамеша бо ҳарфи калон навишта '
          'мешавад.',
    },
    examples: {
      'en': ['I think I am late.'],
      'ru': ['I think I am late.'],
      'tg': ['I think I am late.'],
    },
    exercise: {
      'en': 'Rewrite with correct capitalisation: "i live in khujand."',
      'ru': 'Напишите правильно: «i live in khujand.»',
      'tg': 'Дуруст нависед: «i live in khujand.»',
    },
    apply: (s) {
      final fixed = s.replaceAll(RegExp(r"\bi\b"), 'I');
      if (fixed == s) return null;
      return _capitalizeFirst(fixed);
    },
  ),
];
