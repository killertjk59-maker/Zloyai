"""Request/response models shared by the tutor endpoints."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator

TargetLanguage = Literal["en", "ru", "tg"]
ExplanationLanguage = Literal["tg", "ru", "en"]
ProficiencyLevel = Literal[
    "beginner", "elementary", "intermediate", "upper_intermediate", "advanced"
]
PersonalityMode = Literal["normal", "strict", "roast", "shout"]
LearningStyle = Literal["examples", "rules", "dialogue", "drills"]
Confidence = Literal["high", "medium", "low"]
Source = Literal["ai", "mock", "offline"]


class HistoryMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=2000)


class LearnerContext(BaseModel):
    """The minimum context needed to teach well — no personal data."""

    target_language: TargetLanguage = "en"
    explanation_language: ExplanationLanguage = "tg"
    level: ProficiencyLevel = "beginner"
    personality: PersonalityMode = "strict"
    profanity: bool = False
    learning_style: LearningStyle = "examples"
    goals: list[str] = Field(default_factory=list, max_length=8)

    @field_validator("goals")
    @classmethod
    def _clean_goals(cls, goals: list[str]) -> list[str]:
        cleaned = []
        for goal in goals:
            safe = goal.strip()[:40]
            if safe and safe not in cleaned:
                cleaned.append(safe)
        return cleaned[:8]


class CorrectRequest(LearnerContext):
    text: str = Field(min_length=1, max_length=600)
    history: list[HistoryMessage] = Field(default_factory=list, max_length=10)

    @field_validator("text")
    @classmethod
    def _non_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("text must not be blank")
        return value.strip()


class ChatRequest(LearnerContext):
    message: str = Field(min_length=1, max_length=600)
    history: list[HistoryMessage] = Field(default_factory=list, max_length=10)

    @field_validator("message")
    @classmethod
    def _non_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("message must not be blank")
        return value.strip()


class Correction(BaseModel):
    original: str
    corrected: str
    explanation: str
    rule: str | None = None
    examples: list[str] = Field(default_factory=list)
    exercise: str | None = None
    alternatives: list[str] = Field(default_factory=list)
    confidence: Confidence = "high"


class TutorResponse(BaseModel):
    reply: str
    source: Source
    model: str | None = None
    latency_ms: int | None = None
    follow_up: str | None = None
    correction: Correction | None = None


class HealthResponse(BaseModel):
    status: Literal["ok"]
    provider: str
    model: str
    mock: bool
    version: str
    app_env: str


class ModelInfo(BaseModel):
    id: str
    name: str | None = None
    context_length: int | None = None
    prompt_price: str | None = None
    completion_price: str | None = None


class FreeModelList(BaseModel):
    """Free model discovery so no model is assumed free forever."""

    source: Literal["openrouter"] = "openrouter"
    checked_at: str
    count: int
    models: list[ModelInfo]
    note: str
