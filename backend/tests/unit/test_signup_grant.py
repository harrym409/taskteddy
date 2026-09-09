"""Unit tests for grant_signup_bonus_if_eligible — the email-verified gate."""
from datetime import datetime

import pytest

from routes._helpers import grant_signup_bonus_if_eligible, SIGNUP_BONUS

pytestmark = pytest.mark.unit


def test_no_grant_without_email(db, make_user):
    user = make_user(role="customer")            # no email at all
    assert grant_signup_bonus_if_eligible(db, user) == 0.0
    assert user.promo_balance == 0.0
    assert user.signup_bonus_granted is False


def test_no_grant_email_set_but_unverified(db, make_user):
    user = make_user(role="customer")
    user.email = "a@b.com"                        # set but not verified
    assert grant_signup_bonus_if_eligible(db, user) == 0.0
    assert user.promo_balance == 0.0


def test_grant_when_email_verified(db, make_user):
    user = make_user(role="customer")
    user.email = "a@b.com"
    user.email_verified_at = datetime.utcnow()
    granted = grant_signup_bonus_if_eligible(db, user)
    assert granted == SIGNUP_BONUS
    assert user.promo_balance == SIGNUP_BONUS
    assert user.signup_bonus_granted is True


def test_grant_is_idempotent(db, make_user):
    user = make_user(role="customer")
    user.email = "a@b.com"
    user.email_verified_at = datetime.utcnow()
    grant_signup_bonus_if_eligible(db, user)
    # A second call never credits again.
    assert grant_signup_bonus_if_eligible(db, user) == 0.0
    assert user.promo_balance == SIGNUP_BONUS


def test_tasker_never_eligible(db, make_user):
    tasker = make_user(role="tasker")
    tasker.email = "t@b.com"
    tasker.email_verified_at = datetime.utcnow()
    assert grant_signup_bonus_if_eligible(db, tasker) == 0.0
    assert tasker.promo_balance == 0.0
