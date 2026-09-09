"""Integration: the promo checkout flow — apply, remove, refund, no-loss."""
import pytest

pytestmark = pytest.mark.integration


def _assigned_task(make_user, make_task, make_application, promo_balance=500.0,
                   budget=1000.0, otp="1234"):
    customer = make_user(role="customer", promo_balance=promo_balance)
    tasker = make_user(role="tasker")
    task = make_task(customer.id, budget=budget, status="assigned",
                     assigned_to=tasker.id, otp=otp)
    make_application(task.id, tasker.id, bid_amount=budget, status="accepted")
    return customer, tasker, task


def test_checkout_summary(client, auth_as, make_user, make_task, make_application):
    customer, tasker, task = _assigned_task(make_user, make_task, make_application)
    auth_as(customer.id, "customer")
    r = client.get(f"/api/tasks/{task.id}/checkout")
    assert r.status_code == 200, r.text
    s = r.json()
    assert s["amount"] == 1000.0
    assert s["max_promo_for_task"] == 100.0     # 10% cap
    assert s["promo_available_now"] == 100.0
    assert s["net_payable"] == 1000.0           # nothing applied yet
    assert s["can_apply"] is True


def test_apply_bonus_deducts_and_locks(client, db, auth_as, make_user, make_task,
                                       make_application):
    customer, tasker, task = _assigned_task(make_user, make_task, make_application)
    auth_as(customer.id, "customer")
    r = client.post(f"/api/tasks/{task.id}/apply-bonus")
    assert r.status_code == 200, r.text
    s = r.json()
    assert s["promo_applied"] == 100.0
    assert s["net_payable"] == 900.0
    db.refresh(customer)
    db.refresh(task)
    assert customer.promo_balance == 400.0      # 500 − 100
    assert task.promo_discount == 100.0


def test_apply_is_capped_by_balance(client, db, auth_as, make_user, make_task,
                                    make_application):
    # Only ₹30 of bonus left, task cap is ₹100 → only ₹30 applies.
    customer, tasker, task = _assigned_task(
        make_user, make_task, make_application, promo_balance=30.0
    )
    auth_as(customer.id, "customer")
    s = client.post(f"/api/tasks/{task.id}/apply-bonus").json()
    assert s["promo_applied"] == 30.0
    assert s["net_payable"] == 970.0
    db.refresh(customer)
    assert customer.promo_balance == 0.0


def test_remove_bonus_refunds(client, db, auth_as, make_user, make_task,
                              make_application):
    customer, tasker, task = _assigned_task(make_user, make_task, make_application)
    auth_as(customer.id, "customer")
    client.post(f"/api/tasks/{task.id}/apply-bonus")
    r = client.post(f"/api/tasks/{task.id}/remove-bonus")
    assert r.status_code == 200
    assert r.json()["promo_applied"] == 0.0
    db.refresh(customer)
    db.refresh(task)
    assert customer.promo_balance == 500.0      # fully refunded
    assert task.promo_discount == 0.0


def test_non_owner_cannot_checkout(client, auth_as, make_user, make_task,
                                   make_application):
    customer, tasker, task = _assigned_task(make_user, make_task, make_application)
    stranger = make_user(role="customer")
    auth_as(stranger.id, "customer")
    r = client.get(f"/api/tasks/{task.id}/checkout")
    assert r.status_code == 403


def test_cancel_refunds_applied_bonus(client, db, auth_as, make_user, make_task,
                                      make_application):
    customer, tasker, task = _assigned_task(make_user, make_task, make_application)
    auth_as(customer.id, "customer")
    client.post(f"/api/tasks/{task.id}/apply-bonus")
    r = client.delete(f"/api/customer/tasks/{task.id}")
    assert r.status_code == 200, r.text
    db.refresh(customer)
    assert customer.promo_balance == 500.0      # bonus returned on cancel
