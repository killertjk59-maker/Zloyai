"""Tutor endpoints: sentence correction and free conversation."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends

from app.api.deps import provider_dep
from app.core.errors import MessageTooLong
from app.schemas.tutor import ChatRequest, CorrectRequest, TutorResponse
from app.services.ai.base import AIProvider
from app.core.config import Settings, get_settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/tutor", tags=["tutor"])


def _enforce_lengths(settings: Settings, text: str) -> None:
    if len(text) > settings.max_message_chars:
        raise MessageTooLong(
            f"Message is longer than the {settings.max_message_chars}-character limit."
        )


def _to_response(result) -> TutorResponse:
    return TutorResponse(
        reply=result.reply,
        source=result.source,  # type: ignore[arg-type]
        model=result.model,
        latency_ms=result.latency_ms,
        follow_up=result.follow_up,
        correction=result.correction,
    )


@router.post(
    "/correct",
    response_model=TutorResponse,
    summary="Correct a sentence and explain the mistake",
    responses={
        429: {"description": "rate_limited"},
        502: {"description": "provider_auth_error / bad_upstream_response"},
        503: {"description": "provider_not_configured / model_unavailable"},
        504: {"description": "provider_timeout"},
    },
)
async def correct(
    payload: CorrectRequest,
    provider: AIProvider = Depends(provider_dep),
    settings: Settings = Depends(get_settings),
) -> TutorResponse:
    _enforce_lengths(settings, payload.text)
    result = await provider.correct(payload)
    return _to_response(result)


@router.post(
    "/chat",
    response_model=TutorResponse,
    summary="Chat with the tutor",
    responses={
        429: {"description": "rate_limited"},
        502: {"description": "provider_auth_error / bad_upstream_response"},
        503: {"description": "provider_not_configured / model_unavailable"},
        504: {"description": "provider_timeout"},
    },
)
async def chat(
    payload: ChatRequest,
    provider: AIProvider = Depends(provider_dep),
    settings: Settings = Depends(get_settings),
) -> TutorResponse:
    _enforce_lengths(settings, payload.message)
    history = payload.history[-settings.max_history_messages :]
    if len(history) != len(payload.history):
        payload = payload.model_copy(update={"history": history})
    result = await provider.chat(payload)
    return _to_response(result)
