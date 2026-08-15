"""Security helpers used by middleware and route validation."""
import os
import re
from typing import Optional

from fastapi import HTTPException, status


# Configurable image CDN domains (can be extended via environment)
_IMAGE_CDN_DOMAINS = os.getenv("IMAGE_CDN_DOMAINS", "")
ALLOWED_IMAGE_DOMAINS = (
    [_d.strip() for _d in _IMAGE_CDN_DOMAINS.split(",") if _d.strip()]
    or ["https://*.amazonaws.com", "https://*.digitaloceanspaces.com", "https://*.backblazeb2.com"]
)


def sanitize_string(value: Optional[str], max_length: int = 1000) -> Optional[str]:
    if value is None:
        return None
    value = value.replace("\x00", "").strip()
    if len(value) > max_length:
        value = value[:max_length]

    html_escape_table = {
        "&": "&amp;",
        '"': "&quot;",
        "'": "&#x27;",
        ">": "&gt;",
        "<": "&lt;",
    }
    for char, escape in html_escape_table.items():
        value = value.replace(char, escape)
    return value


def sanitize_email(email: Optional[str]) -> Optional[str]:
    if email is None:
        return None

    email = email.strip().lower()
    email_pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

    if not re.match(email_pattern, email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid email format",
        )
    if len(email) > 254:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email too long",
        )
    return email


def get_client_ip(request) -> str:
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()

    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip.strip()

    if hasattr(request, "client") and request.client:
        return request.client.host

    return "unknown"


def get_security_headers() -> dict:
    """Get security headers with configurable CSP for image domains."""
    # Build CSP with allowed image domains
    img_sources = ["'self'", "data:", "https:"]
    for domain in ALLOWED_IMAGE_DOMAINS:
        img_sources.append(domain)
    
    csp = (
        f"default-src 'self'; "
        f"img-src {' '.join(img_sources)}; "
        f"style-src 'self' 'unsafe-inline'; "
        f"font-src 'self' https:; "
        f"script-src 'self'; "
        f"connect-src 'self'; "
        f"frame-src 'none'; "
        f"object-src 'none'; "
        f"base-uri 'self'"
    )
    
    return {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "X-XSS-Protection": "1; mode=block",
        "Referrer-Policy": "strict-origin-when-cross-origin",
        "Permissions-Policy": "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=()",
        "Content-Security-Policy": csp,
    }
