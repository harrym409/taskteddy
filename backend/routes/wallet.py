from datetime import datetime
import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import Task, Transaction, User, Withdrawal, get_db_session
from models.schemas import WalletTopUpRequest, WithdrawalRequest
from utils.auth import get_current_user

router = APIRouter()


def _transaction_to_dict(txn: Transaction) -> dict:
    return {
        "id": txn.id,
        "user_id": txn.user_id,
        "type": txn.type,
        "amount": float(txn.amount),
        "description": txn.description,
        "task_id": txn.task_id,
        "created_at": txn.created_at,
    }


@router.get("/balance")
def get_balance(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    user = session.get(User, current_user["sub"])
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {"balance": float(user.wallet_balance or 0.0)}


@router.get("/promo")
def get_promo_balance(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """The customer's non-withdrawable TaskTeddy bonus balance and its rules —
    powers the rewards card and the checkout discount."""
    from routes._helpers import PROMO_MAX_PCT, SIGNUP_BONUS
    user = session.get(User, current_user["sub"])
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    email_verified = bool(user.email and user.email_verified_at)
    granted = bool(getattr(user, "signup_bonus_granted", False))
    is_customer = user.user_type == "customer"
    # The welcome bonus is still to be claimed: a customer who hasn't been
    # granted it yet unlocks it by verifying their email.
    bonus_pending = is_customer and not granted
    return {
        "promo_balance": float(user.promo_balance or 0.0),
        "max_discount_pct": PROMO_MAX_PCT,
        "signup_bonus": SIGNUP_BONUS,
        "email_verified": email_verified,
        "name_set": bool((user.name or "").strip()),
        "signup_bonus_granted": granted,
        "bonus_pending": bonus_pending,
    }


@router.post("/topup", status_code=201)
def top_up_wallet(
    data: WalletTopUpRequest,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    user = session.get(User, current_user["sub"])
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    amount = round(float(data.amount), 2)
    bonus = round(amount * 0.05, 2) if amount >= 250 else 0.0
    total_credit = round(amount + bonus, 2)

    user.wallet_balance = round(float(user.wallet_balance or 0.0) + total_credit, 2)
    user.updated_at = datetime.utcnow()

    session.add(
        Transaction(
            id=str(uuid.uuid4()),
            user_id=user.id,
            type="topup",
            amount=total_credit,
            description=f"Wallet top-up ₹{amount:.2f}" + (f" (+₹{bonus:.2f} bonus)" if bonus > 0 else ""),
            task_id=None,
            created_at=datetime.utcnow(),
        )
    )
    session.commit()

    return {
        "amount": amount,
        "bonus": bonus,
        "credited_amount": total_credit,
        "balance": float(user.wallet_balance),
    }


@router.get("/transactions")
def get_transactions(
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    txns = session.execute(
        select(Transaction)
        .where(Transaction.user_id == current_user["sub"])
        .order_by(Transaction.created_at.desc())
        .limit(limit)
    ).scalars().all()
    return [_transaction_to_dict(txn) for txn in txns]


@router.get("/earnings")
def get_earnings(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    earnings = session.execute(
        select(Transaction)
        .where(Transaction.user_id == current_user["sub"], Transaction.type == "earning")
        .order_by(Transaction.created_at.desc())
    ).scalars().all()

    now = datetime.utcnow()
    total_earnings = sum(float(e.amount) for e in earnings)
    this_month_earnings = sum(
        float(e.amount)
        for e in earnings
        if e.created_at and e.created_at.year == now.year and e.created_at.month == now.month
    )

    rows = []
    for earning in earnings:
        row = _transaction_to_dict(earning)
        if earning.task_id:
            task = session.get(Task, earning.task_id)
            if task:
                row["task"] = {
                    "id": task.id,
                    "title": task.title,
                    "category": task.category,
                    "status": task.status,
                }
        rows.append(row)

    return {
        "earnings": rows,
        "total_earnings": total_earnings,
        "this_month_earnings": this_month_earnings,
        "completed_tasks": len(earnings),
    }


@router.post("/withdraw", status_code=201)
def request_withdrawal(
    data: WithdrawalRequest,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    user = session.get(User, current_user["sub"])
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if float(user.wallet_balance or 0.0) < float(data.amount):
        raise HTTPException(status_code=400, detail="Insufficient balance")

    if float(data.amount) < 100:
        raise HTTPException(status_code=400, detail="Minimum withdrawal amount is ₹100")

    withdrawal = Withdrawal(
        id=str(uuid.uuid4()),
        user_id=user.id,
        amount=float(data.amount),
        method=data.method,
        details=data.details,
        status="pending",
        created_at=datetime.utcnow(),
    )
    session.add(withdrawal)

    user.wallet_balance = round(float(user.wallet_balance or 0.0) - float(data.amount), 2)
    user.updated_at = datetime.utcnow()

    session.add(
        Transaction(
            id=str(uuid.uuid4()),
            user_id=user.id,
            type="withdrawal",
            amount=-float(data.amount),
            description=f"Withdrawal via {data.method}",
            task_id=None,
            created_at=datetime.utcnow(),
        )
    )
    session.commit()
    session.refresh(withdrawal)

    return {
        "id": withdrawal.id,
        "user_id": withdrawal.user_id,
        "amount": float(withdrawal.amount),
        "method": withdrawal.method,
        "details": withdrawal.details,
        "status": withdrawal.status,
        "created_at": withdrawal.created_at,
    }


@router.get("/withdrawals")
def get_withdrawals(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    rows = session.execute(
        select(Withdrawal)
        .where(Withdrawal.user_id == current_user["sub"])
        .order_by(Withdrawal.created_at.desc())
    ).scalars().all()

    return [
        {
            "id": row.id,
            "user_id": row.user_id,
            "amount": float(row.amount),
            "method": row.method,
            "details": row.details,
            "status": row.status,
            "created_at": row.created_at,
        }
        for row in rows
    ]
