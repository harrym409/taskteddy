"""SMS delivery abstraction.

Production OTP delivery goes through a real SMS provider selected by the
SMS_PROVIDER env var. The integration is written so the app runs in development
with NO provider configured: in that case the message is logged server-side
(never returned to the client) so the OTP flow is still testable locally.

Configure via env (see .env.example):
    SMS_PROVIDER=msg91 | twilio | console   (default: console)

    # MSG91
    MSG91_AUTH_KEY=...
    MSG91_SENDER_ID=TSKTDY
    MSG91_OTP_TEMPLATE_ID=...        # optional, if using MSG91 OTP templates

    # Twilio
    TWILIO_ACCOUNT_SID=...
    TWILIO_AUTH_TOKEN=...
    TWILIO_FROM_NUMBER=+1...
"""
import logging
import os
from typing import Optional

import httpx

from config import get_settings

logger = logging.getLogger("taskteddy.sms")
settings = get_settings()


def sms_provider() -> str:
    return os.getenv("SMS_PROVIDER", "console").strip().lower()


def provider_configured() -> bool:
    """True when a real (non-console) provider has its credentials set."""
    provider = sms_provider()
    if provider == "msg91":
        return bool(os.getenv("MSG91_AUTH_KEY"))
    if provider == "twilio":
        return bool(
            os.getenv("TWILIO_ACCOUNT_SID")
            and os.getenv("TWILIO_AUTH_TOKEN")
            and os.getenv("TWILIO_FROM_NUMBER")
        )
    return False


def send_sms(phone: str, message: str) -> bool:
    """Send an SMS. Returns True on success.

    Falls back to console/logging when no provider is configured so local dev
    keeps working. In production an unconfigured provider is an error.
    """
    provider = sms_provider()

    try:
        if provider == "msg91":
            return _send_msg91(phone, message)
        if provider == "twilio":
            return _send_twilio(phone, message)
    except Exception:  # network/provider failure — never crash the request
        logger.exception("SMS send failed via provider=%s", provider)
        return False

    # console fallback
    if settings["IS_PRODUCTION"]:
        logger.error(
            "No SMS provider configured in production (SMS_PROVIDER=%s). "
            "Cannot deliver message to %s.",
            provider,
            phone,
        )
        return False
    logger.info("[DEV SMS -> %s] %s", phone, message)
    return True


def _send_msg91(phone: str, message: str) -> bool:
    auth_key = os.getenv("MSG91_AUTH_KEY", "")
    sender = os.getenv("MSG91_SENDER_ID", "TSKTDY")
    if not auth_key:
        raise RuntimeError("MSG91_AUTH_KEY not set")
    # MSG91 flow/SMS API. Numbers are sent without the leading '+'.
    resp = httpx.post(
        "https://control.msg91.com/api/v5/flow/",
        headers={"authkey": auth_key, "Content-Type": "application/json"},
        json={
            "sender": sender,
            "short_url": "0",
            "mobiles": phone.lstrip("+"),
            "message": message,
        },
        timeout=10.0,
    )
    ok = resp.status_code == 200
    if not ok:
        logger.error("MSG91 error %s: %s", resp.status_code, resp.text[:200])
    return ok


def _send_twilio(phone: str, message: str) -> bool:
    sid = os.getenv("TWILIO_ACCOUNT_SID", "")
    token = os.getenv("TWILIO_AUTH_TOKEN", "")
    from_number = os.getenv("TWILIO_FROM_NUMBER", "")
    if not (sid and token and from_number):
        raise RuntimeError("Twilio credentials not set")
    resp = httpx.post(
        f"https://api.twilio.com/2010-04-01/Accounts/{sid}/Messages.json",
        auth=(sid, token),
        data={"To": phone, "From": from_number, "Body": message},
        timeout=10.0,
    )
    ok = resp.status_code in (200, 201)
    if not ok:
        logger.error("Twilio error %s: %s", resp.status_code, resp.text[:200])
    return ok
