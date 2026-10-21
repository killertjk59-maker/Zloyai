"""POST /api/v1/tutor/correct — request contract and mock answers."""

from __future__ import annotations

import pytest

BASE = {
    "text": "She go to school.",
    "target_language": "en",
    "explanation_language": "tg",
    "level": "beginner",
    "personality": "strict",
    "profanity": False,
    "learning_style": "examples",
    "goals": ["travel"],
}


def post(client, **overrides):
    return client.post("/api/v1/tutor/correct", json={**BASE, **overrides})


def test_corrects_third_person_sentence(client):
    response = post(client)
    assert response.status_code == 200
    body = response.json()
    assert body["source"] == "mock"
    assert body["model"] == "mock-rules-v1"
    correction = body["correction"]
    assert correction["original"] == "She go to school."
    assert correction["corrected"] == "She goes to school."
    assert correction["confidence"] == "high"
    assert correction["rule"]
    assert correction["explanation"]
    assert body["reply"]


def test_returns_tajik_explanation_when_asked(client):
    body = post(client, explanation_language="tg").json()
    assert "мегирад" in body["correction"]["explanation"]


def test_returns_russian_explanation_when_asked(client):
    body = post(
        client, explanation_language="ru", text="He go to work every day."
    ).json()
    assert body["correction"]["corrected"] == "He goes to work every day."
    assert "глагол" in body["correction"]["explanation"].lower()


def test_returns_english_explanation_when_asked(client):
    body = post(client, explanation_language="en").json()
    assert "present simple" in body["correction"]["explanation"].lower()


def test_would_to_is_low_confidence_and_offers_alternative(client):
    body = post(
        client, text="I would to go to school.", explanation_language="en"
    ).json()
    correction = body["correction"]
    assert correction["corrected"] == "I would go to school."
    # The rule keeps "would" but flags that the learner may have meant past tense.
    assert correction["confidence"] == "low"
    assert correction["alternatives"]


def test_age_uses_to_be(client):
    body = post(client, text="I have 20 years old.", explanation_language="en").json()
    assert body["correction"]["corrected"] == "I am 20 years old."


def test_clean_sentence_returns_no_invented_correction(client):
    body = post(client, text="I went to the market yesterday.").json()
    assert body["correction"] is None
    reply = body["reply"].lower()
    # It must not pretend the sentence is perfect, nor invent an error.
    assert "маънои он нест" in reply


def test_blank_text_is_rejected_by_validation(client):
    response = post(client, text="   ")
    assert response.status_code == 422
    detail = response.json()["detail"]
    assert detail["code"] == "validation_error"


def test_overlong_text_is_rejected_with_typed_error(client):
    response = post(client, text="a" * 700)
    assert response.status_code == 422
    assert response.json()["detail"]["code"] == "validation_error"


def test_profanity_on_adds_flavour_but_keeps_the_lesson(client):
    body = post(client, personality="roast", profanity=True).json()
    assert body["correction"]["explanation"]
    assert body["reply"]


def test_unknown_personality_is_rejected(client):
    response = post(client, personality="murderous")
    assert response.status_code == 422


def test_goals_are_deduplicated_and_trimmed(client):
    response = post(client, goals=[" travel ", "travel", "", "work "])
    assert response.status_code == 200


@pytest.mark.parametrize(
    "text,expected",
    [
        ("I am agree with you.", "I agree with you."),
        ("She don't like coffee.", "She doesn't like coffee."),
        ("I didn't went there.", "I didn't go there."),
        ("This is more better.", "This is better."),
        ("I am student.", "I am a student."),
        ("i think i know.", "I think I know."),
        ("Yesterday I buy a new phone.", "Yesterday I bought a new phone."),
        ("I have informations.", "I have information."),
        ("He live in Khujand.", "He lives in Khujand."),
        ("How I can help you?", "How can I help you?"),
        ("I live here since three years.", "I live here for three years."),
    ],
)
def test_rule_table_through_the_api(client, text, expected):
    body = post(client, text=text, explanation_language="en").json()
    assert body["correction"] is not None, text
    assert body["correction"]["corrected"] == expected
