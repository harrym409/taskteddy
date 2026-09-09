"""Integration: the ₹500 bonus is NOT given on signup — it is unlocked only
after a customer verifies their email."""
from datetime import datetime

import pytest

from database import User
from utils.email_otp import send_email_otp as seed_email_otp

pytestmark = pytest.mark.integration


def _signup(client, phone, user_type):
    r = client.post("/api/auth/send-otp", json={"phone": phone, "user_type": user_type})
    assert r.status_code == 200, r.text
    otp = r.json().get("otp")
    assert otp, "dev mode should return the OTP for testing"
    r2 = client.post("/api/auth/verify-otp", json={"phone": phone, "otp": otp})
    assert r2.status_code == 200, r2.text
    return r2.json()


def test_signup_does_not_credit_bonus(client, db):
    """A brand-new customer has NO bonus and it is still pending."""
    _signup(client, "+919812345678", "customer")
    user = db.query(User).filter(User.phone == "+919812345678").first()
    assert user is not None
    assert user.promo_balance == 0.0
    assert user.signup_bonus_granted is False


def test_bonus_unlocked_after_email_verification(client, db, auth_as, make_user):
    customer = make_user(role="customer", name="Asha Rao")
    auth_as(customer.id, "customer")
    # Seed the email OTP the same way the send endpoint does, then verify.
    email = "asha@example.com"
    otp = seed_email_otp(email)["otp"]
    r = client.post(
        "/api/users/me/verify-email-otp", json={"email": email, "otp": otp}
    )
    assert r.status_code == 200, r.text
    assert r.json()["bonus_granted"] == 500.0
    db.refresh(customer)
    assert customer.email == email
    assert customer.email_verified_at is not None
    assert customer.promo_balance == 500.0
    assert customer.signup_bonus_granted is True


def test_bonus_not_double_granted(client, db, auth_as, make_user):
    """Once granted, re-verifying (or a second call) never credits again."""
    customer = make_user(role="customer")
    customer.email = "x@example.com"
    customer.email_verified_at = datetime.utcnow()
    customer.promo_balance = 500.0
    customer.signup_bonus_granted = True
    db.commit()

    from routes._helpers import grant_signup_bonus_if_eligible
    granted = grant_signup_bonus_if_eligible(db, customer)
    assert granted == 0.0
    assert customer.promo_balance == 500.0


def test_tasker_never_gets_bonus(client, db, auth_as, make_user):
    tasker = make_user(role="tasker")
    auth_as(tasker.id, "tasker")
    email = "worker@example.com"
    otp = seed_email_otp(email)["otp"]
    r = client.post(
        "/api/users/me/verify-email-otp", json={"email": email, "otp": otp}
    )
    assert r.status_code == 200, r.text
    assert r.json().get("bonus_granted", 0.0) == 0.0
    db.refresh(tasker)
    assert tasker.promo_balance == 0.0
    assert tasker.signup_bonus_granted is False
