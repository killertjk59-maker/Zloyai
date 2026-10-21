"""The deterministic rule engine: honest, explainable corrections."""

from __future__ import annotations

import pytest

from app.services.offline_checker import RULES, check_sentence


@pytest.mark.parametrize(
    "text,expected",
    [
        ("She go to school.", "She goes to school."),
        ("He have two brothers.", "He has two brothers."),
        ("My brother play football.", "My brother plays football."),
        ("I have 20 years old.", "I am 20 years old."),
        ("I am agree with you.", "I agree with you."),
        ("I need more informations.", "I need more information."),
        ("I didn't went to school.", "I didn't go to school."),
        ("This book is more better.", "This book is better."),
        ("I have lived here since three years.", "I have lived here for three years."),
        ("How I can help you?", "How can I help you?"),
        ("I am student.", "I am a student."),
        ("I am engineer.", "I am an engineer."),
        ("She don't like tea.", "She doesn't like tea."),
        ("Yesterday I buy a new phone.", "Yesterday I bought a new phone."),
        ("i think i know.", "I think I know."),
    ],
)
def test_rule_table(text, expected):
    correction = check_sentence(text, "en")
    assert correction is not None, text
    assert correction.corrected == expected
    assert correction.explanation
    assert correction.original == text


def test_unmatched_sentence_returns_none_instead_of_a_guess():
    assert check_sentence("The weather is lovely today.", "en") is None
    assert check_sentence("", "en") is None
    assert check_sentence("   ", "en") is None


def test_already_correct_sentence_is_not_flagged():
    assert check_sentence("She goes to school.", "en") is None


def test_explanation_language_is_honoured():
    tg = check_sentence("She go to school.", "tg")
    ru = check_sentence("She go to school.", "ru")
    en = check_sentence("She go to school.", "en")
    assert tg and tg.explanation != ru.explanation
    assert "мегирад" in tg.explanation
    assert "глагол" in ru.explanation.lower()
    assert "present simple" in en.explanation.lower()


def test_unknown_language_falls_back_to_english():
    correction = check_sentence("She go to school.", "klingon")
    assert correction is not None
    assert "present simple" in correction.explanation.lower()


def test_examples_are_in_the_target_language():
    correction = check_sentence("She go to school.", "tg")
    assert correction.examples
    assert any("She" in example or "He" in example for example in correction.examples)


def test_multiple_rules_can_apply_at_once():
    correction = check_sentence("i am agree.", "en")
    assert correction is not None
    assert correction.corrected == "I agree."
    assert "•" in (correction.rule or "")


def test_would_to_is_flagged_as_low_confidence():
    correction = check_sentence("I would to go home.", "en")
    assert correction is not None
    assert correction.corrected == "I would go home."
    assert correction.confidence == "low"
    assert correction.alternatives


def test_high_confidence_for_unambiguous_errors():
    correction = check_sentence("She go to school.", "en")
    assert correction is not None
    assert correction.confidence == "high"
    assert correction.alternatives == []


def test_every_rule_has_all_three_languages():
    for rule in RULES:
        for language in ("en", "ru", "tg"):
            assert rule.name.get(language), f"{rule.id} missing name/{language}"
            assert rule.explanation.get(language), (
                f"{rule.id} missing explanation/{language}"
            )


def test_rule_ids_are_unique():
    ids = [rule.id for rule in RULES]
    assert len(ids) == len(set(ids))


def test_rules_are_idempotent():
    """Applying a rule twice must not keep changing the sentence."""
    correction = check_sentence("She go to school.", "en")
    assert correction is not None
    assert check_sentence(correction.corrected, "en") is None


def test_exercise_is_offered_for_the_first_rule():
    correction = check_sentence("She go to school.", "en")
    assert correction is not None
    assert correction.exercise
