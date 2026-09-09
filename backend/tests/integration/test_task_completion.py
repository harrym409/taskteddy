"""Integration: OTP-verified completion + the promo/commission settlement.

The crown-jewel invariant: with a bonus applied, the tasker is still paid in
full and the platform never takes a loss.
"""
import pytest

pytestmark = pytest.mark.integration


def _ready_task(make_user, make_task, make_application, promo_discount=0.0,
                budget=1000.0, otp="1234"):
    customer = make_user(role="customer")
    tasker = make_user(role="tasker")
    task = make_task(customer.id, budget=budget, status="assigned",
                     assigned_to=tasker.id, promo_discount=promo_discount, otp=otp)
    make_application(task.id, tasker.id, bid_amount=budget, status="accepted")
    return customer, tasker, task


def test_complete_cash_no_bonus(client, db, auth_as, make_user, make_task,
                                make_application):
    customer, tasker, task = _ready_task(make_user, make_task, make_application)
    auth_as(tasker.id, "tasker")
    r = client.patch(
        f"/api/tasker/tasks/{task.id}/complete",
        params={"completion_otp": "1234", "payment_method": "cash"},
    )
    assert r.status_code == 200, r.text
    earning = r.json()["earning"]
    assert earning["net"] == 900.0
    assert earning["commission"] == 100.0
    db.refresh(tasker)
    assert tasker.wallet_balance == -100.0     # owes the cash-job fee
    assert tasker.pending_cash_jobs == 1


def test_complete_cash_with_full_bonus_is_no_loss(client, db, auth_as, make_user,
                                                  make_task, make_application):
    customer, tasker, task = _ready_task(
        make_user, make_task, make_application, promo_discount=100.0
    )
    auth_as(tasker.id, "tasker")
    r = client.patch(
        f"/api/tasker/tasks/{task.id}/complete",
        params={"completion_otp": "1234", "payment_method": "cash"},
    )
    assert r.status_code == 200, r.text
    earning = r.json()["earning"]
    assert earning["net"] == 900.0             # tasker take-home UNCHANGED
    assert earning["commission"] == 0.0        # platform forwent its fee
    assert earning["collected"] == 900.0       # customer paid 900 cash
    db.refresh(tasker)
    assert tasker.wallet_balance == 0.0        # owes nothing → never a loss


def test_complete_rejects_wrong_otp(client, auth_as, make_user, make_task,
                                    make_application):
    customer, tasker, task = _ready_task(make_user, make_task, make_application)
    auth_as(tasker.id, "tasker")
    r = client.patch(
        f"/api/tasker/tasks/{task.id}/complete",
        params={"completion_otp": "9999", "payment_method": "cash"},
    )
    assert r.status_code == 400


def test_complete_forbidden_for_other_tasker(client, auth_as, make_user, make_task,
                                             make_application):
    customer, tasker, task = _ready_task(make_user, make_task, make_application)
    other = make_user(role="tasker")
    auth_as(other.id, "tasker")
    r = client.patch(
        f"/api/tasker/tasks/{task.id}/complete",
        params={"completion_otp": "1234", "payment_method": "cash"},
    )
    assert r.status_code == 404  # not this tasker's task
