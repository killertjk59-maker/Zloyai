"""
Deterministic mock provider.

Used when no OpenRouter key is configured, in tests, and for local development.
It is NOT an AI: every answer comes from the rule table in
`app/services/offline_checker.py`. Responses are always labelled
`source="mock"` and `model="mock-rules-v1"` so the app can show that badge and
no user can mistake this for a language model.
"""

from __future__ import annotations

import random

from app.schemas.tutor import ChatRequest, CorrectRequest
from app.services.ai.base import AIProvider, ProviderResult
from app.services.offline_checker import check_sentence

MODEL_ID = "mock-rules-v1"

NEXT_STEP = {
    "tg": "Ҷумлаи нав бо ин қоида нависед.",
    "ru": "Напишите новое предложение с этим правилом.",
    "en": "Write a new sentence using this rule.",
}

OPENERS = {
    "normal": [
        "Thanks for sharing that — let's look at it together.",
        "Good effort. Here is what I would adjust.",
    ],
    "strict": [
        "Look at this carefully. The grammar is not optional.",
        "Not good enough yet. Fix this before you move on.",
    ],
    "roast": [
        "Oh, that sentence came in without a helmet.",
        "Your grammar just tripped over its own shoelaces.",
    ],
    "shout": [
        "STOP! READ THE SENTENCE AGAIN!",
        "NO! FIRST THE VERB, THEN THE REST!",
    ],
}

PROFANITY_TAIL = {
    "normal": "",
    "strict": "No shortcuts.",
    "roast": " Honestly, this mistake is a damn classic.",
    "shout": " THIS IS A MESS! FIX IT!",
}


def _opener(personality: str, profanity: bool, index_seed: str) -> str:
    pool = OPENERS.get(personality, OPENERS["strict"])
    opener = pool[sum(ord(c) for c in index_seed) % len(pool)]
    if profanity:
        opener = opener + PROFANITY_TAIL.get(personality, "")
    return opener


class MockProvider(AIProvider):
    name = "mock"

    def __init__(self, model_id: str = MODEL_ID):
        self._model = model_id

    @property
    def model(self) -> str:
        return self._model

    @property
    def is_mock(self) -> bool:
        return True

    async def correct(self, request: CorrectRequest) -> ProviderResult:
        correction = check_sentence(request.text, request.explanation_language)
        opener = _opener(request.personality, request.profanity, request.text)
        lang = request.explanation_language

        if correction is None:
            reply = self._no_match_reply(lang, opener, request.text)
            follow_up = {
                "tg": "Ҷумлаи дигар нависед, то санҷам.",
                "ru": "Напишите другое предложение, и я проверю.",
                "en": "Write another sentence and I will check it.",
            }.get(lang, "Write another sentence.")
        else:
            reply = f"{opener}\n\n{correction.explanation}"
            follow_up = correction.exercise or NEXT_STEP.get(lang, NEXT_STEP["en"])

        return ProviderResult(
            reply=reply,
            correction=correction,
            follow_up=follow_up,
            model=self._model,
            source="mock",
            latency_ms=1,
        )

    async def chat(self, request: ChatRequest) -> ProviderResult:
        lang = request.explanation_language
        correction = check_sentence(request.message, lang)
        opener = _opener(request.personality, request.profanity, request.message)

        if correction is not None:
            reply = f"{opener}\n\n{correction.explanation}"
            follow_up = correction.exercise or NEXT_STEP.get(lang, NEXT_STEP["en"])
        else:
            reply = self._fallback_chat(lang, opener)
            follow_up = {
                "tg": "Ҷумлае бо замони гузашта нависед.",
                "ru": "Напишите предложение в прошедшем времени.",
                "en": "Write a sentence in the past tense.",
            }.get(lang, "Write a sentence in the past tense.")

        return ProviderResult(
            reply=reply,
            correction=correction,
            follow_up=follow_up,
            model=self._model,
            source="mock",
            latency_ms=1,
        )

    # ------------------------------------------------------------------ text
    @staticmethod
    def _no_match_reply(lang: str, opener: str, text: str) -> str:
        templates = {
            "tg": (
                "{opener}\n\nДар ҳолати мазкур ман хатои қоидавии маълумро ёфта "
                "натавонистам. Ин маънои он нест, ки ҷумла комилан дуруст аст — "
                "танҳо қоидаҳои маҳаллии ман ин ҷумларо намепӯшонанд. "
                "Барои таҳлили пурра ба режими AI гузаред."
            ),
            "ru": (
                "{opener}\n\nВ этом предложении я не нашёл известной мне "
                "грамматической ошибки. Это не значит, что предложение идеально — "
                "просто мои локальные правила его не покрывают. Для полного "
                "разбора включите режим AI."
            ),
            "en": (
                "{opener}\n\nI did not find a grammar error that my rules know "
                "about. That does not mean the sentence is perfect — it only means "
                "my local rule set does not cover it. Switch to AI mode for a full "
                "analysis."
            ),
        }
        return templates.get(lang, templates["en"]).format(opener=opener)

    @staticmethod
    def _fallback_chat(lang: str, opener: str) -> str:
        sample = random.Random(0).choice(["I went to the market yesterday."])
        templates = {
            "tg": (
                "{opener}\n\nМан дар режими MOCK кор мекунам, бинобар ин суҳбати "
                "озод надорам. Метавонам ҷумлаҳоро аз рӯи қоидаҳои маҳаллӣ тафтиш "
                "кунам. Намуна: «{sample}»"
            ),
            "ru": (
                "{opener}\n\nЯ работаю в режиме MOCK, поэтому свободной беседы у "
                "меня нет. Я могу проверять предложения по локальным правилам. "
                "Пример: «{sample}»"
            ),
            "en": (
                "{opener}\n\nI am running in MOCK mode, so I cannot hold a free "
                "conversation. I can check sentences against local rules. "
                "Example: “{sample}”"
            ),
        }
        return templates.get(lang, templates["en"]).format(opener=opener, sample=sample)
