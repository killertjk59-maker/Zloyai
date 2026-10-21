"""Prompt construction: personality, safety rails, language discipline."""

from __future__ import annotations

import pytest

from app.schemas.tutor import ChatRequest, CorrectRequest, HistoryMessage
from app.services.prompts import (
    build_chat_messages,
    build_correct_messages,
    build_system_prompt,
)


def correct_request(**overrides) -> CorrectRequest:
    payload = {
        "text": "She go to school.",
        "target_language": "en",
        "explanation_language": "tg",
        "level": "beginner",
        "personality": "strict",
        "profanity": False,
    }
    payload.update(overrides)
    return CorrectRequest(**payload)


@pytest.mark.parametrize("personality", ["normal", "strict", "roast", "shout"])
def test_each_personality_is_present(personality):
    prompt = build_system_prompt(correct_request(personality=personality))
    assert f"PERSONALITY: {personality.upper()}" in prompt


def test_profanity_disabled_says_so_explicitly():
    prompt = build_system_prompt(correct_request(profanity=False))
    assert "PROFANITY: disabled" in prompt
    assert "No profanity" in prompt


def test_profanity_enabled_still_forbids_slurs():
    prompt = build_system_prompt(correct_request(profanity=True))
    assert "PROFANITY: allowed" in prompt
    assert "never use slurs" in prompt.lower()


def test_safety_rules_are_always_included():
    prompt = build_system_prompt(correct_request(personality="roast", profanity=True))
    assert "Never attack" in prompt
    assert "No slurs" in prompt
    assert "Never invent progress" in prompt


def test_shout_prompt_forbids_claiming_real_shouting():
    prompt = build_system_prompt(correct_request(personality="shout"))
    assert "Never claim your voice is actually shouting" in prompt


def test_explanation_language_is_named():
    prompt = build_system_prompt(correct_request(explanation_language="ru"))
    assert "Russian" in prompt
    prompt = build_system_prompt(correct_request(explanation_language="tg"))
    assert "Tajik" in prompt


def test_level_guidance_changes_with_level():
    beginner = build_system_prompt(correct_request(level="beginner"))
    advanced = build_system_prompt(correct_request(level="advanced"))
    assert "A1" in beginner
    assert "C1" in advanced


def test_learning_style_guidance_is_included():
    prompt = build_system_prompt(correct_request(learning_style="drills"))
    assert "exercises" in prompt.lower()


def test_goals_are_echoed_without_personal_data():
    prompt = build_system_prompt(correct_request(goals=["travel", "work"]))
    assert "travel, work" in prompt


def test_correct_messages_shape():
    messages = build_correct_messages(correct_request())
    assert len(messages) == 2
    assert messages[0]["role"] == "system"
    assert messages[1]["role"] == "user"
    assert "She go to school." in messages[1]["content"]
    assert "SENTENCE TO CHECK" in messages[1]["content"]


def test_history_is_included_and_bounded():
    history = [
        HistoryMessage(role="user", content=f"user {index}") for index in range(10)
    ]
    request = ChatRequest(message="next", history=history)
    messages = build_chat_messages(request)
    turns = [m for m in messages if m["role"] != "system"]
    assert len(turns) == 9  # 8 history turns + the new message
    assert messages[-1]["content"] == "next"


def test_chat_prompt_asks_for_json_and_forbids_fake_errors():
    messages = build_chat_messages(ChatRequest(message="hello"))
    system = messages[0]["content"]
    assert "ONE JSON object" in system
    assert "Never invent a mistake" in system


def test_correct_prompt_handles_already_correct_sentences():
    system = build_system_prompt(correct_request())
    assert "do NOT invent errors" in system
