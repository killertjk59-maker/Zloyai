"""Health endpoint: honest engine status, no secrets."""

from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import create_app
from tests.conftest import make_settings


def test_health_reports_mock_without_key(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["mock"] is True
    assert body["provider"] == "mock"
    assert body["model"] == "mock-rules-v1"
    assert body["key_configured"] is False
    assert body["version"] == "1.0.0"


def test_health_never_leaks_the_key():
    settings = make_settings(
        ai_provider="openrouter", openrouter_api_key="sk-or-v1-SECRET-VALUE"
    )
    app = create_app(settings)
    with TestClient(app) as client:
        raw = client.get("/api/v1/health").text
    assert "SECRET-VALUE" not in raw
    assert "sk-or-v1" not in raw
    body = client.get("/api/v1/health").json()
    assert body["key_configured"] is True
    assert body["provider"] == "openrouter"
    assert body["mock"] is False


def test_root_route_points_at_docs(client):
    body = client.get("/").json()
    assert body["docs"] == "/docs"
    assert body["health"] == "/api/v1/health"


def test_openapi_schema_is_valid(client):
    schema = client.get("/openapi.json").json()
    assert "/api/v1/tutor/correct" in schema["paths"]
    assert "/api/v1/tutor/chat" in schema["paths"]
    assert "/api/v1/health" in schema["paths"]
