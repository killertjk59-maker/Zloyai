"""
Application configuration.

Every secret is read from the environment (or a local `.env` file that is
git-ignored). Nothing here is ever sent to the Flutter client, and no value of
`OPENROUTER_API_KEY` is printed, logged or returned by the API.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration for the ZLOY.AI backend."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    # --- Application -----------------------------------------------------
    app_env: Literal["development", "staging", "production", "test"] = "development"
    app_name: str = "ZLOY.AI API"
    app_version: str = "1.0.0"
    log_level: str = "INFO"

    # --- AI provider -----------------------------------------------------
    # auto   -> OpenRouter when a key is configured, otherwise the mock provider
    # openrouter -> always OpenRouter (fails clearly if the key is missing)
    # mock   -> deterministic local provider, no network, clearly labelled
    ai_provider: Literal["auto", "openrouter", "mock"] = "auto"

    openrouter_api_key: SecretStr = Field(default_factory=lambda: SecretStr(""))
    openrouter_base_url: str = "https://openrouter.ai/api/v1"
    # Verified against GET /api/v1/models at build time; free model IDs rotate,
    # so this is configurable and never assumed to stay free.
    openrouter_model: str = "google/gemma-4-31b-it:free"
    openrouter_timeout_seconds: float = 30.0
    openrouter_max_tokens: int = 900
    openrouter_temperature: float = 0.6
    # Optional attribution headers required by OpenRouter's leaderboard.
    openrouter_site_url: str = ""
    openrouter_app_title: str = "ZLOY.AI"

    # --- HTTP ------------------------------------------------------------
    request_timeout_seconds: float = 40.0
    cors_origins: str = ""
    max_message_chars: int = 600
    max_history_messages: int = 10

    # --- Rate limiting ---------------------------------------------------
    rate_limit_requests: int = 30
    rate_limit_window_seconds: int = 60

    # --- Database --------------------------------------------------------
    # sqlite:///./zloy.db  |  sqlite:////absolute/path.db  |  plain path
    database_url: str = "sqlite:///./zloy.db"

    @field_validator("openrouter_base_url")
    @classmethod
    def _strip_trailing_slash(cls, value: str) -> str:
        return value.rstrip("/")

    @field_validator("openrouter_timeout_seconds", "request_timeout_seconds")
    @classmethod
    def _sane_timeouts(cls, value: float) -> float:
        if value <= 0:
            raise ValueError("timeouts must be positive")
        return min(value, 180.0)

    @property
    def has_openrouter_key(self) -> bool:
        return bool(self.openrouter_api_key.get_secret_value().strip())

    @property
    def cors_origin_list(self) -> list[str]:
        return [
            origin.strip() for origin in self.cors_origins.split(",") if origin.strip()
        ]

    @property
    def database_path(self) -> str:
        """Extract a filesystem path from a `sqlite://` URL."""
        url = self.database_url
        if url.startswith("sqlite:///"):
            return url[len("sqlite:///") :]
        if url.startswith("sqlite://"):
            return url[len("sqlite://") :]
        return url

    def describe(self) -> dict[str, object]:
        """Safe, secret-free description used by the health endpoint."""
        return {
            "app_env": self.app_env,
            "openrouter_model": self.openrouter_model,
            "openrouter_key_configured": self.has_openrouter_key,
        }

    def __repr__(self) -> str:  # pragma: no cover - defensive
        return (
            f"Settings(app_env={self.app_env!r}, ai_provider={self.ai_provider!r}, "
            f"model={self.openrouter_model!r}, key_configured={self.has_openrouter_key})"
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
