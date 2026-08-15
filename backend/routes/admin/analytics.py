"""Admin analytics: KPI summary, time-series, category mix, and payout reports."""
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from database import (
    Booking,
    Setting,
    Transaction,
    User,
    Withdrawal,
    get_db_session,
)
from routes.admin.main import get_current_admin

router = APIRouter()

# Booking states that represent realised, billable work.
_DONE_STATES = ("completed", "confirmed", "in_progress")


def _commission_pct(session: Session) -> float:
    row = session.get(Setting, "platform_commission_percent")
    try:
        return float(row.value) if row and row.value is not None else 10.0
    except (TypeError, ValueError):
        return 10.0


def _day_series(session: Session, column, table, extra_where=None, days: int = 30, agg=None):
    """Return {date_iso: value} grouped by day for the last `days` days."""
    since = datetime.utcnow() - timedelta(days=days - 1)
    bucket = func.date_trunc("day", column).label("bucket")
    value = agg if agg is not None else func.count()
    stmt = select(bucket, value).where(column >= since)
    if extra_where is not None:
        stmt = stmt.where(extra_where)
    stmt = stmt.group_by(bucket).order_by(bucket)
    rows = session.execute(stmt).all()
    return {r[0].date().isoformat(): float(r[1] or 0) for r in rows}


def _fill_days(series: dict, days: int = 30) -> list[dict]:
    """Produce a dense day-by-day list, zero-filling gaps."""
    today = datetime.utcnow().date()
    out = []
    for i in range(days - 1, -1, -1):
        d = (today - timedelta(days=i)).isoformat()
        out.append({"date": d, "value": series.get(d, 0)})
    return out


@router.get("/analytics/summary")
def analytics_summary(
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    pct = _commission_pct(session)

    total_customers = session.query(User).filter(User.user_type == "customer").count()
    total_taskers = session.query(User).filter(User.user_type == "tasker").count()
    verified_taskers = (
        session.query(User)
        .filter(User.user_type == "tasker", User.is_verified == True)  # noqa: E712
        .count()
    )
    total_bookings = session.query(Booking).count()
    completed_bookings = (
        session.query(Booking).filter(Booking.status == "completed").count()
    )

    gmv = session.execute(
        select(func.coalesce(func.sum(Booking.total_amount), 0.0)).where(
            Booking.status.in_(_DONE_STATES)
        )
    ).scalar() or 0.0
    platform_revenue = round(float(gmv) * pct / 100.0, 2)

    pending_withdrawals = (
        session.query(Withdrawal).filter(Withdrawal.status == "pending").count()
    )
    pending_payout_amount = session.execute(
        select(func.coalesce(func.sum(Withdrawal.amount), 0.0)).where(
            Withdrawal.status == "pending"
        )
    ).scalar() or 0.0

    # Simple 7-day-vs-prior-7-day growth on new bookings.
    now = datetime.utcnow()
    last7 = session.query(Booking).filter(
        Booking.created_at >= now - timedelta(days=7)
    ).count()
    prev7 = session.query(Booking).filter(
        Booking.created_at >= now - timedelta(days=14),
        Booking.created_at < now - timedelta(days=7),
    ).count()
    growth = round(((last7 - prev7) / prev7 * 100.0), 1) if prev7 else (100.0 if last7 else 0.0)

    return {
        "total_customers": total_customers,
        "total_taskers": total_taskers,
        "verified_taskers": verified_taskers,
        "total_bookings": total_bookings,
        "completed_bookings": completed_bookings,
        "gmv": round(float(gmv), 2),
        "platform_revenue": platform_revenue,
        "commission_percent": pct,
        "pending_withdrawals": pending_withdrawals,
        "pending_payout_amount": round(float(pending_payout_amount), 2),
        "bookings_last_7d": last7,
        "bookings_growth_percent": growth,
    }


@router.get("/analytics/timeseries")
def analytics_timeseries(
    days: int = Query(30, ge=7, le=90),
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    pct = _commission_pct(session)

    bookings = _day_series(session, Booking.created_at, Booking, days=days)
    gmv = _day_series(
        session, Booking.created_at, Booking,
        extra_where=Booking.status.in_(_DONE_STATES),
        days=days, agg=func.coalesce(func.sum(Booking.total_amount), 0.0),
    )
    new_customers = _day_series(
        session, User.created_at, User,
        extra_where=(User.user_type == "customer"), days=days,
    )
    new_taskers = _day_series(
        session, User.created_at, User,
        extra_where=(User.user_type == "tasker"), days=days,
    )

    revenue_filled = [
        {"date": p["date"], "value": round(p["value"] * pct / 100.0, 2)}
        for p in _fill_days(gmv, days)
    ]

    return {
        "days": days,
        "bookings": _fill_days(bookings, days),
        "gmv": _fill_days(gmv, days),
        "revenue": revenue_filled,
        "new_customers": _fill_days(new_customers, days),
        "new_taskers": _fill_days(new_taskers, days),
    }


@router.get("/analytics/categories")
def analytics_categories(
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Booking volume + value grouped by service category (from booking snapshot)."""
    rows = (
        session.execute(
            select(
                Booking.service,
                Booking.total_amount,
                Booking.status,
            )
        )
        .all()
    )
    agg: dict[str, dict] = {}
    for service_json, amount, status in rows:
        cat = "Other"
        if isinstance(service_json, dict):
            cat = service_json.get("category") or "Other"
        entry = agg.setdefault(cat, {"category": cat, "count": 0, "value": 0.0})
        entry["count"] += 1
        if status in _DONE_STATES:
            entry["value"] += float(amount or 0.0)
    out = sorted(agg.values(), key=lambda e: e["count"], reverse=True)
    for e in out:
        e["value"] = round(e["value"], 2)
    return out


@router.get("/analytics/payouts")
def analytics_payouts(
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Withdrawal/payout rollup by status for the finance view."""
    rows = (
        session.execute(
            select(
                Withdrawal.status,
                func.count(),
                func.coalesce(func.sum(Withdrawal.amount), 0.0),
            ).group_by(Withdrawal.status)
        )
        .all()
    )
    by_status = {
        status: {"count": int(n), "amount": round(float(total), 2)}
        for status, n, total in rows
    }
    total_paid = by_status.get("approved", {}).get("amount", 0.0) + \
        by_status.get("completed", {}).get("amount", 0.0)

    # Total earnings credited to taskers (from the ledger).
    total_earnings = session.execute(
        select(func.coalesce(func.sum(Transaction.amount), 0.0)).where(
            Transaction.type == "earning"
        )
    ).scalar() or 0.0

    return {
        "by_status": by_status,
        "total_paid_out": round(float(total_paid), 2),
        "total_tasker_earnings": round(float(total_earnings), 2),
    }
