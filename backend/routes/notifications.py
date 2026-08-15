from datetime import datetime
import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import DeviceToken, Notification, get_db_session
from utils.auth import get_current_user
from utils.push import send_push_detailed

logger = logging.getLogger("taskteddy.notifications")

router = APIRouter()


class DeviceTokenRequest(BaseModel):
    token: str = Field(..., min_length=10, max_length=512)
    platform: str | None = Field(default=None, max_length=20)


@router.post("/device-tokens")
def register_device_token(
    data: DeviceTokenRequest,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Register (or re-associate) an FCM device token for the current user."""
    existing = session.execute(
        select(DeviceToken).where(DeviceToken.token == data.token)
    ).scalar_one_or_none()
    now = datetime.utcnow()
    if existing:
        existing.user_id = current_user["sub"]
        existing.platform = data.platform
        existing.updated_at = now
    else:
        session.add(
            DeviceToken(
                id=str(uuid.uuid4()),
                user_id=current_user["sub"],
                token=data.token,
                platform=data.platform,
                created_at=now,
                updated_at=now,
            )
        )
    session.commit()
    return {"message": "Device token registered"}


@router.delete("/device-tokens")
def unregister_device_token(
    data: DeviceTokenRequest,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Remove a device token (on logout / uninstall)."""
    session.query(DeviceToken).filter(
        DeviceToken.token == data.token,
        DeviceToken.user_id == current_user["sub"],
    ).delete()
    session.commit()
    return {"message": "Device token removed"}


def _notification_to_dict(item: Notification) -> dict:
    return {
        "id": item.id,
        "user_id": item.user_id,
        "title": item.title,
        "body": item.body,
        "emoji": item.emoji,
        "type": item.type,
        "related_id": item.related_id,
        "is_read": bool(item.is_read),
        "created_at": item.created_at,
    }


@router.get("/")
def get_notifications(
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    rows = session.execute(
        select(Notification)
        .where(Notification.user_id == current_user["sub"])
        .order_by(Notification.created_at.desc())
        .limit(limit)
    ).scalars().all()
    return [_notification_to_dict(row) for row in rows]


@router.get("/unread-count")
def get_unread_count(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    count = session.execute(
        select(Notification)
        .where(Notification.user_id == current_user["sub"], Notification.is_read.is_(False))
    ).scalars().all()
    return {"unread_count": len(count)}


@router.patch("/{notification_id}/read")
def mark_as_read(
    notification_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    item = session.execute(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == current_user["sub"],
        )
    ).scalar_one_or_none()

    if not item:
        raise HTTPException(status_code=404, detail="Notification not found")

    item.is_read = True
    session.commit()
    return {"message": "Notification marked as read"}


@router.patch("/mark-all-read")
def mark_all_read(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    rows = session.execute(
        select(Notification).where(
            Notification.user_id == current_user["sub"],
            Notification.is_read.is_(False),
        )
    ).scalars().all()
    for row in rows:
        row.is_read = True
    session.commit()
    return {"message": "All notifications marked as read"}


@router.delete("/{notification_id}")
def delete_notification(
    notification_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    item = session.execute(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == current_user["sub"],
        )
    ).scalar_one_or_none()

    if not item:
        raise HTTPException(status_code=404, detail="Notification not found")

    session.delete(item)
    session.commit()
    return {"message": "Notification deleted"}


async def create_notification(
    session: Session,
    user_id: str,
    title: str,
    body: str,
    emoji: str,
    notification_type: str,
    related_id: str | None = None,
):
    notification = Notification(
        id=str(uuid.uuid4()),
        user_id=user_id,
        title=title,
        body=body,
        emoji=emoji,
        type=notification_type,
        related_id=related_id,
        is_read=False,
        created_at=datetime.utcnow(),
    )
    session.add(notification)
    session.commit()
    session.refresh(notification)

    # Best-effort push delivery. Never let a push failure break the caller.
    try:
        tokens_rows = session.execute(
            select(DeviceToken).where(DeviceToken.user_id == user_id)
        ).scalars().all()
        tokens = [r.token for r in tokens_rows]
        if tokens:
            _, invalid = send_push_detailed(
                tokens,
                title=f"{emoji} {title}".strip(),
                body=body,
                data={"type": notification_type, "related_id": related_id or ""},
            )
            # Prune tokens FCM reported as dead so we stop targeting them.
            for bad in invalid:
                session.query(DeviceToken).filter(DeviceToken.token == bad).delete()
            if invalid:
                session.commit()
    except Exception:
        logger.exception("Push delivery failed for notification %s", notification.id)

    return notification
