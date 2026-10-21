"""Very small in-process sliding-window rate limiter.

Good enough for a single-instance free-tier deployment: it protects the shared
OpenRouter quota from accidental loops. For multiple workers use Redis instead;
this is documented in the README rather than pretended to be distributed.
"""

from __future__ import annotations

import time
from collections import defaultdict, deque
from threading import Lock

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import JSONResponse, Response

PROTECTED_PREFIXES = ("/api/v1/tutor/",)


class RateLimiter:
    def __init__(self, limit: int, window_seconds: int):
        self.limit = max(1, limit)
        self.window = max(1, window_seconds)
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = Lock()

    def allow(self, key: str) -> tuple[bool, int]:
        now = time.monotonic()
        with self._lock:
            bucket = self._hits[key]
            while bucket and now - bucket[0] > self.window:
                bucket.popleft()
            if len(bucket) >= self.limit:
                retry_after = max(1, int(self.window - (now - bucket[0])) + 1)
                return False, retry_after
            bucket.append(now)
            return True, 0

    def reset(self) -> None:
        with self._lock:
            self._hits.clear()


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, limit: int, window_seconds: int):
        super().__init__(app)
        self.limiter = RateLimiter(limit, window_seconds)

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        path = request.url.path
        if request.method == "POST" and path.startswith(PROTECTED_PREFIXES):
            client = request.client.host if request.client else "unknown"
            # Render/Fly/Cloud Run put the real client first in X-Forwarded-For.
            forwarded = request.headers.get("x-forwarded-for", "")
            if forwarded:
                client = forwarded.split(",")[0].strip() or client
            allowed, retry_after = self.limiter.allow(client)
            if not allowed:
                return JSONResponse(
                    status_code=429,
                    content={
                        "detail": {
                            "code": "rate_limited",
                            "message": "Too many requests. Please wait a moment and retry.",
                        }
                    },
                    headers={"Retry-After": str(retry_after)},
                )
        return await call_next(request)
