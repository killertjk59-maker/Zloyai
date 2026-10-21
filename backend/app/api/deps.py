"""Shared FastAPI dependencies."""

from __future__ import annotations

from fastapi import Request

from app.core.config import Settings, get_settings
from app.services.ai.base import AIProvider


def settings_dep(request: Request) -> Settings:
    """Settings bound to this app instance (overridable in tests)."""
    return getattr(request.app.state, "settings", None) or get_settings()


def provider_dep(request: Request) -> AIProvider:
    """Provider instance created once in the app lifespan."""
    return request.app.state.provider
