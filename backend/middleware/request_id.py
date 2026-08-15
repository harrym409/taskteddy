"""Request ID middleware for traceability."""
import contextvars
import time
import uuid
from typing import Optional

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

request_id_var: contextvars.ContextVar[Optional[str]] = contextvars.ContextVar(
    "request_id", default=None
)


def get_request_id() -> Optional[str]:
    return request_id_var.get()


class RequestIDMiddleware(BaseHTTPMiddleware):
    """Add request ID + response time headers."""

    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = request.headers.get("X-Request-ID") or uuid.uuid4().hex[:16]
        token = request_id_var.set(request_id)
        start_time = time.perf_counter()
        try:
            response = await call_next(request)
            response.headers["X-Request-ID"] = request_id
            duration = (time.perf_counter() - start_time) * 1000
            response.headers["X-Response-Time"] = f"{duration:.2f}ms"
            return response
        finally:
            request_id_var.reset(token)
