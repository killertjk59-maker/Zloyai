"""Health and provider-metadata endpoints (no secrets, no auth required)."""

from __future__ import annotations

import datetime as dt
import logging

import httpx
from fastapi import APIRouter, Depends

from app.api.deps import provider_dep, settings_dep
from app.core.config import Settings
from app.services.ai.base import AIProvider

logger = logging.getLogger(__name__)
router = APIRouter(tags=["system"])


@router.get("/health", summary="Liveness + engine status")
async def health(
    settings: Settings = Depends(settings_dep),
    provider: AIProvider = Depends(provider_dep),
) -> dict:
    """
    Never exposes the API key, only whether one is configured.

    `mock: true` tells the app it is talking to the deterministic rule engine, so
    the UI can show the MOCK badge instead of implying a language model answered.
    """
    return {
        "status": "ok",
        "provider": provider.name,
        "model": provider.model,
        "mock": provider.is_mock,
        "version": settings.app_version,
        "app_env": settings.app_env,
        "key_configured": settings.has_openrouter_key,
    }


@router.get(
    "/models/free",
    summary="List the models OpenRouter currently prices at zero",
)
async def free_models(settings: Settings = Depends(settings_dep)) -> dict:
    """
    Free model IDs rotate. This endpoint queries OpenRouter live so nobody has to
    trust a hard-coded list — and so the app can warn when its configured model
    has disappeared from the free tier.
    """
    url = f"{settings.openrouter_base_url}/models"
    headers = {"Content-Type": "application/json"}
    if settings.has_openrouter_key:
        headers["Authorization"] = (
            f"Bearer {settings.openrouter_api_key.get_secret_value()}"
        )

    async with httpx.AsyncClient(timeout=20.0) as client:
        response = await client.get(url, headers=headers)
        response.raise_for_status()
        payload = response.json()

    models = []
    for item in payload.get("data", []):
        pricing = item.get("pricing") or {}
        prompt = str(pricing.get("prompt", ""))
        completion = str(pricing.get("completion", ""))
        is_free = prompt in ("0", "0.0", "0.00") and completion in ("0", "0.0", "0.00")
        if not is_free:
            continue
        models.append(
            {
                "id": str(item.get("id", "")),
                "name": item.get("name"),
                "context_length": item.get("context_length"),
                "prompt_price": prompt,
                "completion_price": completion,
            }
        )

    models.sort(key=lambda model: model["id"])
    return {
        "source": "openrouter",
        "checked_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "count": len(models),
        "models": models,
        "note": (
            "Prices were read from OpenRouter at this moment. Free models can change "
            "or disappear; always re-check before relying on one."
        ),
    }
