"""
Deterministic grammar checker used by the mock provider and by tests.

This is deliberately a small, explainable rule set — not a language model. The
Flutter app ships a larger version of the same idea for offline use (see
`app/lib/data/offline_rules.dart`); both follow the same semantics so that a
sentence corrected offline is corrected the same way here.

Adding a rule means adding one `Rule` entry with text for every supported
explanation language.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Callable

from app.schemas.tutor import Correction

IRREGULAR_PAST = {
    "go": "went",
    "eat": "ate",
    "see": "saw",
    "buy": "bought",
    "come": "came",
    "take": "took",
    "have": "had",
    "do": "did",
    "make": "made",
    "say": "said",
    "get": "got",
    "know": "knew",
    "write": "wrote",
    "speak": "spoke",
    "drink": "drank",
    "give": "gave",
    "find": "found",
    "think": "thought",
}

THIRD_PERSON = {
    "have": "has",
    "do": "does",
    "go": "goes",
    "watch": "watches",
    "teach": "teaches",
    "study": "studies",
    "try": "tries",
    "say": "says",
}


@dataclass
class Rule:
    id: str
    name: dict[str, str]
    explanation: dict[str, str]
    apply: Callable[[str], str | None]
    examples: dict[str, list[str]] = field(default_factory=dict)
    exercise: dict[str, str] = field(default_factory=dict)
    alternatives: dict[str, list[str]] | None = None
    low_confidence: bool = False


def _third_person_form(verb: str) -> str:
    lower = verb.lower()
    if lower in THIRD_PERSON:
        return THIRD_PERSON[lower]
    if lower.endswith("y") and len(lower) > 1 and lower[-2] not in "aeiou":
        return verb[:-1] + "ies"
    if lower.endswith(("s", "sh", "ch", "x", "o")):
        return verb + "es"
    return verb + "s"


def _replace_first(
    pattern: str, sentence: str, replacement: Callable[[re.Match], str]
) -> str | None:
    match = re.search(pattern, sentence, flags=re.IGNORECASE)
    if not match:
        return None
    return sentence[: match.start()] + replacement(match) + sentence[match.end() :]


# --------------------------------------------------------------------------- rules


def _would_to(sentence: str) -> str | None:
    return _replace_first(
        r"\bwould\s+to\s+([a-z]+)\b",
        sentence,
        lambda m: f"would {m.group(1)}",
    )


VERBS = (
    "go|like|want|need|know|think|say|do|have|play|work|live|study|eat|make|"
    "take|come|see|look|feel|try|watch|read|write|speak|learn|help|love|walk"
)

# Singular nouns that take -s on the verb. Kept as an explicit list: guessing a
# subject's number from English nouns in general is not reliable enough.
SINGULAR_SUBJECTS = (
    "brother|sister|mother|father|friend|teacher|student|boss|neighbour|neighbor|"
    "colleague|wife|husband|son|daughter|child|man|woman|doctor|driver"
)


def _third_person_s(sentence: str) -> str | None:
    return _replace_first(
        rf"\b(he|she|it)\s+({VERBS})\b",
        sentence,
        lambda m: f"{m.group(1)} {_third_person_form(m.group(2))}",
    )


def _third_person_noun_s(sentence: str) -> str | None:
    return _replace_first(
        rf"\b((?:my|his|her|your|our|their|the)\s+)?({SINGULAR_SUBJECTS})\s+({VERBS})\b",
        sentence,
        lambda m: (f"{m.group(1) or ''}{m.group(2)} {_third_person_form(m.group(3))}"),
    )


def _age_be(sentence: str) -> str | None:
    def fix(m: re.Match) -> str:
        subject = m.group(1)
        verb = {"i": "am", "he": "is", "she": "is"}.get(subject.lower(), "are")
        return f"{subject} {verb} {m.group(3)} years old"

    return _replace_first(
        r"\b(I|you|we|they|he|she)\s+(have|has)\s+(\d+)\s+years?\s+old\b",
        sentence,
        fix,
    )


def _am_agree(sentence: str) -> str | None:
    return _replace_first(
        r"\b(I)\s+am\s+agree\b", sentence, lambda m: f"{m.group(1)} agree"
    )


def _uncountable(sentence: str) -> str | None:
    fixes = {
        "informations": "information",
        "advices": "advice",
        "furnitures": "furniture",
        "equipments": "equipment",
        "peoples": "people",
        "researches": "research",
        "knowledges": "knowledge",
    }
    result = sentence
    for wrong, right in fixes.items():
        result = re.sub(rf"\b{wrong}\b", right, result, flags=re.IGNORECASE)
    return result if result != sentence else None


def _aux_past(sentence: str) -> str | None:
    def fix(m: re.Match) -> str:
        aux, verb = m.group(1), m.group(2).lower()
        base = next((b for b, past in IRREGULAR_PAST.items() if past == verb), None)
        if base is None and verb.endswith("ed") and len(verb) > 3:
            base = verb[:-2]
        return f"{aux} {base}" if base else m.group(0)

    return _replace_first(
        r"\b(did not|didn't|does not|doesn't|do not|don't)\s+([a-z]+)\b",
        sentence,
        fix,
    )


def _double_comparative(sentence: str) -> str | None:
    return _replace_first(
        r"\bmore\s+(better|worse|easier|harder|faster|slower|bigger|smaller|happier)\b",
        sentence,
        lambda m: m.group(1),
    )


def _since_for(sentence: str) -> str | None:
    return _replace_first(
        r"\bsince\s+(\d+|two|three|four|five|six|ten|a few)\s+(years?|months?|days?|weeks?|hours?)\b",
        sentence,
        lambda m: f"for {m.group(1)} {m.group(2)}",
    )


def _question_order(sentence: str) -> str | None:
    return _replace_first(
        r"\b(how|where|what|when|why|which)\s+(I|we|you|they|he|she)\s+(can|should|must|will|would)\b",
        sentence,
        lambda m: f"{m.group(1)} {m.group(3)} {m.group(2)}",
    )


def _article_profession(sentence: str) -> str | None:
    def fix(m: re.Match) -> str:
        noun = m.group(2)
        article = "an" if noun[0].lower() in "aeiou" else "a"
        return f"{m.group(1)} {article} {noun}"

    return _replace_first(
        r"\b(am|is|are)\s+(student|teacher|doctor|engineer|driver|nurse|programmer|designer|lawyer|waiter)\b",
        sentence,
        fix,
    )


def _third_person_negative(sentence: str) -> str | None:
    return _replace_first(
        r"\b(he|she|it)\s+(don't|do not)\b",
        sentence,
        lambda m: f"{m.group(1)} doesn't",
    )


def _past_marker(sentence: str) -> str | None:
    if not re.search(
        r"\b(yesterday|last night|last week|last month|last year|ago)\b",
        sentence,
        flags=re.IGNORECASE,
    ):
        return None
    for match in re.finditer(r"[A-Za-z']+", sentence):
        past = IRREGULAR_PAST.get(match.group(0).lower())
        if past:
            return sentence[: match.start()] + past + sentence[match.end() :]
    return None


def _capital_i(sentence: str) -> str | None:
    result = re.sub(r"\bi\b", "I", sentence)
    if result == sentence:
        return None
    return result[0].upper() + result[1:] if result else result


RULES: list[Rule] = [
    Rule(
        id="would_to",
        low_confidence=True,
        name={
            "en": "Modal verbs + bare infinitive",
            "ru": "Модальные глаголы + инфинитив без to",
            "tg": "Феълҳои модалӣ + масдар бе to",
        },
        explanation={
            "en": 'After the modal "would" the verb comes without "to": "would go". '
            'If you meant a finished action in the past, use the past simple: "went".',
            "ru": 'После модального "would" глагол употребляется без "to": "would go". '
            'Если речь о завершённом действии в прошлом, нужен Past Simple: "went".',
            "tg": 'Баъди феъли модалии "would" феъл бе "to" меояд: "would go". '
            'Агар амали гузаштаи анҷомёфтаро дар назар дошта бошӣ, Past Simple лозим аст: "went".',
        },
        examples={
            "en": [
                "I would go to London if I had money.",
                "I went to school yesterday.",
            ],
            "ru": [
                "I would go to London if I had money.",
                "I went to school yesterday.",
            ],
            "tg": [
                "I would go to London if I had money.",
                "I went to school yesterday.",
            ],
        },
        exercise={
            "en": 'Fill in: "If I had time, I ___ (go) to the gym."',
            "ru": "Вставьте: «If I had time, I ___ (go) to the gym.»",
            "tg": "Пур кунед: «If I had time, I ___ (go) to the gym.»",
        },
        alternatives={
            "en": ['If you meant a finished past action: "I went to school."'],
            "ru": ["Если речь о завершённом действии: «I went to school.»"],
            "tg": ["Агар амали гузаштаро дар назар дошта бошӣ: «I went to school.»"],
        },
        apply=_would_to,
    ),
    Rule(
        id="third_person_s",
        name={
            "en": "Present simple: -s for he / she / it",
            "ru": "Present Simple: -s для he / she / it",
            "tg": "Ҳозираи оддӣ: -s барои he / she / it",
        },
        explanation={
            "en": 'In the present simple, he / she / it takes a verb ending in -s: "he goes".',
            "ru": 'В Present Simple с he / she / it глагол получает -s: "he goes".',
            "tg": 'Дар ҳозираи оддӣ бо he / she / it феъл бандаки -s мегирад: "he goes".',
        },
        examples={
            "en": ["She works in a hospital.", "He has two brothers."],
            "ru": ["She works in a hospital.", "He has two brothers."],
            "tg": ["She works in a hospital.", "He has two brothers."],
        },
        exercise={
            "en": 'Correct: "My brother play football every Sunday."',
            "ru": "Исправьте: «My brother play football every Sunday.»",
            "tg": "Ислоҳ кунед: «My brother play football every Sunday.»",
        },
        apply=_third_person_s,
    ),
    Rule(
        id="third_person_noun_s",
        name={
            "en": "Present simple: -s with a singular subject",
            "ru": "Present Simple: -s при подлежащем в единственном числе",
            "tg": "Ҳозираи оддӣ: -s бо мубтадои танҳо",
        },
        explanation={
            "en": "A singular subject (my brother, the teacher) takes a verb ending "
            'in -s: "my brother plays".',
            "ru": "Подлежащее в единственном числе (my brother, the teacher) требует "
            'глагол с -s: "my brother plays".',
            "tg": "Мубтадои танҳо (my brother, the teacher) феълро бо -s мегирад: "
            '"my brother plays".',
        },
        examples={
            "en": ["My brother works in a bank."],
            "ru": ["My brother works in a bank."],
            "tg": ["My brother works in a bank."],
        },
        exercise={
            "en": 'Correct: "My sister live in Dushanbe."',
            "ru": "Исправьте: «My sister live in Dushanbe.»",
            "tg": "Ислоҳ кунед: «My sister live in Dushanbe.»",
        },
        apply=_third_person_noun_s,
    ),
    Rule(
        id="age_be",
        name={
            "en": "Age uses the verb to be",
            "ru": "Возраст: глагол to be",
            "tg": "Синну сол бо феъли to be",
        },
        explanation={
            "en": 'English expresses age with "to be": "I am 20 years old".',
            "ru": 'Возраст передаётся через to be: "I am 20 years old".',
            "tg": 'Синну сол бо to be ифода мешавад: "I am 20 years old".',
        },
        examples={
            "en": ["My sister is 12 years old."],
            "ru": ["My sister is 12 years old."],
            "tg": ["My sister is 12 years old."],
        },
        exercise={
            "en": 'Say your age using "to be".',
            "ru": "Скажите свой возраст через to be.",
            "tg": "Синну соли худро бо to be гӯед.",
        },
        apply=_age_be,
    ),
    Rule(
        id="am_agree",
        name={
            "en": '"agree" is a verb',
            "ru": '"agree" — глагол',
            "tg": '"agree" феъл аст',
        },
        explanation={
            "en": 'Do not put "to be" before a main verb: "I agree".',
            "ru": 'Не ставьте to be перед смысловым глаголом: "I agree".',
            "tg": 'Пеш аз феъли асосӣ to be намегузоранд: "I agree".',
        },
        examples={
            "en": ["I agree with you."],
            "ru": ["I agree with you."],
            "tg": ["I agree with you."],
        },
        apply=_am_agree,
    ),
    Rule(
        id="uncountable",
        name={
            "en": "Uncountable nouns",
            "ru": "Неисчисляемые существительные",
            "tg": "Исмҳои ношумурданӣ",
        },
        explanation={
            "en": "Information, advice, furniture and equipment have no plural.",
            "ru": "Information, advice, furniture, equipment не имеют множественного числа.",
            "tg": "Information, advice, furniture, equipment шакли ҷамъ надоранд.",
        },
        examples={
            "en": ["I need more information."],
            "ru": ["I need more information."],
            "tg": ["I need more information."],
        },
        apply=_uncountable,
    ),
    Rule(
        id="aux_past",
        name={
            "en": "do/does/did + base verb",
            "ru": "do/does/did + инфинитив",
            "tg": "do/does/did + масдар",
        },
        explanation={
            "en": 'After do/does/did the main verb stays in the base form: "I didn\'t go".',
            "ru": 'После do/does/did глагол стоит в базовой форме: "I didn\'t go".',
            "tg": 'Баъди do/does/did феъл дар шакли аслӣ мемонад: "I didn\'t go".',
        },
        examples={
            "en": ["I didn't see him."],
            "ru": ["I didn't see him."],
            "tg": ["I didn't see him."],
        },
        apply=_aux_past,
    ),
    Rule(
        id="double_comparative",
        name={
            "en": "Comparatives",
            "ru": "Сравнительная степень",
            "tg": "Дараҷаи муқоисавӣ",
        },
        explanation={
            "en": 'Short adjectives take -er, so "more" is not needed: "better".',
            "ru": 'Короткие прилагательные образуют сравнение с -er: "better".',
            "tg": 'Сифатҳои кӯтоҳ бо -er сохта мешаванд: "better".',
        },
        examples={
            "en": ["This exercise is easier."],
            "ru": ["This exercise is easier."],
            "tg": ["This exercise is easier."],
        },
        apply=_double_comparative,
    ),
    Rule(
        id="since_for",
        name={"en": "for vs since", "ru": "for vs since", "tg": "for ва since"},
        explanation={
            "en": 'Use "for" with a duration and "since" with a start point.',
            "ru": "For — с длительностью, since — с точкой отсчёта.",
            "tg": "For бо давомнокӣ, since бо нуқтаи оғоз истифода мешавад.",
        },
        examples={
            "en": ["I have lived here for three years."],
            "ru": ["I have lived here for three years."],
            "tg": ["I have lived here for three years."],
        },
        apply=_since_for,
    ),
    Rule(
        id="question_order",
        name={
            "en": "Question word order",
            "ru": "Порядок слов в вопросе",
            "tg": "Тартиби калимаҳо дар савол",
        },
        explanation={
            "en": 'The auxiliary comes before the subject: "How can I help you?"',
            "ru": 'Вспомогательный глагол перед подлежащим: "How can I help you?"',
            "tg": 'Феъли ёридиҳанда пеш аз мубтадо меояд: "How can I help you?"',
        },
        examples={
            "en": ["Where can I buy a ticket?"],
            "ru": ["Where can I buy a ticket?"],
            "tg": ["Where can I buy a ticket?"],
        },
        apply=_question_order,
    ),
    Rule(
        id="article_profession",
        name={
            "en": "a / an before a profession",
            "ru": "a / an перед профессией",
            "tg": "a / an пеш аз касб",
        },
        explanation={
            "en": 'Singular countable nouns need an article: "I am a student".',
            "ru": 'Исчисляемое существительное требует артикль: "I am a student".',
            "tg": 'Исми шумурданӣ артикл талаб мекунад: "I am a student".',
        },
        examples={
            "en": ["She is a doctor."],
            "ru": ["She is a doctor."],
            "tg": ["She is a doctor."],
        },
        apply=_article_profession,
    ),
    Rule(
        id="third_person_negative",
        name={
            "en": "he / she / it + doesn't",
            "ru": "he / she / it + doesn't",
            "tg": "he / she / it + doesn't",
        },
        explanation={
            "en": 'For he / she / it the negative auxiliary is "doesn\'t".',
            "ru": "Для he / she / it отрицание образуется через doesn't.",
            "tg": 'Барои he / she / it шакли инкорӣ "doesn\'t" аст.',
        },
        examples={
            "en": ["She doesn't drink coffee."],
            "ru": ["She doesn't drink coffee."],
            "tg": ["She doesn't drink coffee."],
        },
        apply=_third_person_negative,
    ),
    Rule(
        id="past_marker",
        name={
            "en": "Past time marker",
            "ru": "Маркер прошлого",
            "tg": "Нишонаи гузашта",
        },
        explanation={
            "en": 'With "yesterday" or "…ago" the verb must be in the past simple.',
            "ru": "С yesterday и …ago глагол стоит в Past Simple.",
            "tg": "Бо yesterday ва …ago феъл дар Past Simple меояд.",
        },
        examples={
            "en": ["Yesterday I went to the market."],
            "ru": ["Yesterday I went to the market."],
            "tg": ["Yesterday I went to the market."],
        },
        apply=_past_marker,
    ),
    Rule(
        id="capital_i",
        name={
            "en": 'The pronoun "I" is capitalised',
            "ru": "Местоимение I с заглавной",
            "tg": 'Ҷонишини "I" бо ҳарфи калон',
        },
        explanation={
            "en": 'The pronoun "I" is always written with a capital letter.',
            "ru": "Местоимение I всегда пишется с заглавной буквы.",
            "tg": "Ҷонишини I ҳамеша бо ҳарфи калон навишта мешавад.",
        },
        examples={
            "en": ["I think I am late."],
            "ru": ["I think I am late."],
            "tg": ["I think I am late."],
        },
        apply=_capital_i,
    ),
]


def check_sentence(text: str, explanation_language: str = "tg") -> Correction | None:
    """Return a structured correction, or None when no rule matches."""
    original = text.strip()
    if not original:
        return None

    current = original
    applied: list[Rule] = []
    for rule in RULES:
        result = rule.apply(current)
        if result and result != current:
            current = result
            applied.append(rule)

    if not applied:
        return None

    lang = explanation_language if explanation_language in ("en", "ru", "tg") else "en"

    def pick(mapping: dict[str, str]) -> str:
        return mapping.get(lang) or mapping.get("en") or ""

    explanations = [pick(rule.explanation) for rule in applied[:3]]
    rule_names = " • ".join(dict.fromkeys(pick(rule.name) for rule in applied))
    examples: list[str] = []
    for rule in applied:
        for example in (rule.examples.get(lang) or rule.examples.get("en") or [])[:2]:
            if example not in examples:
                examples.append(example)
        if len(examples) >= 3:
            break
    alternatives: list[str] = []
    for rule in applied:
        mapping = rule.alternatives or {}
        alternatives.extend(mapping.get(lang) or mapping.get("en") or [])

    return Correction(
        original=original,
        corrected=current,
        explanation="\n\n".join(explanations),
        rule=rule_names,
        examples=examples[:3],
        exercise=pick(applied[0].exercise) or None,
        alternatives=alternatives,
        confidence="low" if any(rule.low_confidence for rule in applied) else "high",
    )
