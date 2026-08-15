"""In-memory rate limiting middleware."""
import asyncio
import time
from collections import defaultdict
from typing import Dict, Optional, Tuple

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from config import get_settings
from utils.security import get_client_ip


class RateLimitStore:
    """Simple sliding-window request counter."""

    def __init__(self):
        self._store: Dict[str, list[tuple[float, int]]] = defaultdict(list)
        self._lock = asyncio.Lock()

    async def is_allowed(
        self,
        identifier: str,
        limit: int,
        window_seconds: int = 60,
    ) -> Tuple[bool, int, int]:
        async with self._lock:
            now = time.time()
            cutoff = now - window_seconds

            self._store[identifier] = [
                (ts, count)
                for ts, count in self._store[identifier]
                if ts > cutoff
            ]

            current_count = sum(count for ts, count in self._store[identifier])
            if current_count >= limit:
                oldest = min(ts for ts, _ in self._store[identifier])
                reset_time = int(oldest + window_seconds - now)
                return False, 0, max(1, reset_time)

            self._store[identifier].append((now, 1))
            remaining = max(0, limit - current_count - 1)
            return True, remaining, window_seconds


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Global + auth-path specific rate limiter with stricter OTP limits."""

    # Standard auth endpoints
    AUTH_PATH_PREFIXES = (
        "/api/auth/login",
        "/api/auth/register",
        "/api/auth/phone",
    )
    
    # Sensitive endpoints that need stricter limits
    OTP_PATH_PREFIXES = (
        "/api/auth/send-otp",
    )
    
    # Stricter limits for OTP (prevent abuse)
    OTP_RATE_LIMIT = 5  # 5 OTPs per hour per IP
    OTP_RATE_WINDOW = 3600  # 1 hour

    def __init__(self, app, store: Optional[RateLimitStore] = None):
        super().__init__(app)
        self._settings = get_settings()
        self._store = store or RateLimitStore()

    async def dispatch(self, request: Request, call_next) -> Response:
        if not self._settings["RATE_LIMIT_ENABLED"]:
            return await call_next(request)

        path = request.url.path
        client_ip = get_client_ip(request)
        
        # Determine rate limit based on endpoint sensitivity
        if path.startswith(self.OTP_PATH_PREFIXES):
            # Stricter limit for OTP endpoints
            limit = self.OTP_RATE_LIMIT
            window = self.OTP_RATE_WINDOW
        elif path.startswith(self.AUTH_PATH_PREFIXES):
            limit = self._settings["RATE_LIMIT_AUTH_PER_MINUTE"]
            window = 60
        else:
            limit = self._settings["RATE_LIMIT_PER_MINUTE"]
            window = 60

        identifier = f"{client_ip}:{path}"
        is_allowed, remaining, reset_time = await self._store.is_allowed(
            identifier, limit, window
        )

        if not is_allowed:
            return JSONResponse(
                status_code=429,
                content={
                    "error": "Too Many Requests",
                    "message": f"Rate limit exceeded. Try again in {reset_time} seconds.",
                    "retry_after": reset_time,
                },
                headers={
                    "X-RateLimit-Limit": str(limit),
                    "X-RateLimit-Remaining": "0",
                    "X-RateLimit-Reset": str(reset_time),
                    "Retry-After": str(reset_time),
                },
            )

        response = await call_next(request)
        response.headers["X-RateLimit-Limit"] = str(limit)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        response.headers["X-RateLimit-Reset"] = str(reset_time)
        return response


rate_limit_store = RateLimitStore()
