"""Configuration safety, CORS, validation errors and rate limiting."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.core.rate_limit import RateLimiter
from app.main import create_app
from tests.conftest import make_settings


# --------------------------------------------------------------------- config


def test_secret_is_masked_in_repr():
    settings = make_settings(openrouter_api_key="sk-or-v1-super-secret")
    assert "super-secret" not in repr(settings)
    assert settings.has_openrouter_key is True


def test_blank_key_counts_as_not_configured():
    assert make_settings(openrouter_api_key="   ").has_openrouter_key is False


def test_trailing_slash_is_stripped_from_base_url():
    settings = make_settings(openrouter_base_url="https://openrouter.ai/api/v1/")
    assert settings.openrouter_base_url == "https://openrouter.ai/api/v1"


def test_cors_origins_are_parsed():
    settings = make_settings(cors_origins="https://a.example, https://b.example ,")
    assert settings.cors_origin_list == ["https://a.example", "https://b.example"]


def test_timeouts_are_clamped():
    assert make_settings(request_timeout_seconds=9999).request_timeout_seconds == 180.0
    with pytest.raises(ValueError):
        make_settings(request_timeout_seconds=0)


def test_database_path_extraction():
    assert (
        make_settings(database_url="sqlite:///./zloy.db").database_path == "./zloy.db"
    )
    assert make_settings(database_url="/tmp/zloy.db").database_path == "/tmp/zloy.db"


def test_describe_contains_no_secret():
    described = make_settings(openrouter_api_key="sk-or-v1-secret").describe()
    assert described["openrouter_key_configured"] is True
    assert "secret" not in str(described)


def test_invalid_ai_provider_is_rejected():
    with pytest.raises(ValueError):
        Settings(_env_file=None, ai_provider="wizard")


# ------------------------------------------------------------------ behaviour


def test_empty_message_gets_a_typed_validation_error(client):
    response = client.post("/api/v1/tutor/chat", json={"message": "  "})
    assert response.status_code == 422
    assert response.json()["detail"]["code"] == "validation_error"


def test_missing_body_gets_a_typed_validation_error(client):
    response = client.post("/api/v1/tutor/chat", json={})
    assert response.status_code == 422
    detail = response.json()["detail"]
    assert detail["code"] == "validation_error"
    assert "message" in detail["message"]


def test_unknown_route_returns_typed_404(client):
    response = client.get("/api/v1/nope")
    assert response.status_code == 404
    assert response.json()["detail"]["code"] == "http_error"


def test_method_not_allowed_is_typed(client):
    response = client.get("/api/v1/tutor/correct")
    assert response.status_code == 405
    assert response.json()["detail"]["code"] == "http_error"


def test_cors_preflight_is_allowed(client):
    response = client.options(
        "/api/v1/tutor/chat",
        headers={
            "Origin": "https://example.app",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "content-type",
        },
    )
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] in (
        "*",
        "https://example.app",
    )


def test_rate_limit_protects_the_model_quota():
    settings = make_settings(rate_limit_requests=2, rate_limit_window_seconds=60)
    with TestClient(create_app(settings)) as limited:
        first = limited.post("/api/v1/tutor/chat", json={"message": "hi"})
        second = limited.post("/api/v1/tutor/chat", json={"message": "hi"})
        third = limited.post("/api/v1/tutor/chat", json={"message": "hi"})
    assert first.status_code == 200
    assert second.status_code == 200
    assert third.status_code == 429
    assert third.json()["detail"]["code"] == "rate_limited"
    assert int(third.headers["retry-after"]) >= 1


def test_health_is_not_rate_limited():
    settings = make_settings(rate_limit_requests=1, rate_limit_window_seconds=60)
    with TestClient(create_app(settings)) as limited:
        limited.post("/api/v1/tutor/chat", json={"message": "hi"})
        for _ in range(5):
            assert limited.get("/api/v1/health").status_code == 200


def test_rate_limiter_window_slides():
    limiter = RateLimiter(limit=2, window_seconds=1)
    assert limiter.allow("a")[0] is True
    assert limiter.allow("a")[0] is True
    allowed, retry_after = limiter.allow("a")
    assert allowed is False
    assert retry_after >= 1
    assert limiter.allow("b")[0] is True  # separate bucket per client
    limiter.reset()
    assert limiter.allow("a")[0] is True


def test_rate_limit_counts_forwarded_client():
    settings = make_settings(rate_limit_requests=1, rate_limit_window_seconds=60)
    with TestClient(create_app(settings)) as limited:
        first = limited.post(
            "/api/v1/tutor/chat",
            json={"message": "hi"},
            headers={"X-Forwarded-For": "203.0.113.9"},
        )
        same = limited.post(
            "/api/v1/tutor/chat",
            json={"message": "hi"},
            headers={"X-Forwarded-For": "203.0.113.9, 10.0.0.1"},
        )
        other = limited.post(
            "/api/v1/tutor/chat",
            json={"message": "hi"},
            headers={"X-Forwarded-For": "198.51.100.4"},
        )
    assert first.status_code == 200
    assert same.status_code == 429
    assert other.status_code == 200
