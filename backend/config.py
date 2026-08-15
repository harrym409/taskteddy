"""Configuration management for TaskTeddy backend."""
import os
import secrets
import string
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv

# Load .env from backend directory
load_dotenv(dotenv_path=Path(__file__).parent / ".env")


class ConfigurationError(Exception):
    """Raised when required configuration is missing or invalid."""


def _generate_strong_secret(length: int = 64) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def _validate_jwt_secret() -> str:
    is_production = os.getenv("ENVIRONMENT", "development") == "production"
    secret = os.getenv("JWT_SECRET", "")

    if not secret:
        if is_production:
            # A generated per-process secret invalidates all tokens on restart and
            # differs across workers — never acceptable in production.
            raise ConfigurationError(
                "JWT_SECRET is required in production. Set a stable, random secret "
                "of at least 32 characters (see .env.example)."
            )
        return _generate_strong_secret()

    if len(secret) < 32 and is_production:
        raise ConfigurationError(
            "JWT_SECRET must be at least 32 characters in production. "
            f"Current length: {len(secret)}"
        )
    return secret


@lru_cache()
def get_settings() -> dict:
    env = os.getenv("ENVIRONMENT", "development")
    is_production = env == "production"

    cors_origins_raw = os.getenv("CORS_ORIGINS", "*")
    if cors_origins_raw == "*":
        cors_origins = ["*"] if not is_production else []
    else:
        cors_origins = [origin.strip() for origin in cors_origins_raw.split(",") if origin.strip()]

    redis_url = os.getenv("REDIS_URL", "")

    return {
        "ENVIRONMENT": env,
        "IS_PRODUCTION": is_production,
        "HOST": os.getenv("HOST", "0.0.0.0"),
        "PORT": int(os.getenv("PORT", "8000")),
        "DATABASE_URL": os.getenv(
            "DATABASE_URL",
            "postgresql://postgres:postgres@localhost:5433/taskteddy",
        ),
        "JWT_SECRET": _validate_jwt_secret(),
        "JWT_ALGORITHM": os.getenv("JWT_ALGORITHM", "HS256"),
        "JWT_EXPIRATION": int(os.getenv("JWT_EXPIRATION", "7200")),
        "FIREBASE_VERIFY_TOKENS": os.getenv("FIREBASE_VERIFY_TOKENS", "false").lower() == "true",
        "UPLOAD_DIR": os.getenv("UPLOAD_DIR", "./uploads"),
        "MAX_UPLOAD_SIZE": int(os.getenv("MAX_UPLOAD_SIZE", "10485760")),
        "CORS_ORIGINS": cors_origins,
        "CORS_ALLOW_CREDENTIALS": os.getenv("CORS_ALLOW_CREDENTIALS", "true").lower() == "true",
        "RATE_LIMIT_ENABLED": os.getenv("RATE_LIMIT_ENABLED", "true").lower() == "true",
        "RATE_LIMIT_PER_MINUTE": int(os.getenv("RATE_LIMIT_PER_MINUTE", "120")),
        "RATE_LIMIT_AUTH_PER_MINUTE": int(os.getenv("RATE_LIMIT_AUTH_PER_MINUTE", "20")),
        "LOG_LEVEL": os.getenv("LOG_LEVEL", "INFO"),
        "LOG_FORMAT": os.getenv("LOG_FORMAT", "text"),
        "redis_url": redis_url,
        "redis_enabled": bool(redis_url),
        "OTP_EXPIRY_SECONDS": int(os.getenv("OTP_EXPIRY_SECONDS", "60")),
        "FRONTEND_URL": os.getenv("FRONTEND_URL", "http://localhost:3000"),
        # Pagination defaults (explicit for consistency)
        "DEFAULT_PAGE_SIZE": int(os.getenv("DEFAULT_PAGE_SIZE", "20")),
        "MAX_PAGE_SIZE": int(os.getenv("MAX_PAGE_SIZE", "100")),
        # S3 Storage (for production file uploads)
        "S3_BUCKET": os.getenv("S3_BUCKET", ""),
        "S3_REGION": os.getenv("S3_REGION", "us-east-1"),
        "S3_ACCESS_KEY": os.getenv("S3_ACCESS_KEY", ""),
        "S3_SECRET_KEY": os.getenv("S3_SECRET_KEY", ""),
        "S3_ENDPOINT_URL": os.getenv("S3_ENDPOINT_URL", ""),  # Optional: for MinIO/custom S3
        "S3_PUBLIC_URL": os.getenv("S3_PUBLIC_URL", ""),  # CloudFront or custom domain
        "USE_S3": os.getenv("USE_S3", "false").lower() == "true",
    }
