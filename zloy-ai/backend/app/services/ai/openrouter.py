"""OpenRouter provider (OpenAI-compatible chat completions)."""

from __future__ import annotations

import logging
import time

import httpx

from app.core.config import Settings
from app.core.errors import (
    ProviderAuthError,
    ProviderBadResponse,
    ProviderModelUnavailable,
    ProviderNotConfigured,
    ProviderRateLimited,
    ProviderTimeout,
)
from app.schemas.tutor import ChatRequest, CorrectRequest
from app.services.ai.base import AIProvider, ProviderResult, parse_model_payload
from app.services.prompts import build_chat_messages, build_correct_messages

logger = logging.getLogger(__name__)


class OpenRouterProvider(AIProvider):
    name = "openrouter"

    def __init__(self, settings: Settings, client: httpx.AsyncClient | None = None):
        self._settings = settings
        self._client = client
        self._owns_client = client is None

    # ---------------------------------------------------------------- helpers
    @property
    def model(self) -> str:
        return self._settings.openrouter_model

    @property
    def is_mock(self) -> bool:
        return False

    def _headers(self) -> dict[str, str]:
        if not self._settings.has_openrouter_key:
            raise ProviderNotConfigured()
        headers = {
            "Authorization": f"Bearer {self._settings.openrouter_api_key.get_secret_value()}",
            "Content-Type": "application/json",
            "X-Title": self._settings.openrouter_app_title,
        }
        if self._settings.openrouter_site_url:
            headers["HTTP-Referer"] = self._settings.openrouter_site_url
        return headers

    def _http(self) -> httpx.AsyncClient:
        if self._client is None:
            self._client = httpx.AsyncClient(
                timeout=httpx.Timeout(self._settings.openrouter_timeout_seconds)
            )
        return self._client

    async def aclose(self) -> None:
        if self._owns_client and self._client is not None:
            await self._client.aclose()
            self._client = None

    async def _complete(self, messages: list[dict[str, str]]) -> tuple[str, str]:
        body = {
            "model": self.model,
            "messages": messages,
            "temperature": self._settings.openrouter_temperature,
            "max_tokens": self._settings.openrouter_max_tokens,
            "response_format": {"type": "json_object"},
        }
        try:
            response = await self._http().post(
                f"{self._settings.openrouter_base_url}/chat/completions",
                headers=self._headers(),
                json=body,
            )
        except httpx.TimeoutException as exc:
            logger.warning("openrouter timeout: %s", type(exc).__name__)
            raise ProviderTimeout() from exc
        except httpx.HTTPError as exc:
            logger.warning("openrouter transport error: %s", type(exc).__name__)
            raise ProviderBadResponse("Could not reach the AI provider.") from exc

        self._raise_for_status(response)

        try:
            payload = response.json()
            choice = payload["choices"][0]
            content = choice["message"]["content"]
        except (ValueError, KeyError, IndexError, TypeError) as exc:
            logger.warning("openrouter malformed payload: %s", type(exc).__name__)
            raise ProviderBadResponse() from exc

        if not isinstance(content, str) or not content.strip():
            raise ProviderBadResponse("The AI provider returned an empty answer.")

        # OpenRouter echoes the model actually used (may differ for routers).
        used_model = payload.get("model") or self.model
        return content, str(used_model)

    @staticmethod
    def _raise_for_status(response: httpx.Response) -> None:
        status_code = response.status_code
        if status_code < 400:
            return
        if status_code == 401 or status_code == 403:
            raise ProviderAuthError()
        if status_code == 429:
            retry_after = response.headers.get("Retry-After")
            raise ProviderRateLimited(
                retry_after=int(retry_after) if (retry_after or "").isdigit() else 20
            )
        if status_code in (400, 404, 503):
            # 400/404 usually means the model slug is gone or was never free.
            raise ProviderModelUnavailable()
        if status_code >= 500:
            raise ProviderModelUnavailable()
        raise ProviderBadResponse(f"Unexpected provider status {status_code}.")

    # --------------------------------------------------------------- endpoints
    async def correct(self, request: CorrectRequest) -> ProviderResult:
        started = time.perf_counter()
        content, used_model = await self._complete(build_correct_messages(request))
        reply, correction, follow_up = parse_model_payload(
            content, original=request.text
        )
        if correction is None:
            # Refusing to invent a correction is correct behaviour, but the app
            # needs *something* honest, so we say so explicitly.
            reply = (
                reply
                if reply.strip()
                else "I could not analyse this sentence. Try rephrasing it."
            )
        return ProviderResult(
            reply=reply,
            correction=correction,
            follow_up=follow_up,
            model=used_model,
            source="ai",
            latency_ms=int((time.perf_counter() - started) * 1000),
        )

    async def chat(self, request: ChatRequest) -> ProviderResult:
        started = time.perf_counter()
        content, used_model = await self._complete(build_chat_messages(request))
        reply, correction, follow_up = parse_model_payload(
            content, original=request.message
        )
        return ProviderResult(
            reply=reply,
            correction=correction,
            follow_up=follow_up,
            model=used_model,
            source="ai",
            latency_ms=int((time.perf_counter() - started) * 1000),
        )
