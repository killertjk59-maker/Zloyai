"""Provider selection + tolerant parsing of model output."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.services.ai.base import (
    extract_json_object,
    parse_correction,
    parse_model_payload,
    strip_code_fences,
)
from app.services.ai.factory import build_provider
from app.services.ai.mock import MockProvider
from app.services.ai.openrouter import OpenRouterProvider
from tests.conftest import make_settings


# ------------------------------------------------------------------ selection


def test_auto_without_key_selects_mock():
    provider = build_provider(make_settings(ai_provider="auto"))
    assert isinstance(provider, MockProvider)
    assert provider.is_mock is True


def test_auto_with_key_selects_openrouter():
    provider = build_provider(
        make_settings(ai_provider="auto", openrouter_api_key="sk-or-v1-x")
    )
    assert isinstance(provider, OpenRouterProvider)
    assert provider.is_mock is False


def test_explicit_mock_wins_even_with_a_key():
    provider = build_provider(
        make_settings(ai_provider="mock", openrouter_api_key="sk-or-v1-x")
    )
    assert isinstance(provider, MockProvider)


def test_openrouter_without_key_fails_per_request_with_a_clear_503():
    settings = make_settings(ai_provider="openrouter")
    with TestClient(create_app(settings)) as client:
        response = client.post("/api/v1/tutor/correct", json={"text": "She go home."})
    assert response.status_code == 503
    detail = response.json()["detail"]
    assert detail["code"] == "provider_not_configured"
    assert "OPENROUTER_API_KEY" in detail["message"]


# -------------------------------------------------------------------- parsing


def test_strip_code_fences():
    assert strip_code_fences('```json\n{"a": 1}\n```') == '{"a": 1}'
    assert strip_code_fences('{"a": 1}') == '{"a": 1}'


def test_extract_json_with_surrounding_text():
    assert extract_json_object('blah {"a": {"b": 2}} trailing') == {"a": {"b": 2}}


def test_extract_json_handles_braces_inside_strings():
    payload = extract_json_object('{"a": "a } brace"}')
    assert payload == {"a": "a } brace"}


def test_extract_json_handles_escaped_quotes():
    payload = extract_json_object('{"a": "he said \\"hi\\""}')
    assert payload == {"a": 'he said "hi"'}


def test_extract_json_returns_none_for_garbage():
    assert extract_json_object("nothing here") is None
    assert extract_json_object("{broken") is None
    assert extract_json_object("[1, 2, 3]") is None


def test_parse_correction_coerces_untrusted_types():
    correction = parse_correction(
        {
            "original": 5,
            "corrected": None,
            "explanation": "Because English.",
            "rule": 12,
            "examples": ["ok", 3, None, {"x": 1}],
            "alternatives": "not-a-list",
            "confidence": "HIGH",
        },
        original="fallback",
    )
    assert correction is not None
    assert correction.original == "fallback"
    assert correction.corrected == "fallback"
    assert correction.examples == ["ok", "3"]
    assert correction.alternatives == []
    assert correction.confidence == "high"


def test_parse_correction_rejects_non_dict():
    assert parse_correction("nope", original="x") is None
    assert parse_correction(None, original="x") is None


def test_parse_model_payload_plain_text():
    reply, correction, follow_up = parse_model_payload("Just text.", original="x")
    assert reply == "Just text."
    assert correction is None
    assert follow_up is None


def test_parse_model_payload_falls_back_to_explanation_as_reply():
    reply, correction, _ = parse_model_payload(
        '{"correction": {"explanation": "Use -s."}}', original="He go."
    )
    assert correction is not None
    assert reply == "Use -s."


@pytest.mark.parametrize("blank", ["", "   ", "{}"])
def test_parse_model_payload_never_returns_empty_reply(blank):
    reply, _, _ = parse_model_payload(blank, original="x")
    assert reply
