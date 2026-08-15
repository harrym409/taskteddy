"""Trust & safety: report a user, block/unblock, list blocks."""
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import User, UserBlock, UserReport, get_db_session
from routes._helpers import sanitize_text, user_to_public
from utils.auth import get_current_user

router = APIRouter()

_REASONS = {
    "inappropriate_behaviour",
    "no_show",
    "safety_concern",
    "fraud_or_scam",
    "poor_quality",
    "spam",
    "other",
}


class ReportIn(BaseModel):
    reported_id: str
    reason: str
    detail: str | None = None
    task_id: str | None = None

    @field_validator("reported_id")
    @classmethod
    def _not_blank(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("reported_id is required")
        return v.strip()


class BlockIn(BaseModel):
    blocked_id: str


def blocked_user_ids(session: Session, user_id: str) -> set[str]:
    """Ids the user has blocked OR who have blocked the user — hidden both ways."""
    rows = session.execute(
        select(UserBlock.blocker_id, UserBlock.blocked_id).where(
            (UserBlock.blocker_id == user_id) | (UserBlock.blocked_id == user_id)
        )
    ).all()
    out: set[str] = set()
    for blocker, blocked in rows:
        out.add(blocked if blocker == user_id else blocker)
    return out


@router.post("/report", status_code=201)
def report_user(
    body: ReportIn,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    if body.reported_id == current_user["sub"]:
        raise HTTPException(status_code=400, detail="You cannot report yourself")
    if session.get(User, body.reported_id) is None:
        raise HTTPException(status_code=404, detail="User not found")

    reason = body.reason if body.reason in _REASONS else "other"
    report = UserReport(
        id=f"RPT_{uuid.uuid4().hex[:20]}",
        reporter_id=current_user["sub"],
        reported_id=body.reported_id,
        task_id=(body.task_id or None),
        reason=reason,
        detail=sanitize_text(body.detail, 1000) if body.detail else None,
        status="open",
        created_at=datetime.utcnow(),
    )
    session.add(report)
    session.commit()
    return {"message": "Report submitted. Our team will review it.", "id": report.id}


@router.get("/blocks")
def list_blocks(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    rows = (
        session.execute(
            select(UserBlock)
            .where(UserBlock.blocker_id == current_user["sub"])
            .order_by(UserBlock.created_at.desc())
        )
        .scalars()
        .all()
    )
    out = []
    for b in rows:
        u = session.get(User, b.blocked_id)
        out.append({
            "id": b.id,
            "blocked_id": b.blocked_id,
            "created_at": b.created_at,
            "user": user_to_public(u, include_wallet=False) if u else None,
        })
    return out


@router.post("/block", status_code=201)
def block_user(
    body: BlockIn,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    if body.blocked_id == current_user["sub"]:
        raise HTTPException(status_code=400, detail="You cannot block yourself")
    if session.get(User, body.blocked_id) is None:
        raise HTTPException(status_code=404, detail="User not found")

    existing = session.execute(
        select(UserBlock).where(
            UserBlock.blocker_id == current_user["sub"],
            UserBlock.blocked_id == body.blocked_id,
        )
    ).scalar_one_or_none()
    if existing is not None:
        return {"message": "Already blocked", "id": existing.id}

    block = UserBlock(
        id=f"BLK_{uuid.uuid4().hex[:20]}",
        blocker_id=current_user["sub"],
        blocked_id=body.blocked_id,
        created_at=datetime.utcnow(),
    )
    session.add(block)
    session.commit()
    return {"message": "User blocked", "id": block.id}


@router.delete("/block/{blocked_id}", status_code=204)
def unblock_user(
    blocked_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    block = session.execute(
        select(UserBlock).where(
            UserBlock.blocker_id == current_user["sub"],
            UserBlock.blocked_id == blocked_id,
        )
    ).scalar_one_or_none()
    if block is not None:
        session.delete(block)
        session.commit()
    return None
