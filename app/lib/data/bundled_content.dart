import '../models/chat_models.dart';
import '../models/enums.dart';

/// A vocabulary entry with both explanation languages.
class VocabEntry {
  const VocabEntry({
    required this.word,
    required this.tg,
    required this.ru,
    required this.example,
    required this.enDefinition,
  });

  final String word;
  final String tg;
  final String ru;
  final String example;
  final String enDefinition;
}

/// A bilingual translation drill: the prompt is in the explanation language
/// and the answer is English, so it can be checked automatically.
class TranslationEntry {
  const TranslationEntry({
    required this.tg,
    required this.ru,
    required this.en,
    this.accepted = const [],
  });

  final String tg;
  final String ru;
  final String en;
  final List<String> accepted;
}

/// All offline learning material. Everything here ships inside the APK and
/// works with no network at all.
class BundledContent {
  BundledContent._();

  // ---------------------------------------------------------------- vocabulary

  static const List<(String, String, List<VocabEntry>)> _vocabSets = [
    (
      'everyday-basics',
      'Everyday basics',
      [
        VocabEntry(
          word: 'breakfast',
          tg: 'нахӯристӣ',
          ru: 'завтрак',
          example: 'I eat breakfast at seven.',
          enDefinition: 'the first meal of the day',
        ),
        VocabEntry(
          word: 'journey',
          tg: 'сафар',
          ru: 'поездка',
          example: 'The journey to Dushanbe takes six hours.',
          enDefinition: 'a trip from one place to another',
        ),
        VocabEntry(
          word: 'tired',
          tg: 'хаста',
          ru: 'усталый',
          example: 'I am tired after work.',
          enDefinition: 'needing rest or sleep',
        ),
        VocabEntry(
          word: 'borrow',
          tg: 'қарз гирифтан',
          ru: 'брать взаймы',
          example: 'Can I borrow your pen?',
          enDefinition: 'to take something and return it later',
        ),
        VocabEntry(
          word: 'neighbour',
          tg: 'ҳамсоя',
          ru: 'сосед',
          example: 'Our neighbour has a big dog.',
          enDefinition: 'a person who lives next to you',
        ),
        VocabEntry(
          word: 'cheap',
          tg: 'арзон',
          ru: 'дешёвый',
          example: 'This bread is cheap.',
          enDefinition: 'costing little money',
        ),
        VocabEntry(
          word: 'weather',
          tg: 'обу ҳаво',
          ru: 'погода',
          example: 'The weather is cold today.',
          enDefinition: 'the state of the air outside',
        ),
        VocabEntry(
          word: 'arrive',
          tg: 'расидан',
          ru: 'прибывать',
          example: 'We arrive at nine o’clock.',
          enDefinition: 'to reach a place',
        ),
        VocabEntry(
          word: 'choose',
          tg: 'интихоб кардан',
          ru: 'выбирать',
          example: 'Choose one answer.',
          enDefinition: 'to pick one thing from several',
        ),
        VocabEntry(
          word: 'quiet',
          tg: 'ором',
          ru: 'тихий',
          example: 'Please be quiet in the library.',
          enDefinition: 'making little or no noise',
        ),
      ],
    ),
    (
      'daily-life',
      'Daily life',
      [
        VocabEntry(
          word: 'appointment',
          tg: 'вохӯрии муқарраршуда',
          ru: 'приём, встреча',
          example: 'I have a dentist appointment at four.',
          enDefinition: 'an arranged meeting at a fixed time',
        ),
        VocabEntry(
          word: 'complain',
          tg: 'шикоят кардан',
          ru: 'жаловаться',
          example: 'He complained about the noise.',
          enDefinition: 'to say that something is wrong',
        ),
        VocabEntry(
          word: 'afford',
          tg: 'қудрат доштан (аз ҷиҳати молиявӣ)',
          ru: 'позволить себе',
          example: 'We cannot afford a new car.',
          enDefinition: 'to have enough money for something',
        ),
        VocabEntry(
          word: 'advice',
          tg: 'маслиҳат',
          ru: 'совет',
          example: 'She gave me useful advice.',
          enDefinition: 'an opinion about what someone should do',
        ),
        VocabEntry(
          word: 'improve',
          tg: 'беҳтар кардан',
          ru: 'улучшать',
          example: 'My English is improving.',
          enDefinition: 'to become better',
        ),
        VocabEntry(
          word: 'traffic',
          tg: 'ҳаракати нақлиёт',
          ru: 'дорожное движение',
          example: 'The traffic is terrible today.',
          enDefinition: 'the movement of vehicles on the road',
        ),
        VocabEntry(
          word: 'hurry',
          tg: 'шитоб кардан',
          ru: 'спешить',
          example: 'Hurry up, the bus is coming!',
          enDefinition: 'to move or do something quickly',
        ),
        VocabEntry(
          word: 'luggage',
          tg: 'бор',
          ru: 'багаж',
          example: 'My luggage is too heavy.',
          enDefinition: 'bags you take when travelling',
        ),
        VocabEntry(
          word: 'recipe',
          tg: 'дастури пухтупаз',
          ru: 'рецепт',
          example: 'This recipe is from my mother.',
          enDefinition: 'instructions for cooking a dish',
        ),
        VocabEntry(
          word: 'realize',
          tg: 'дарк кардан',
          ru: 'осознавать',
          example: 'I realized my mistake.',
          enDefinition: 'to understand something suddenly',
        ),
      ],
    ),
    (
      'work-study',
      'Work & study',
      [
        VocabEntry(
          word: 'deadline',
          tg: 'муҳлати ниҳоӣ',
          ru: 'крайний срок',
          example: 'The deadline is Friday.',
          enDefinition: 'the last day or time to finish something',
        ),
        VocabEntry(
          word: 'research',
          tg: 'таҳқиқот',
          ru: 'исследование',
          example: 'She does research on language learning.',
          enDefinition: 'careful study of a subject',
        ),
        VocabEntry(
          word: 'achieve',
          tg: 'ноил шудан',
          ru: 'достигать',
          example: 'You can achieve your goal with practice.',
          enDefinition: 'to succeed in reaching a goal',
        ),
        VocabEntry(
          word: 'require',
          tg: 'талаб кардан',
          ru: 'требовать',
          example: 'The job requires good English.',
          enDefinition: 'to need something officially',
        ),
        VocabEntry(
          word: 'reliable',
          tg: 'боэътимод',
          ru: 'надёжный',
          example: 'He is a reliable colleague.',
          enDefinition: 'able to be trusted',
        ),
        VocabEntry(
          word: 'opportunity',
          tg: 'имконият',
          ru: 'возможность',
          example: 'This is a great opportunity.',
          enDefinition: 'a chance to do something good',
        ),
        VocabEntry(
          word: 'apply',
          tg: 'ариза додан',
          ru: 'подавать заявку',
          example: 'I applied for a new job.',
          enDefinition: 'to formally ask for a job or place',
        ),
        VocabEntry(
          word: 'colleague',
          tg: 'ҳамкор',
          ru: 'коллега',
          example: 'My colleague speaks three languages.',
          enDefinition: 'a person you work with',
        ),
        VocabEntry(
          word: 'salary',
          tg: 'маош',
          ru: 'зарплата',
          example: 'The salary is paid monthly.',
          enDefinition: 'money paid for work',
        ),
        VocabEntry(
          word: 'schedule',
          tg: 'ҷадвали корӣ',
          ru: 'расписание',
          example: 'My schedule is full this week.',
          enDefinition: 'a plan of times and activities',
        ),
      ],
    ),
  ];

  static List<Lesson> vocabularyLessons(ExplanationLanguage lang) {
    return [
      for (var setIndex = 0; setIndex < _vocabSets.length; setIndex++)
        _buildVocabLesson(_vocabSets[setIndex], setIndex, lang),
    ];
  }

  static Lesson _buildVocabLesson(
    (String, String, List<VocabEntry>) set,
    int setIndex,
    ExplanationLanguage lang,
  ) {
    final entries = set.$3;
    final lessons = <PracticeItem>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final correct = lang == ExplanationLanguage.tajik ? entry.tg : entry.ru;
      final distractors = <String>[];
      for (var offset = 1; offset <= 3; offset++) {
        final other = entries[(i + offset * 3) % entries.length];
        final candidate = lang == ExplanationLanguage.tajik
            ? other.tg
            : other.ru;
        if (candidate != correct && !distractors.contains(candidate)) {
          distractors.add(candidate);
        }
      }
      final choices = <String>[correct, ...distractors.take(3)];
      // Deterministic rotation so the answer is not always first.
      final rotate = i % choices.length;
      final rotated = [
        ...choices.sublist(rotate),
        ...choices.sublist(0, rotate),
      ];
      lessons.add(
        PracticeItem(
          id: '${set.$1}-$i',
          prompt: entry.word,
          answer: correct,
          choiceAnswers: rotated,
          hint: entry.enDefinition,
          explanation: _vocabExplanation(entry, lang),
        ),
      );
    }
    return Lesson(
      id: set.$1,
      title: set.$2,
      subtitle:
          '${entries.length} words · ${lang == ExplanationLanguage.tajik ? 'тарҷума' : 'перевод'}',
      kind: LessonKind.vocabulary,
      level: setIndex == 0
          ? ProficiencyLevel.beginner
          : setIndex == 1
          ? ProficiencyLevel.elementary
          : ProficiencyLevel.intermediate,
      items: lessons,
      emoji: setIndex == 0 ? '🧺' : (setIndex == 1 ? '☕' : '💼'),
    );
  }

  static String _vocabExplanation(VocabEntry entry, ExplanationLanguage lang) {
    switch (lang) {
      case ExplanationLanguage.tajik:
        return '«${entry.word}» = ${entry.tg}. Маъно: ${entry.enDefinition}. '
            'Мисол: ${entry.example}';
      case ExplanationLanguage.russian:
        return '«${entry.word}» = ${entry.ru}. Значение: '
            '${entry.enDefinition}. Пример: ${entry.example}';
      case ExplanationLanguage.english:
        return '${entry.word} = ${entry.enDefinition}. Example: ${entry.example}';
    }
  }

  // ------------------------------------------------------------------ grammar

  static List<Lesson> grammarLessons(ExplanationLanguage lang) => [
    _presentSimpleLesson(lang),
    _pastSimpleLesson(lang),
    _articlesLesson(lang),
    _prepositionsLesson(lang),
    _comparativesLesson(lang),
  ];

  static Lesson _presentSimpleLesson(ExplanationLanguage lang) {
    const items = [
      (
        'She ___ (work) in a hospital.',
        'works',
        ['work', 'working'],
        'Third person singular takes -s.',
        'Шахси сеюми танҳо бандаки -s мегирад: she works.',
        'Третье лицо единственного числа получает -s: she works.',
      ),
      (
        'They ___ (not / like) coffee.',
        "don't like",
        ['doesn\'t like', 'not like'],
        'Plural subject uses do not / don’t.',
        'Бо they шакли инкорӣ "don\'t" меояд: they don\'t like.',
        'С they используется don\'t: they don\'t like.',
      ),
      (
        '___ he speak English?',
        'Does',
        ['Do', 'Is'],
        'Questions with he/she/it use "does".',
        'Дар савол бо he/she/it феъли ёридиҳандаи "does" меояд.',
        'В вопросе с he/she/it используется does.',
      ),
      (
        'I ___ (study) every evening.',
        'study',
        ['studies', 'studying'],
        'With "I" the verb stays in the base form.',
        'Бо "I" феъл дар шакли аслӣ мемонад: I study.',
        'С "I" глагол остаётся в базовой форме: I study.',
      ),
      (
        'My brother ___ (go) to school by bus.',
        'goes',
        ['go', 'going'],
        'go + -es for he/she/it.',
        'Бо he/she/it феъли go → goes мешавад.',
        'С he/she/it: go → goes.',
      ),
      (
        'We ___ (not / have) a car.',
        "don't have",
        ['doesn\'t have', 'not have'],
        'do not / don’t with we.',
        'Бо "we" шакли инкорӣ "don\'t" аст.',
        'С "we" отрицание образуется через don\'t.',
      ),
    ];

    return Lesson(
      id: 'grammar-present-simple',
      title: 'Present Simple',
      subtitle: '6 exercises · routines and facts',
      kind: LessonKind.grammar,
      level: ProficiencyLevel.beginner,
      emoji: '⏱️',
      items: [
        for (var i = 0; i < items.length; i++)
          PracticeItem(
            id: 'ps-$i',
            prompt: items[i].$1,
            answer: items[i].$2,
            acceptedAnswers: items[i].$3,
            hint: items[i].$4,
            explanation: _pick(
              lang,
              items[i].$5,
              items[i].$6,
              'Present simple describes habits and facts.',
            ),
          ),
      ],
    );
  }

  static Lesson _pastSimpleLesson(ExplanationLanguage lang) {
    const items = [
      (
        'Yesterday I ___ (go) to the market.',
        'went',
        ['go', 'goed'],
        'go is irregular: go → went.',
        'Феъли go ғайриқонунӣ аст: go → went.',
        'Глагол go неправильный: go → went.',
      ),
      (
        'She ___ (buy) a new phone last week.',
        'bought',
        ['buyed', 'buys'],
        'buy → bought.',
        'buy → bought.',
        'buy → bought.',
      ),
      (
        'We ___ (not / see) him at the party.',
        "didn't see",
        ['didn\'t saw', 'not saw'],
        'After didn’t use the base verb.',
        'Баъди "didn\'t" феъл дар шакли аслӣ меояд: didn\'t see.',
        'После didn\'t глагол стоит в базовой форме: didn\'t see.',
      ),
      (
        '___ you finish your homework?',
        'Did',
        ['Do', 'Was'],
        'Past question with did.',
        'Савол дар замони гузашта бо "did" сохта мешавад.',
        'Вопрос в прошедшем времени строится с did.',
      ),
      (
        'He ___ (eat) breakfast at 7 yesterday.',
        'ate',
        ['eated', 'eats'],
        'eat → ate.',
        'eat → ate.',
        'eat → ate.',
      ),
      (
        'They ___ (come) home late.',
        'came',
        ['comed', 'come'],
        'come → came.',
        'come → came.',
        'come → came.',
      ),
    ];
    return Lesson(
      id: 'grammar-past-simple',
      title: 'Past Simple',
      subtitle: '6 exercises · finished actions',
      kind: LessonKind.grammar,
      level: ProficiencyLevel.elementary,
      emoji: '🕰️',
      items: [
        for (var i = 0; i < items.length; i++)
          PracticeItem(
            id: 'past-$i',
            prompt: items[i].$1,
            answer: items[i].$2,
            acceptedAnswers: items[i].$3,
            hint: items[i].$4,
            explanation: _pick(
              lang,
              items[i].$5,
              items[i].$6,
              'Past simple describes finished actions.',
            ),
          ),
      ],
    );
  }

  static Lesson _articlesLesson(ExplanationLanguage lang) {
    const items = [
      (
        'I am ___ student.',
        'a',
        ['an', 'the'],
        'a before a consonant sound.',
        'Пеш аз садоноги ҳамсадо артикли "a" меояд: a student.',
        'Перед согласным звуком ставится "a": a student.',
      ),
      (
        'She is ___ engineer.',
        'an',
        ['a', 'the'],
        'an before a vowel sound.',
        'Пеш аз садоноги садонокӣ артикли "an" меояд: an engineer.',
        'Перед гласным звуком ставится "an": an engineer.',
      ),
      (
        '___ sun rises in the east.',
        'The',
        ['A', '—'],
        'Unique things take "the".',
        'Ашёи ягона бо "the" истифода мешавад: the sun.',
        'Единственные в своём роде объекты — с "the": the sun.',
      ),
      (
        'I like ___ music.',
        '—',
        ['a', 'the'],
        'No article with general uncountable nouns.',
        'Бо исмҳои ношумурданӣ дар маънои умумӣ артикл намеояд.',
        'С неисчисляемыми в общем значении артикль не нужен.',
      ),
      (
        'He is ___ best student in the class.',
        'the',
        ['a', 'an'],
        'Superlatives take "the".',
        'Дараҷаи олӣ бо "the" меояд: the best.',
        'Превосходная степень — с "the": the best.',
      ),
    ];
    return Lesson(
      id: 'grammar-articles',
      title: 'Articles a / an / the',
      subtitle: '5 exercises · the small words that matter',
      kind: LessonKind.grammar,
      level: ProficiencyLevel.beginner,
      emoji: '🔤',
      items: [
        for (var i = 0; i < items.length; i++)
          PracticeItem(
            id: 'art-$i',
            prompt: items[i].$1,
            answer: items[i].$2,
            acceptedAnswers: [...items[i].$3, '0'],
            hint: items[i].$4,
            explanation: _pick(
              lang,
              items[i].$5,
              items[i].$6,
              'Articles depend on whether the noun is countable and specific.',
            ),
          ),
      ],
    );
  }

  static Lesson _prepositionsLesson(ExplanationLanguage lang) {
    const items = [
      (
        'The meeting is ___ Monday.',
        'on',
        ['in', 'at'],
        'Days take "on".',
        'Рӯзҳо бо "on" меоянд: on Monday.',
        'Дни недели — с "on": on Monday.',
      ),
      (
        'I was born ___ 1998.',
        'in',
        ['on', 'at'],
        'Years take "in".',
        'Солҳо бо "in" меоянд: in 1998.',
        'Годы — с "in": in 1998.',
      ),
      (
        'The class starts ___ 8 o’clock.',
        'at',
        ['in', 'on'],
        'Clock times take "at".',
        'Вақти соат бо "at" меояд: at 8 o\'clock.',
        'Время по часам — с "at": at 8 o\'clock.',
      ),
      (
        'I have lived here ___ three years.',
        'for',
        ['since', 'during'],
        'for + duration.',
        'Давомнокӣ бо "for" ифода мешавад: for three years.',
        'Длительность — с "for": for three years.',
      ),
      (
        'She has worked here ___ 2019.',
        'since',
        ['for', 'from'],
        'since + starting point.',
        'Нуқтаи оғоз бо "since" меояд: since 2019.',
        'Точка отсчёта — с "since": since 2019.',
      ),
    ];
    return Lesson(
      id: 'grammar-prepositions',
      title: 'Prepositions of time',
      subtitle: '5 exercises · in / on / at / for / since',
      kind: LessonKind.grammar,
      level: ProficiencyLevel.elementary,
      emoji: '📍',
      items: [
        for (var i = 0; i < items.length; i++)
          PracticeItem(
            id: 'prep-$i',
            prompt: items[i].$1,
            answer: items[i].$2,
            acceptedAnswers: items[i].$3,
            hint: items[i].$4,
            explanation: _pick(
              lang,
              items[i].$5,
              items[i].$6,
              'Choose the preposition by the kind of time expression.',
            ),
          ),
      ],
    );
  }

  static Lesson _comparativesLesson(ExplanationLanguage lang) {
    const items = [
      (
        'This book is ___ (interesting) than that one.',
        'more interesting',
        ['interestinger', 'most interesting'],
        'Long adjectives use "more".',
        'Сифатҳои дароз бо "more" дараҷаи муқоисавӣ месозанд.',
        'Длинные прилагательные образуют сравнение с more.',
      ),
      (
        'My car is ___ (fast) than yours.',
        'faster',
        ['more fast', 'fastest'],
        'Short adjectives take -er.',
        'Сифатҳои кӯтоҳ бандаки -er мегиранд: faster.',
        'Короткие прилагательные получают -er: faster.',
      ),
      (
        'She is the ___ (good) student in the group.',
        'best',
        ['goodest', 'better'],
        'good → better → best.',
        'good → better → best.',
        'good → better → best.',
      ),
      (
        'Today is ___ (bad) than yesterday.',
        'worse',
        ['badder', 'worst'],
        'bad → worse → worst.',
        'bad → worse → worst.',
        'bad → worse → worst.',
      ),
      (
        'This exercise is ___ (easy) than the last one.',
        'easier',
        ['more easy', 'easiest'],
        'y → ier.',
        'Дар охир "y" ба "ier" табдил меёбад: easier.',
        'y → ier: easier.',
      ),
    ];
    return Lesson(
      id: 'grammar-comparatives',
      title: 'Comparatives',
      subtitle: '5 exercises · compare things correctly',
      kind: LessonKind.grammar,
      level: ProficiencyLevel.elementary,
      emoji: '⚖️',
      items: [
        for (var i = 0; i < items.length; i++)
          PracticeItem(
            id: 'cmp-$i',
            prompt: items[i].$1,
            answer: items[i].$2,
            acceptedAnswers: items[i].$3,
            hint: items[i].$4,
            explanation: _pick(
              lang,
              items[i].$5,
              items[i].$6,
              'Comparatives compare two things; superlatives compare three or more.',
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------------- reading

  static List<ReadingPassage> readingPassages(ExplanationLanguage lang) => [
    ReadingPassage(
      id: 'reading-market',
      title: 'A morning at the market',
      level: ProficiencyLevel.beginner,
      text:
          'Every Saturday Farid goes to the Panjshanbe market in Khujand. '
          'He buys bread, apples and milk. The market is busy and noisy. '
          'Farid always greets the sellers. He says that the market is the '
          'best place to practise small talk in Russian.',
      questions: [
        PracticeItem(
          id: 'r1-q1',
          prompt: 'Where does Farid go on Saturday?',
          answer: 'the market',
          acceptedAnswers: ['market', 'panjshanbe market', 'bazaar'],
          choiceAnswers: ['the market', 'the cinema', 'the airport'],
          explanation: _pick(
            lang,
            'Дар матн гуфта шудааст: "Farid goes to the Panjshanbe market".',
            'В тексте сказано: "Farid goes to the Panjshanbe market".',
            'The text says: "Farid goes to the Panjshanbe market".',
          ),
        ),
        PracticeItem(
          id: 'r1-q2',
          prompt: 'What does he buy?',
          answer: 'bread, apples and milk',
          acceptedAnswers: ['bread apples and milk', 'bread and milk'],
          explanation: _pick(
            lang,
            'Матн: "He buys bread, apples and milk".',
            'Текст: "He buys bread, apples and milk".',
            'Text: "He buys bread, apples and milk".',
          ),
        ),
        PracticeItem(
          id: 'r1-q3',
          prompt: 'Why does he like the market?',
          answer: 'to practise small talk',
          acceptedAnswers: ['practise russian', 'practice small talk'],
          explanation: _pick(
            lang,
            'Матн: "the best place to practise small talk in Russian".',
            'Текст: "the best place to practise small talk in Russian".',
            'Text: "the best place to practise small talk in Russian".',
          ),
        ),
      ],
    ),
    ReadingPassage(
      id: 'reading-routine',
      title: 'The 15-minute rule',
      level: ProficiencyLevel.elementary,
      text:
          'Learning a language for two hours once a week is worse than '
          'studying for fifteen minutes every day. Short daily sessions '
          'keep words fresh in your memory. Start with five new words, '
          'write one sentence with each, and review yesterday’s words '
          'before adding more.',
      questions: [
        PracticeItem(
          id: 'r2-q1',
          prompt: 'Which is better according to the text?',
          answer: 'fifteen minutes every day',
          acceptedAnswers: ['15 minutes every day', 'daily short sessions'],
          choiceAnswers: [
            'fifteen minutes every day',
            'two hours once a week',
            'only on weekends',
          ],
          explanation: _pick(
            lang,
            'Матн: "fifteen minutes every day" беҳтар аст.',
            'Текст: лучше "fifteen minutes every day".',
            'Text: fifteen minutes every day is better.',
          ),
        ),
        PracticeItem(
          id: 'r2-q2',
          prompt: 'What should you do before adding new words?',
          answer: 'review yesterday’s words',
          acceptedAnswers: ['review yesterdays words', 'review'],
          explanation: _pick(
            lang,
            'Матн: аввал калимаҳои дирӯзаро такрор кун: '
                '"review yesterday’s words before adding more".',
            'Текст: сначала повтори вчерашние слова, потом добавляй новые.',
            'Text: review yesterday’s words before adding more.',
          ),
        ),
      ],
    ),
  ];

  // ----------------------------------------------------------- translations

  static List<Lesson> translationLessons(ExplanationLanguage lang) {
    const entries = <TranslationEntry>[
      TranslationEntry(
        tg: 'Ман ҳар рӯз ба кор меравам.',
        ru: 'Я каждый день хожу на работу.',
        en: 'I go to work every day.',
        accepted: ['I go to work every day', 'Every day I go to work'],
      ),
      TranslationEntry(
        tg: 'Вай дирӯз китоб харид.',
        ru: 'Она вчера купила книгу.',
        en: 'She bought a book yesterday.',
      ),
      TranslationEntry(
        tg: 'Мо англисӣ меомӯзем.',
        ru: 'Мы учим английский.',
        en: 'We are learning English.',
        accepted: ['We learn English', 'We study English'],
      ),
      TranslationEntry(
        tg: 'Оё ту дӯстон дорӣ?',
        ru: 'У тебя есть друзья?',
        en: 'Do you have friends?',
        accepted: ['Have you got friends'],
      ),
      TranslationEntry(
        tg: 'Ин китоб аз он китоб шавқовартар аст.',
        ru: 'Эта книга интереснее той.',
        en: 'This book is more interesting than that one.',
      ),
      TranslationEntry(
        tg: 'Ман ба шумо кӯмак карда метавонам.',
        ru: 'Я могу вам помочь.',
        en: 'I can help you.',
        accepted: ['I could help you'],
      ),
      TranslationEntry(
        tg: 'Ӯ се сол боз дар ин ҷо кор мекунад.',
        ru: 'Он работает здесь три года.',
        en: 'He has worked here for three years.',
        accepted: ['He has been working here for three years'],
      ),
      TranslationEntry(
        tg: 'Ман фардо ба Душанбе меравам.',
        ru: 'Завтра я еду в Душанбе.',
        en: 'I am going to Dushanbe tomorrow.',
        accepted: ['I will go to Dushanbe tomorrow'],
      ),
    ];

    return [
      Lesson(
        id: 'translation-core',
        title: 'Translation drill',
        subtitle:
            '8 sentences · ${lang == ExplanationLanguage.tajik ? 'тоҷикӣ → англисӣ' : 'русский → английский'}',
        kind: LessonKind.translation,
        level: ProficiencyLevel.elementary,
        emoji: '🔁',
        items: [
          for (var i = 0; i < entries.length; i++)
            PracticeItem(
              id: 'tr-$i',
              prompt: lang == ExplanationLanguage.tajik
                  ? entries[i].tg
                  : entries[i].ru,
              answer: entries[i].en,
              acceptedAnswers: entries[i].accepted,
              hint: _pick(
                lang,
                'Ба англисӣ нависед.',
                'Напишите по-английски.',
                'Write it in English.',
              ),
              explanation: _pick(
                lang,
                'Ҷавоби дуруст: ${entries[i].en}',
                'Правильный ответ: ${entries[i].en}',
                'Correct answer: ${entries[i].en}',
              ),
            ),
        ],
      ),
    ];
  }

  // ------------------------------------------------------- daily challenge

  /// Builds today's challenge deterministically from the date so every device
  /// gets a stable set of tasks for that day, with no server involved.
  static Lesson dailyChallenge({
    required DateTime day,
    required ExplanationLanguage lang,
    required ProficiencyLevel level,
  }) {
    final vocab = vocabularyLessons(lang);
    final grammar = grammarLessons(lang);
    final pool = <PracticeItem>[
      ...vocab.expand((l) => l.items),
      ...grammar.expand((l) => l.items),
    ];
    final seed = day.year * 10000 + day.month * 100 + day.day;
    final picked = <PracticeItem>[];
    final used = <int>{};
    var cursor = seed % pool.length;
    var attempts = 0;
    // Bounded pseudo-random walk: a simple LCG can fall into a short cycle, so
    // the loop is capped and falls back to a sequential fill.
    while (picked.length < 8 && attempts < pool.length * 4) {
      attempts++;
      if (used.add(cursor)) picked.add(pool[cursor]);
      cursor = (cursor * 31 + 17) % pool.length;
    }
    if (picked.length < 8) {
      for (var i = 0; i < pool.length && picked.length < 8; i++) {
        final index = (seed + i * 7) % pool.length;
        if (used.add(index)) picked.add(pool[index]);
      }
    }
    // Adapt difficulty: beginners get the first four (easier) items only.
    final adjusted = level == ProficiencyLevel.beginner
        ? picked.take(5).toList()
        : picked;
    return Lesson(
      id: 'daily-${day.year}-${day.month}-${day.day}',
      title: 'Daily challenge',
      subtitle:
          '${adjusted.length} mixed tasks · ${day.day}.${day.month}.${day.year}',
      kind: LessonKind.challenge,
      level: level,
      emoji: '🔥',
      items: adjusted,
    );
  }

  /// Localised line shown on the home dashboard.
  static String dailyChallengeHeadline(ExplanationLanguage lang, int count) {
    switch (lang) {
      case ExplanationLanguage.tajik:
        return 'Имрӯз $count вазифа — бе баҳона!';
      case ExplanationLanguage.russian:
        return 'Сегодня $count заданий — без отговорок!';
      case ExplanationLanguage.english:
        return 'Today: $count tasks — no excuses!';
    }
  }

  static String _pick(
    ExplanationLanguage lang,
    String tg,
    String ru,
    String en,
  ) => switch (lang) {
    ExplanationLanguage.tajik => tg,
    ExplanationLanguage.russian => ru,
    ExplanationLanguage.english => en,
  };
}
