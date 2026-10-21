"""Typed application errors mapped to safe HTTP responses.

Internal exception text and stack traces never reach the client: every error is
converted to a short code plus a human-readable message.
"""

from __future__ import annotations

from fastapi import HTTPException, status


class TutorError(HTTPException):
    """Base error for tutor endpoints."""

    code = "tutor_error"
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    message = "The tutor is temporarily unavailable."

    def __init__(self, message: str | None = None, *, retry_after: int | None = None):
        super().__init__(
            status_code=self.status_code,
            detail={"code": self.code, "message": message or self.message},
            headers={"Retry-After": str(retry_after)} if retry_after else None,
        )


class ProviderNotConfigured(TutorError):
    code = "provider_not_configured"
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    message = (
        "The AI provider is not configured on the server. "
        "Set OPENROUTER_API_KEY or run with AI_PROVIDER=mock."
    )


class ProviderAuthError(TutorError):
    code = "provider_auth_error"
    status_code = status.HTTP_502_BAD_GATEWAY
    message = "The server's AI provider credentials were rejected."


class ProviderRateLimited(TutorError):
    code = "rate_limited"
    status_code = status.HTTP_429_TOO_MANY_REQUESTS
    message = "Too many requests. Please wait a moment and retry."


class ProviderModelUnavailable(TutorError):
    code = "model_unavailable"
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    message = "The configured AI model is unavailable right now."


class ProviderTimeout(TutorError):
    code = "provider_timeout"
    status_code = status.HTTP_504_GATEWAY_TIMEOUT
    message = "The AI provider took too long to answer."


class ProviderBadResponse(TutorError):
    code = "bad_upstream_response"
    status_code = status.HTTP_502_BAD_GATEWAY
    message = "The AI provider returned a response that could not be read."


class MessageTooLong(TutorError):
    code = "message_too_long"
    status_code = 422
    message = "Please send a shorter message and try again."
