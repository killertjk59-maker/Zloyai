import '../models/enums.dart';

/// A single expected word and whether it was heard.
class WordMatch {
  const WordMatch({required this.word, required this.matched});

  final String word;
  final bool matched;
}

/// Honest, limited pronunciation feedback.
///
/// This compares the platform speech recogniser's transcript with the expected
/// sentence using a word-level longest-common-subsequence match. It measures
/// **word recognition**, not phonemes, stress or intonation. It must therefore
/// never be presented as a pronunciation score.
class PronunciationAssessment {
  const PronunciationAssessment({
    required this.expected,
    required this.heard,
    required this.words,
    required this.extraWords,
  });

  final String expected;
  final String heard;
  final List<WordMatch> words;
  final List<String> extraWords;

  int get totalWords => words.length;
  int get matchedWords => words.where((w) => w.matched).length;

  /// 0.0 – 1.0 word match rate (not an accuracy score).
  double get matchRate => totalWords == 0 ? 0 : matchedWords / totalWords;

  List<String> get missedWords =>
      words.where((w) => !w.matched).map((w) => w.word).toList();

  /// Short, honest interpretation for the given explanation language.
  String summary(ExplanationLanguage language) {
    final percent = (matchRate * 100).round();
    final missed = missedWords.take(4).join(', ');
    if (language == ExplanationLanguage.tajik) {
      if (matchRate >= 0.9) {
        return 'Шинохти нутқ $percent% калимаҳоро шинохт. Ин ченаки '
            'шинохти калима аст, на баҳои талаффуз.';
      }
      if (matchRate >= 0.6) {
        return 'Шинохти нутқ $percent% калимаҳоро шинохт. Калимаҳои '
            'шинохтанашуда: $missed. Оҳистатар ва равшантар гӯед.';
      }
      return 'Шинохти нутқ танҳо $percent% калимаҳоро шинохт. Ин метавонад аз '
          'талаффуз, садои паст ё микрофон бошад. Калимаҳо: $missed';
    }
    if (language == ExplanationLanguage.russian) {
      if (matchRate >= 0.9) {
        return 'Распознавание речи узнало $percent% слов. Это показатель '
            'распознавания слов, а не оценка произношения.';
      }
      if (matchRate >= 0.6) {
        return 'Распознавание речи узнало $percent% слов. Не распознаны: '
            '$missed. Говорите медленнее и чётче.';
      }
      return 'Распознано только $percent% слов. Причина может быть в '
          'произношении, тихом голосе или микрофоне. Слова: $missed';
    }
    if (matchRate >= 0.9) {
      return 'Speech recognition understood $percent% of the words. This is a '
          'word-recognition rate, not a pronunciation score.';
    }
    if (matchRate >= 0.6) {
      return 'Speech recognition understood $percent% of the words. Not '
          'recognised: $missed. Try slowing down.';
    }
    return 'Only $percent% of the words were recognised. That can be '
        'pronunciation, a quiet voice, or the microphone. Words: $missed';
  }
}

class PronunciationService {
  const PronunciationService();

  static const _contractions = {
    "don't": ['do', 'not'],
    "doesn't": ['does', 'not'],
    "didn't": ['did', 'not'],
    "can't": ['can', 'not'],
    "won't": ['will', 'not'],
    "isn't": ['is', 'not'],
    "aren't": ['are', 'not'],
    "i'm": ['i', 'am'],
    "it's": ['it', 'is'],
    "i've": ['i', 'have'],
    "we're": ['we', 'are'],
    "you're": ['you', 'are'],
    "they're": ['they', 'are'],
  };

  List<String> tokenize(String text) {
    final lower = text.toLowerCase();
    final raw = lower
        .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    final out = <String>[];
    for (final token in raw) {
      final expanded = _contractions[token];
      if (expanded != null) {
        out.addAll(expanded);
      } else {
        out.add(token.replaceAll("'", ''));
      }
    }
    return out;
  }

  PronunciationAssessment assess({
    required String expected,
    required String heard,
  }) {
    final expectedWords = tokenize(expected);
    final heardWords = tokenize(heard);

    // Longest common subsequence over words.
    final n = expectedWords.length;
    final m = heardWords.length;
    final table = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        table[i][j] = expectedWords[i] == heardWords[j]
            ? table[i + 1][j + 1] + 1
            : (table[i + 1][j] >= table[i][j + 1]
                  ? table[i + 1][j]
                  : table[i][j + 1]);
      }
    }

    final matchedFlags = List<bool>.filled(n, false);
    var i = 0;
    var j = 0;
    while (i < n && j < m) {
      if (expectedWords[i] == heardWords[j]) {
        matchedFlags[i] = true;
        i++;
        j++;
      } else if (table[i + 1][j] >= table[i][j + 1]) {
        i++;
      } else {
        j++;
      }
    }

    final matchedHeard = <String>{};
    for (var k = 0; k < n; k++) {
      if (matchedFlags[k]) matchedHeard.add(expectedWords[k]);
    }
    final extra = heardWords
        .where((w) => !matchedHeard.contains(w))
        .toSet()
        .toList(growable: false);

    return PronunciationAssessment(
      expected: expected,
      heard: heard,
      words: [
        for (var k = 0; k < n; k++)
          WordMatch(word: expectedWords[k], matched: matchedFlags[k]),
      ],
      extraWords: extra,
    );
  }
}
