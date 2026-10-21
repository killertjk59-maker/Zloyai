"""OpenRouter integration, exercised against a scripted transport (no network)."""

from __future__ import annotations

import json

import httpx
import pytest

from tests.conftest import correction_payload, error_response, ok_response

BODY = {
    "text": "She go to school.",
    "explanation_language": "tg",
    "personality": "strict",
    "level": "beginner",
}


def test_request_shape_matches_the_openrouter_contract(openrouter):
    api = openrouter([lambda request: ok_response(correction_payload())])
    response = api.post("/api/v1/tutor/correct", json=BODY)
    assert response.status_code == 200

    sent = api.last_request
    assert sent["url"] == "https://openrouter.ai/api/v1/chat/completions"
    assert sent["headers"]["authorization"] == "Bearer test-key-not-real"
    assert sent["headers"]["x-title"] == "ZLOY.AI"
    assert sent["body"]["model"] == "test/model:free"
    assert sent["body"]["response_format"] == {"type": "json_object"}
    assert 0 <= sent["body"]["temperature"] <= 2
    assert sent["body"]["max_tokens"] > 0
    assert sent["body"]["messages"][0]["role"] == "system"
    assert "She go to school." in sent["body"]["messages"][-1]["content"]


def test_system_prompt_carries_personality_and_safety(openrouter):
    api = openrouter([lambda request: ok_response(correction_payload())])
    api.post(
        "/api/v1/tutor/correct",
        json={
            **BODY,
            "personality": "roast",
            "profanity": False,
            "explanation_language": "ru",
        },
    )
    system = api.last_request["body"]["messages"][0]["content"]
    assert "PERSONALITY: ROAST" in system
    assert "PROFANITY: disabled" in system
    assert "Never attack" in system or "never attack" in system
    assert "Russian" in system
    assert "JSON" in system


def test_successful_ai_answer_keeps_the_app_contract(openrouter):
    api = openrouter([lambda request: ok_response(correction_payload())])
    body = api.post("/api/v1/tutor/correct", json=BODY).json()

    assert body["source"] == "ai"
    assert body["model"] == "test/model:free"
    assert body["reply"].startswith("Almost!")
    assert body["correction"]["corrected"] == "She goes to school."
    assert body["correction"]["confidence"] == "high"
    assert isinstance(body["correction"]["examples"], list)
    assert body["follow_up"]


def test_markdown_fenced_json_is_tolerated(openrouter):
    fenced = "```json\n" + correction_payload() + "\n```"
    api = openrouter([lambda request: ok_response(fenced)])
    body = api.post("/api/v1/tutor/correct", json=BODY).json()
    assert body["correction"]["corrected"] == "She goes to school."


def test_json_with_chatter_around_it_is_tolerated(openrouter):
    noisy = "Sure! Here you go:\n" + correction_payload() + "\nHope that helps."
    api = openrouter([lambda request: ok_response(noisy)])
    body = api.post("/api/v1/tutor/correct", json=BODY).json()
    assert body["correction"]["corrected"] == "She goes to school."


def test_plain_text_answer_never_invents_a_correction(openrouter):
    api = openrouter([lambda request: ok_response("Your sentence is fine, well done!")])
    body = api.post("/api/v1/tutor/correct", json=BODY).json()
    assert body["correction"] is None
    assert body["reply"] == "Your sentence is fine, well done!"


def test_correction_without_explanation_is_dropped(openrouter):
    payload = json.dumps(
        {"reply": "Fixed.", "correction": {"original": "a", "corrected": "b"}}
    )
    api = openrouter([lambda request: ok_response(payload)])
    body = api.post("/api/v1/tutor/correct", json=BODY).json()
    assert body["correction"] is None


def test_unknown_confidence_falls_back_to_medium(openrouter):
    payload = json.loads(correction_payload())
    payload["correction"]["confidence"] = "absolutely-certain"
    api = openrouter([lambda request: ok_response(json.dumps(payload))])
    body = api.post("/api/v1/tutor/correct", json=BODY).json()
    assert body["correction"]["confidence"] == "medium"


def test_rate_limit_becomes_429_rate_limited(openrouter):
    api = openrouter(
        [lambda request: error_response(429, headers={"Retry-After": "7"})]
    )
    response = api.post("/api/v1/tutor/correct", json=BODY)
    assert response.status_code == 429
    assert response.json()["detail"]["code"] == "rate_limited"
    assert response.headers.get("retry-after") == "7"


def test_unavailable_model_becomes_503_model_unavailable(openrouter):
    api = openrouter([lambda request: error_response(503)])
    response = api.post("/api/v1/tutor/correct", json=BODY)
    assert response.status_code == 503
    assert response.json()["detail"]["code"] == "model_unavailable"


def test_retired_model_slug_becomes_503_not_a_crash(openrouter):
    api = openrouter([lambda request: error_response(404)])
    response = api.post("/api/v1/tutor/correct", json=BODY)
    assert response.status_code == 503
    assert response.json()["detail"]["code"] == "model_unavailable"


def test_bad_key_becomes_502_auth_error_without_echoing_the_key(openrouter):
    api = openrouter(
        [lambda request: error_response(401, body='{"error":"Invalid key"}')]
    )
    response = api.post("/api/v1/tutor/correct", json=BODY)
    assert response.status_code == 502
    assert response.json()["detail"]["code"] == "provider_auth_error"
    assert "test-key-not-real" not in response.text


def test_timeout_becomes_504(openrouter):
    def boom(request):
        raise httpx.ReadTimeout("too slow", request=request)

    api = openrouter([boom])
    response = api.post("/api/v1/tutor/correct", json=BODY)
    assert response.status_code == 504
    assert response.json()["detail"]["code"] == "provider_timeout"


def test_transport_error_becomes_502(openrouter):
    def boom(request):
        raise httpx.ConnectError("no route", request=request)

    api = openrouter([boom])
    response = api.post("/api/v1/tutor/correct", json=BODY)
    assert response.status_code == 502
    assert response.json()["detail"]["code"] == "bad_upstream_response"


def test_malformed_upstream_payload_becomes_502(openrouter):
    api = openrouter([lambda request: httpx.Response(200, json={"nope": True})])
    response = api.post("/api/v1/tutor/correct", json=BODY)
    assert response.status_code == 502
    assert response.json()["detail"]["code"] == "bad_upstream_response"


def test_empty_answer_becomes_502(openrouter):
    api = openrouter([lambda request: ok_response("   ")])
    response = api.post("/api/v1/tutor/correct", json=BODY)
    assert response.status_code == 502


def test_chat_uses_history_in_the_message_list(openrouter):
    api = openrouter([lambda request: ok_response(correction_payload())])
    api.post(
        "/api/v1/tutor/chat",
        json={
            "message": "And now?",
            "history": [
                {"role": "user", "content": "Hello"},
                {"role": "assistant", "content": "Hi! Ready to practise?"},
            ],
        },
    )
    messages = api.last_request["body"]["messages"]
    assert [message["role"] for message in messages] == [
        "system",
        "user",
        "assistant",
        "user",
    ]
    assert messages[-1]["content"] == "And now?"


def test_health_reports_openrouter_when_a_key_is_present(openrouter):
    api = openrouter([lambda request: ok_response(correction_payload())])
    body = api.get("/api/v1/health").json()
    assert body["provider"] == "openrouter"
    assert body["mock"] is False
    assert body["model"] == "test/model:free"


@pytest.mark.parametrize("status", [500, 502, 520])
def test_server_errors_become_model_unavailable(openrouter, status):
    api = openrouter([lambda request: error_response(status)])
    response = api.post("/api/v1/tutor/chat", json={"message": "hi"})
    assert response.status_code == 503
    assert response.json()["detail"]["code"] == "model_unavailable"
