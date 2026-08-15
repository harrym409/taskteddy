"""Email sending utilities using SendGrid with dynamic templates."""
import os
import logging
from typing import Optional

from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Email, Mail, To

from config import get_settings

settings = get_settings()
logger = logging.getLogger("taskteddy.email")

# SendGrid template ID - set via environment variable
# Format: d-xxxxxxxxxxxxxxxxxxxxx
_TEMPLATE_ID = os.getenv("SENDGRID_EMAIL_TEMPLATE_ID", "")


def _get_sendgrid_client() -> Optional[SendGridAPIClient]:
    """Get SendGrid client from environment."""
    api_key = os.getenv("SENDGRID_API_KEY")
    if not api_key:
        logger.warning("SENDGRID_API_KEY is missing; email OTP will not be delivered.")
        return None
    try:
        return SendGridAPIClient(api_key)
    except Exception as exc:
        logger.exception("Could not initialize SendGrid client: %s", exc)
        return None


def _get_from_email() -> str:
    """Get sender email from settings."""
    return os.getenv("EMAIL_FROM", "support@taskteddy.com")


def send_email_otp(
    to_email: str,
    name: str,
    otp: str,
) -> bool:
    """
    Send OTP verification email via SendGrid using dynamic template.

    Args:
        to_email: Recipient email address
        name: Recipient name
        otp: 6-digit OTP code

    Returns:
        True if email sent successfully, False otherwise
    """
    sg = _get_sendgrid_client()
    if not sg:
        return False

    from_email = _get_from_email()
    template_id = _TEMPLATE_ID

    # If no template ID configured, fall back to simple email
    if not template_id:
        return _send_simple_email(sg, from_email, to_email, name, otp)

    try:
        # Use dynamic template
        message = Mail(
            from_email=Email(from_email),
            to_emails=To(to_email),
            subject="Verify your email - TaskTeddy",
        )

        # Set dynamic template data directly on message
        message.template_id = template_id
        message.dynamic_template_data = {
            "name": name,
            "otp": otp,
            "expiry_minutes": int(settings.get("OTP_EXPIRY_SECONDS", 60) / 60),
        }

        response = sg.send(message)
        return response.status_code in [200, 201, 202]

    except Exception as exc:
        logger.exception("Failed to send OTP email via SendGrid template: %s", exc)
        return False


def _send_simple_email(
    sg: SendGridAPIClient,
    from_email: str,
    to_email: str,
    name: str,
    otp: str,
) -> bool:
    """
    Fallback simple email when no template is configured.
    """
    try:
        message = Mail(
            from_email=Email(from_email),
            to_emails=To(to_email),
            subject="Verify your email - TaskTeddy",
            plain_text_content=f"""
Hi {name},

Your email verification code is: {otp}

This code expires in 60 seconds.

If you didn't request this, please ignore this email.

- TaskTeddy
            """,
        )
        response = sg.send(message)
        return response.status_code in [200, 201, 202]

    except Exception as exc:
        logger.exception("Failed to send fallback OTP email: %s", exc)
        return False
