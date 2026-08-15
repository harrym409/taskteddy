"""Application logging configuration.

Wires LOG_LEVEL / LOG_FORMAT from config into the root logger and injects the
current request id (from RequestIDMiddleware) into every record so logs can be
correlated with the X-Request-ID response header.
"""
import json
import logging
import sys
from typing import Any

from middleware.request_id import get_request_id


class RequestIdFilter(logging.Filter):
    """Attach the active request id to each log record (``-`` when none)."""

    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = get_request_id() or "-"
        return True


class JsonFormatter(logging.Formatter):
    """Minimal structured JSON formatter."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": getattr(record, "request_id", "-"),
            "time": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
        }
        if record.exc_info:
            payload["exc"] = self.formatException(record.exc_info)
        return json.dumps(payload, default=str)


_TEXT_FORMAT = "%(asctime)s %(levelname)-5s [%(name)s] [req:%(request_id)s] %(message)s"


def configure_logging(settings: dict) -> None:
    """Configure the root logger from settings. Idempotent."""
    level = getattr(logging, str(settings.get("LOG_LEVEL", "INFO")).upper(), logging.INFO)
    use_json = str(settings.get("LOG_FORMAT", "text")).lower() == "json"

    handler = logging.StreamHandler(sys.stdout)
    handler.addFilter(RequestIdFilter())
    handler.setFormatter(JsonFormatter() if use_json else logging.Formatter(_TEXT_FORMAT))

    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(level)

    # Align uvicorn's loggers with our handler/format instead of its defaults.
    for name in ("uvicorn", "uvicorn.error", "uvicorn.access"):
        lg = logging.getLogger(name)
        lg.handlers.clear()
        lg.propagate = True
