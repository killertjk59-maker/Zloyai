"""
ZLOY.AI backend — FastAPI application entry point.

Run locally:
    uvicorn app.main:app --reload --port 8000
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api import routes_health, routes_tutor
from app.core.config import Settings, get_settings
from app.core.rate_limit import RateLimitMiddleware
from app.services.ai.factory import build_provider

settings = get_settings()

logging.basicConfig(
    level=getattr(logging, settings.log_level.upper(), logging.INFO),
    format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
)
logger = logging.getLogger("zloy")


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings: Settings = app.state.settings
    provider = build_provider(settings)
    app.state.provider = provider
    logger.info(
        "ZLOY.AI API ready — provider=%s model=%s mock=%s env=%s",
        provider.name,
        provider.model,
        provider.is_mock,
        settings.app_env,
    )
    if provider.name == "openrouter" and not settings.has_openrouter_key:
        logger.warning(
            "OPENROUTER_API_KEY is not set: /api/v1/tutor/* will return 503 "
            "provider_not_configured. Set the key or use AI_PROVIDER=mock."
        )
    try:
        yield
    finally:
        await provider.aclose()


def create_app(app_settings: Settings | None = None) -> FastAPI:
    settings = app_settings or get_settings()
    application = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description=(
            "Language-tutor backend for the ZLOY.AI Android app. "
            "The API never receives or stores API keys from clients: the "
            "OpenRouter key lives only in this server's environment."
        ),
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url=None,
    )

    application.state.settings = settings

    origins = settings.cors_origin_list
    application.add_middleware(
        CORSMiddleware,
        # Native Android clients do not send an Origin header, so "*" is safe
        # here: there are no cookies and no credentials on this API.
        allow_origins=origins or ["*"],
        allow_credentials=False,
        allow_methods=["GET", "POST", "OPTIONS"],
        allow_headers=["*"],
        expose_headers=["Retry-After"],
    )
    application.add_middleware(
        RateLimitMiddleware,
        limit=settings.rate_limit_requests,
        window_seconds=settings.rate_limit_window_seconds,
    )

    @application.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException):
        detail = exc.detail
        if isinstance(detail, dict) and "code" in detail:
            body = {"detail": detail}
        else:
            body = {"detail": {"code": "http_error", "message": str(detail)}}
        return JSONResponse(
            status_code=exc.status_code,
            content=body,
            headers=getattr(exc, "headers", None) or None,
        )

    @application.exception_handler(RequestValidationError)
    async def validation_handler(request: Request, exc: RequestValidationError):
        first = exc.errors()[0] if exc.errors() else {}
        location = ".".join(str(part) for part in first.get("loc", []))
        message = first.get("msg", "Invalid request.")
        return JSONResponse(
            status_code=422,
            content={
                "detail": {
                    "code": "validation_error",
                    "message": f"{location}: {message}" if location else message,
                }
            },
        )

    @application.exception_handler(Exception)
    async def unhandled_handler(request: Request, exc: Exception):
        # Log the type only — never the payload, which may contain learner text.
        logger.exception(
            "unhandled error on %s: %s", request.url.path, type(exc).__name__
        )
        return JSONResponse(
            status_code=500,
            content={
                "detail": {
                    "code": "internal_error",
                    "message": "Something went wrong on the server.",
                }
            },
        )

    application.include_router(routes_health.router, prefix="/api/v1")
    application.include_router(routes_tutor.router, prefix="/api/v1")

    @application.get("/", include_in_schema=False)
    async def root():
        return {
            "name": settings.app_name,
            "version": settings.app_version,
            "docs": "/docs",
            "health": "/api/v1/health",
        }

    return application


app = create_app()
