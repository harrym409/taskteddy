"""Unit tests for the money invariants of the promo/commission engine.

These protect the core business guarantee:
  * the tasker's take-home is ALWAYS gross − full_commission (promo never
    reduces their pay), and
  * the platform's profit is commission − discount, which is NEVER negative
    (the discount can't exceed the commission — no loss).
"""
import pytest

from routes._helpers import (
    PROMO_MAX_PCT,
    SIGNUP_BONUS,
    charge_commission,
    credit_earning,
    promo_cap_for,
)

pytestmark = pytest.mark.unit


def test_constants():
    assert SIGNUP_BONUS == 500.0
    assert PROMO_MAX_PCT == 10.0


@pytest.mark.parametrize("gross", [100, 500, 899, 1000, 2499])
def test_promo_cap_never_exceeds_commission(db, gross):
    cap = promo_cap_for(db, gross)
    # Default commission is 10%, PROMO_MAX_PCT is 10% → cap == 10% of gross,
    # and can never exceed the commission (that would be a loss).
    assert cap == round(gross * 0.10, 2)
    assert cap <= round(gross * 0.10, 2) + 1e-9


def test_charge_commission_no_discount(db, make_user):
    tasker = make_user(role="tasker")
    r = charge_commission(db, tasker.id, 1000.0, "job")
    assert r["commission"] == 100.0
    assert r["net"] == 900.0
    assert tasker.wallet_balance == -100.0  # owes the 10% cash-job fee
    assert tasker.pending_cash_jobs == 1


def test_charge_commission_full_discount_is_break_even(db, make_user):
    """A 10% discount cancels the whole commission: tasker still nets 900,
    the platform simply forgoes its 100 profit — never a loss."""
    tasker = make_user(role="tasker")
    r = charge_commission(db, tasker.id, 1000.0, "job", discount=100.0)
    assert r["commission"] == 0.0        # tasker owes nothing
    assert r["net"] == 900.0             # take-home unchanged
    assert r["collected"] == 900.0       # customer paid 900 cash
    assert tasker.wallet_balance == 0.0  # no fee owed


def test_charge_commission_discount_clamped_to_commission(db, make_user):
    """An over-sized discount is clamped to the commission — profit floors at 0."""
    tasker = make_user(role="tasker")
    r = charge_commission(db, tasker.id, 1000.0, "job", discount=500.0)
    assert r["discount"] == 100.0        # clamped from 500 → 100
    assert r["commission"] == 0.0
    assert r["net"] == 900.0             # tasker never loses out


def test_partial_discount(db, make_user):
    tasker = make_user(role="tasker")
    r = charge_commission(db, tasker.id, 1000.0, "job", discount=40.0)
    assert r["discount"] == 40.0
    assert r["commission"] == 60.0       # 100 fee − 40 covered by bonus
    assert r["net"] == 900.0
    assert tasker.wallet_balance == -60.0


def test_credit_earning_wallet_path(db, make_user):
    tasker = make_user(role="tasker")
    r = credit_earning(db, tasker.id, 1000.0, "job")
    assert r["commission"] == 100.0
    assert r["net"] == 900.0
    assert tasker.wallet_balance == 900.0  # net credited to held-funds wallet
