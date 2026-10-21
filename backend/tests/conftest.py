"""Shared fixtures. Every test runs with no real network access and no real key."""

from __future__ import annotations

import json
from collections.abc import Callable, Iterator

import httpx
import pytest
from fastapi.testclient import TestClient

from app.api.deps import provider_dep
from app.core.config import Settings, get_settings
from app.main import create_app


@pytest.fixture(autouse=True)
def _clean_env(monkeypatch):
    """Make sure no developer `.env` or shell export leaks into the tests."""
    for name in (
        "OPENROUTER_API_KEY",
        "AI_PROVIDER",
        "OPENROUTER_MODEL",
        "CORS_ORIGINS",
        "APP_ENV",
    ):
        monkeypatch.delenv(name, raising=False)
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.fixture(autouse=True)
def _no_real_network(monkeypatch):
    """Fail loudly if a test accidentally makes a real HTTP connection."""

    async def guard(self, request):  # pragma: no cover - only fires on misuse
        raise AssertionError(f"test attempted real network access: {request.url}")

    monkeypatch.setattr(httpx.AsyncHTTPTransport, "handle_async_request", guard)
    yield


def make_settings(**overrides) -> Settings:
    """Settings built from scratch, ignoring any local `.env` file."""
    base: dict = {"app_env": "test", "ai_provider": "mock", "_env_file": None}
    base.update(overrides)
    return Settings(**base)


@pytest.fixture
def settings() -> Settings:
    return make_settings()


@pytest.fixture
def client() -> Iterator[TestClient]:
    """App wired with the default (keyless) configuration -> mock provider."""
    with TestClient(create_app()) as test_client:
        yield test_client


class ScriptedOpenRouter:
    """A TestClient whose provider talks to a scripted, offline OpenRouter."""

    def __init__(self, client: TestClient, calls: list[dict]):
        self.client = client
        self.calls = calls

    def __getattr__(self, item):
        return getattr(self.client, item)

    @property
    def last_request(self) -> dict:
        return self.calls[-1]


@pytest.fixture
def openrouter() -> Callable[..., ScriptedOpenRouter]:
    """
    Build a client backed by a scripted OpenRouter.

        api = openrouter([ok_response(correction_payload())])
        api.post("/api/v1/tutor/correct", json={...})
        assert api.last_request["body"]["model"] == "test/model:free"
    """

    contexts: list[TestClient] = []

    def factory(
        handlers: list[Callable[[httpx.Request], httpx.Response]],
        *,
        model: str = "test/model:free",
    ) -> ScriptedOpenRouter:
        from app.services.ai.openrouter import OpenRouterProvider

        calls: list[dict] = []

        def handler(request: httpx.Request) -> httpx.Response:
            body = json.loads(request.content.decode()) if request.content else {}
            calls.append(
                {
                    "url": str(request.url),
                    "headers": dict(request.headers),
                    "body": body,
                }
            )
            index = min(len(calls) - 1, len(handlers) - 1)
            return handlers[index](request)

        provider = OpenRouterProvider(
            make_settings(
                ai_provider="openrouter",
                openrouter_api_key="test-key-not-real",
                openrouter_model=model,
            ),
            client=httpx.AsyncClient(transport=httpx.MockTransport(handler)),
        )

        app = create_app()
        app.dependency_overrides[provider_dep] = lambda: provider
        client = TestClient(app)
        client.__enter__()
        contexts.append(client)
        return ScriptedOpenRouter(client, calls)

    yield factory
    for client in contexts:
        client.__exit__(None, None, None)


def ok_response(content: str, *, model: str = "test/model:free") -> httpx.Response:
    return httpx.Response(
        200,
        json={
            "id": "gen-test",
            "model": model,
            "choices": [{"message": {"role": "assistant", "content": content}}],
            "usage": {"prompt_tokens": 10, "completion_tokens": 20},
        },
    )


def error_response(status_code: int, *, headers: dict | None = None, body: str = "{}"):
    return httpx.Response(status_code, headers=headers or {}, content=body.encode())


def correction_payload(**overrides) -> str:
    payload = {
        "reply": "Almost! The verb needs -s here.",
        "correction": {
            "original": "She go to school.",
            "corrected": "She goes to school.",
            "explanation": "С he/she/it феъл бандаки -s мегирад.",
            "rule": "Present simple: -s",
            "examples": ["He works every day."],
            "exercise": 'Fix: "He play football."',
            "alternatives": [],
            "confidence": "high",
        },
        "follow_up": "Try making a question with 'she'.",
    }
    payload.update(overrides)
    return json.dumps(payload)
