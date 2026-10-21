"""Provider abstraction: one interface, several implementations."""

from __future__ import annotations

import json
import re
from abc import ABC, abstractmethod
from dataclasses import dataclass, field

from app.schemas.tutor import ChatRequest, CorrectRequest, Correction, Confidence


@dataclass
class ProviderResult:
    """What every provider returns, before it becomes an HTTP response."""

    reply: str
    correction: Correction | None = None
    follow_up: str | None = None
    model: str | None = None
    source: str = "ai"
    latency_ms: int | None = None
    raw: dict | None = field(default=None, repr=False)


class AIProvider(ABC):
    """Interface implemented by the OpenRouter and mock providers."""

    name: str = "base"

    @property
    @abstractmethod
    def model(self) -> str: ...

    @property
    @abstractmethod
    def is_mock(self) -> bool: ...

    @abstractmethod
    async def correct(self, request: CorrectRequest) -> ProviderResult: ...

    @abstractmethod
    async def chat(self, request: ChatRequest) -> ProviderResult: ...

    async def aclose(self) -> None:
        """Release any network resources. No-op by default."""
        return None


# ------------------------------------------------------------------ JSON handling

_FENCE = re.compile(r"^```(?:json)?\s*|\s*```$", flags=re.MULTILINE)


def strip_code_fences(text: str) -> str:
    return _FENCE.sub("", text.strip()).strip()


def extract_json_object(text: str) -> dict | None:
    """Pull the first balanced JSON object out of a model answer."""
    cleaned = strip_code_fences(text)
    try:
        loaded = json.loads(cleaned)
        return loaded if isinstance(loaded, dict) else None
    except json.JSONDecodeError:
        pass

    start = cleaned.find("{")
    while start != -1:
        depth = 0
        in_string = False
        escaped = False
        for index in range(start, len(cleaned)):
            char = cleaned[index]
            if in_string:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    in_string = False
                continue
            if char == '"':
                in_string = True
            elif char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    candidate = cleaned[start : index + 1]
                    try:
                        loaded = json.loads(candidate)
                    except json.JSONDecodeError:
                        break
                    return loaded if isinstance(loaded, dict) else None
        start = cleaned.find("{", start + 1)
    return None


def _as_str_list(value, limit: int = 4) -> list[str]:
    if not isinstance(value, list):
        return []
    out: list[str] = []
    for item in value:
        if isinstance(item, str):
            cleaned = item.strip()
        elif isinstance(item, (int, float)):
            cleaned = str(item)
        else:
            continue
        if cleaned and cleaned not in out:
            out.append(cleaned[:400])
        if len(out) >= limit:
            break
    return out


def _optional_str(value, limit: int = 1200) -> str | None:
    if isinstance(value, str):
        cleaned = value.strip()
        return cleaned[:limit] if cleaned else None
    return None


def _confidence(value) -> Confidence:
    if isinstance(value, str):
        lowered = value.strip().lower()
        if lowered in ("high", "medium", "low"):
            return lowered  # type: ignore[return-value]
    return "medium"


def parse_correction(payload, original: str) -> Correction | None:
    """Coerce an untrusted `correction` object into the app's contract."""
    if not isinstance(payload, dict):
        return None

    corrected = _optional_str(payload.get("corrected"), limit=800) or original
    explanation = _optional_str(payload.get("explanation"), limit=2000)
    if not explanation:
        # A correction without an explanation teaches nothing — drop it.
        return None

    return Correction(
        original=_optional_str(payload.get("original"), limit=800) or original,
        corrected=corrected,
        explanation=explanation,
        rule=_optional_str(payload.get("rule"), limit=200),
        examples=_as_str_list(payload.get("examples")),
        exercise=_optional_str(payload.get("exercise"), limit=600),
        alternatives=_as_str_list(payload.get("alternatives")),
        confidence=_confidence(payload.get("confidence")),
    )


def parse_model_payload(
    content: str, *, original: str
) -> tuple[str, Correction | None, str | None]:
    """Convert the model's JSON (or plain text) into our three fields."""
    payload = extract_json_object(content)
    if payload is None:
        # Plain-text answer: keep it, but never fabricate a correction.
        plain = strip_code_fences(content)
        return (plain or "…"), None, None

    reply = _optional_str(payload.get("reply"), limit=4000)
    correction = parse_correction(payload.get("correction"), original)
    follow_up = _optional_str(payload.get("follow_up"), limit=300)

    if not reply:
        if correction is not None:
            reply = correction.explanation
        else:
            reply = strip_code_fences(content)[:2000] or "…"

    return reply, correction, follow_up
