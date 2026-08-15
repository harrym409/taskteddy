"""Firebase Cloud Messaging (FCM) push delivery.

Env-gated: without a Firebase service account configured this module is a safe
no-op, so the app runs in development without Firebase. Provide credentials via
either of:
    FIREBASE_CREDENTIALS_FILE=/path/to/service-account.json
    GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json   (SDK default)

firebase-admin is already a dependency. Initialization is lazy and cached.
"""
import logging
import os
from typing import Optional, Sequence

logger = logging.getLogger("taskteddy.push")

_app = None
_init_attempted = False


def _get_app():
    """Lazily initialize (once) the firebase-admin app, or return None."""
    global _app, _init_attempted
    if _init_attempted:
        return _app
    _init_attempted = True

    cred_file = os.getenv("FIREBASE_CREDENTIALS_FILE") or os.getenv(
        "GOOGLE_APPLICATION_CREDENTIALS"
    )
    if not cred_file or not os.path.exists(cred_file):
        logger.info("FCM not configured (no service account) — push disabled.")
        return None

    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(cred_file)
        _app = firebase_admin.initialize_app(cred)
        logger.info("FCM initialized.")
    except Exception:
        logger.exception("Failed to initialize FCM — push disabled.")
        _app = None
    return _app


def push_configured() -> bool:
    return _get_app() is not None


def send_push(
    tokens: Sequence[str],
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> int:
    """Send a push notification to the given device tokens.

    Returns the number of messages successfully sent (0 if push is disabled).
    Never raises — push failures must not break the request that triggered them.
    Returns the list of invalid tokens via the side effect of logging; callers
    that want to prune tokens can use send_push_detailed.
    """
    ok, _invalid = send_push_detailed(tokens, title, body, data)
    return ok


def send_push_detailed(
    tokens: Sequence[str],
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> tuple[int, list[str]]:
    """Like send_push but also returns tokens FCM reported as unregistered/invalid
    so the caller can delete them. Returns (success_count, invalid_tokens)."""
    tokens = [t for t in tokens if t]
    if not tokens:
        return 0, []
    if not _get_app():
        return 0, []

    try:
        from firebase_admin import messaging

        message = messaging.MulticastMessage(
            tokens=list(tokens),
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
        )
        resp = messaging.send_each_for_multicast(message)
        invalid: list[str] = []
        for idx, r in enumerate(resp.responses):
            if not r.success:
                exc = getattr(r, "exception", None)
                # Unregistered / invalid-argument tokens should be pruned.
                if exc is not None and exc.__class__.__name__ in (
                    "UnregisteredError",
                    "InvalidArgumentError",
                ):
                    invalid.append(tokens[idx])
        return resp.success_count, invalid
    except Exception:
        logger.exception("FCM send failed")
        return 0, []
