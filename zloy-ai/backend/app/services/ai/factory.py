"""Provider selection.

`AI_PROVIDER=auto` (the default) lets the server run with zero configuration:
no key means the deterministic mock provider, whose answers are labelled
`source="mock"`. Nothing degrades silently — the label is always visible.
"""

from __future__ import annotations

import logging

from app.core.config import Settings
from app.services.ai.base import AIProvider
from app.services.ai.mock import MockProvider
from app.services.ai.openrouter import OpenRouterProvider

logger = logging.getLogger(__name__)


def build_provider(settings: Settings) -> AIProvider:
    choice = settings.ai_provider

    if choice == "mock":
        logger.info("AI provider: mock (explicitly selected)")
        return MockProvider()

    if choice == "openrouter":
        if not settings.has_openrouter_key:
            # Do not fail at import time; fail per request with a clear 503.
            logger.warning(
                "AI provider: openrouter selected but OPENROUTER_API_KEY is missing"
            )
        return OpenRouterProvider(settings)

    if settings.has_openrouter_key:
        logger.info("AI provider: openrouter (model configured)")
        return OpenRouterProvider(settings)

    logger.info("AI provider: mock (no OPENROUTER_API_KEY configured)")
    return MockProvider()
