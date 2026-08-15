"""Security headers middleware."""
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from utils.security import get_security_headers


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Attach common security headers to every response."""

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)
        for header_name, header_value in get_security_headers().items():
            response.headers[header_name] = header_value
        return response
