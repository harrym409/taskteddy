from datetime import datetime
import re
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import cast, func, select, String
from sqlalchemy.orm import Session

from database import Conversation, Message, Task, User, get_db_session
from routes._helpers import safe_user, notify_user
from utils.auth import get_current_user
from utils.uploads import save_upload_file

router = APIRouter()

# Anti-disintermediation guard: keep contact details out of chat so the two
# parties can't take the deal off-platform. Blocks emails and phone-number-length
# digit runs (the app only sends curated presets, so this never trips them).
_EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+\.\w+")


def _contains_contact_info(text: str) -> bool:
    if not text:
        return False
    if _EMAIL_RE.search(text):
        return True
    compact = re.sub(r"[\s\-\.\(\)]", "", text)
    return re.search(r"\d{10,}", compact) is not None


class LocationPayload(BaseModel):
    lat: float
    lng: float
    label: str = Field(default="", max_length=60)
    address: str = Field(default="", max_length=300)
    landmark: str | None = Field(default=None, max_length=200)


class MessagePayload(BaseModel):
    text: str = Field(default="")
    image_url: str | None = None
    location: LocationPayload | None = None


def _clean_location(loc: LocationPayload) -> dict:
    """Validate a shared location and strip any smuggled contact info from its
    free-text fields (address/label/landmark) so the pin stays on-platform."""
    if not (-90.0 <= loc.lat <= 90.0 and -180.0 <= loc.lng <= 180.0):
        raise HTTPException(status_code=400, detail="Invalid location coordinates.")
    label = (loc.label or "").strip()[:60]
    address = (loc.address or "").strip()[:300]
    landmark = (loc.landmark or "").strip()[:200] if loc.landmark else ""
    for part in (label, address, landmark):
        if _contains_contact_info(part):
            raise HTTPException(
                status_code=400,
                detail="For everyone's safety, contact details can't be shared "
                       "in a location. Please keep coordination on TaskTeddy.",
            )
    return {
        "lat": loc.lat,
        "lng": loc.lng,
        "label": label or "Location",
        "address": address,
        "landmark": landmark or None,
    }


def _ensure_chat_open(session: Session, conv: Conversation) -> None:
    """Reject new messages once the task's job is finished — a completed or
    cancelled task closes its chat so the two parties don't keep coordinating
    off-platform afterwards."""
    if conv.task_id:
        task = session.get(Task, conv.task_id)
        if task and task.status in ("completed", "cancelled"):
            raise HTTPException(
                status_code=403,
                detail="This chat is closed because the task is finished.",
            )


def _conversation_to_dict(session: Session, conv: Conversation, current_user_id: str) -> dict:
    participants = conv.participants or []
    other_user_id = next((p for p in participants if p != current_user_id), None)
    other_user = safe_user(session, other_user_id)

    task_payload = None
    closed = False
    if conv.task_id:
        task = session.get(Task, conv.task_id)
        if task:
            task_payload = {
                "id": task.id,
                "title": task.title,
                "category": task.category,
                "budget": float(task.budget),
                "status": task.status,
            }
            # A finished job closes its chat — no new messages allowed.
            closed = task.status in ("completed", "cancelled")

    from database import Message
    unread = session.execute(
        select(func.count(Message.id)).where(
            Message.conversation_id == conv.id,
            Message.sender_id != current_user_id,
            Message.is_read == False,  # noqa: E712
        )
    ).scalar() or 0

    return {
        "id": conv.id,
        "participants": participants,
        "task_id": conv.task_id,
        "last_message": conv.last_message or "",
        "last_message_at": conv.last_message_at,
        "created_at": conv.created_at,
        "other_user": other_user,
        "task": task_payload,
        "unread_count": int(unread),
        "closed": closed,
    }


@router.get("/conversations")
def get_conversations(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    user_id = current_user["sub"]
    # Use explicit JSON containment query for PostgreSQL
    rows = session.execute(
        select(Conversation)
        .where(cast(Conversation.participants, String).contains(f'"{user_id}"'))
        .order_by(Conversation.last_message_at.desc())
    ).scalars().all()

    return [_conversation_to_dict(session, conv, user_id) for conv in rows]


@router.get("/unread-count")
def chat_unread_count(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Total unread chat messages across all of the user's conversations."""
    from database import Message
    user_id = current_user["sub"]
    convo_ids = session.execute(
        select(Conversation.id).where(
            cast(Conversation.participants, String).contains(f'"{user_id}"')
        )
    ).scalars().all()
    if not convo_ids:
        return {"unread_count": 0}
    total = session.execute(
        select(func.count(Message.id)).where(
            Message.conversation_id.in_(convo_ids),
            Message.sender_id != user_id,
            Message.is_read == False,  # noqa: E712
        )
    ).scalar() or 0
    return {"unread_count": int(total)}


@router.post("/conversations")
def create_conversation(
    other_user_id: str,
    task_id: str | None = None,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    if not session.get(User, other_user_id):
        raise HTTPException(status_code=404, detail="User not found")

    current_user_id = current_user["sub"]
    # Use explicit JSON containment query for PostgreSQL
    existing_candidates = session.execute(
        select(Conversation)
        .where(cast(Conversation.participants, String).contains(f'"{current_user_id}"'))
    ).scalars().all()

    # A conversation is scoped to a single task, so the same two people chatting
    # about a different task get a *separate* thread. Match participants AND task.
    for conv in existing_candidates:
        members = set(conv.participants or [])
        if members == {current_user_id, other_user_id} and conv.task_id == task_id:
            return _conversation_to_dict(session, conv, current_user_id)

    now = datetime.utcnow()
    conversation = Conversation(
        id=str(uuid.uuid4()),
        participants=[current_user_id, other_user_id],
        task_id=task_id,
        last_message="",
        last_message_at=now,
        created_at=now,
    )
    session.add(conversation)
    session.commit()
    session.refresh(conversation)

    return _conversation_to_dict(session, conversation, current_user_id)


@router.get("/conversations/{conversation_id}/messages")
def get_messages(
    conversation_id: str,
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    conversation = session.get(Conversation, conversation_id)
    if not conversation or current_user["sub"] not in (conversation.participants or []):
        raise HTTPException(status_code=403, detail="Not authorized")

    messages = session.execute(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.desc())
        .limit(limit)
    ).scalars().all()

    # Opening a conversation marks the other side's messages as read.
    marked = False
    for msg in messages:
        if msg.sender_id != current_user["sub"] and not msg.is_read:
            msg.is_read = True
            marked = True
    if marked:
        session.commit()

    payload = [
        {
            "id": msg.id,
            "conversation_id": msg.conversation_id,
            "sender_id": msg.sender_id,
            "text": msg.text or "",
            "image_url": msg.image_url,
            "location": msg.location,
            "is_read": bool(msg.is_read),
            "created_at": msg.created_at,
        }
        for msg in messages
    ]
    return list(reversed(payload))


@router.post("/conversations/{conversation_id}/messages", status_code=201)
def send_message(
    conversation_id: str,
    data: MessagePayload,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    conversation = session.get(Conversation, conversation_id)
    if not conversation or current_user["sub"] not in (conversation.participants or []):
        raise HTTPException(status_code=403, detail="Not authorized")
    _ensure_chat_open(session, conversation)

    now = datetime.utcnow()
    text = (data.text or "").strip()
    if _contains_contact_info(text):
        raise HTTPException(
            status_code=400,
            detail="For everyone's safety, sharing phone numbers or contact "
                   "details in chat isn't allowed. Please keep coordination on TaskTeddy.",
        )

    location = _clean_location(data.location) if data.location else None

    message = Message(
        id=str(uuid.uuid4()),
        conversation_id=conversation_id,
        sender_id=current_user["sub"],
        sender_type=current_user.get("role", "customer"),
        text=text,
        image_url=data.image_url,
        location=location,
        is_read=False,
        created_at=now,
    )
    session.add(message)

    if location:
        preview = "📍 Shared a location"
    elif text:
        preview = text[:100]
    else:
        preview = "Photo"
    conversation.last_message = preview
    conversation.last_message_at = now
    # Notify the other participant of the new message.
    recipients = [p for p in (conversation.participants or []) if p != current_user["sub"]]
    sender = session.get(User, current_user["sub"])
    sender_name = sender.name if sender else "Someone"
    notif_body = ("Shared a location" if location
                  else (text[:120] if text else "Sent a photo"))
    for rid in recipients:
        notify_user(session, rid, f"Message from {sender_name}",
                    notif_body, emoji="💬",
                    notif_type="chat", related_id=conversation_id)
    session.commit()
    session.refresh(message)

    return {
        "id": message.id,
        "conversation_id": message.conversation_id,
        "sender_id": message.sender_id,
        "text": message.text or "",
        "image_url": message.image_url,
        "location": message.location,
        "is_read": bool(message.is_read),
        "created_at": message.created_at,
    }


@router.post("/conversations/{conversation_id}/messages/image")
async def send_image_message(
    conversation_id: str,
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    conversation = session.get(Conversation, conversation_id)
    if not conversation or current_user["sub"] not in (conversation.participants or []):
        raise HTTPException(status_code=403, detail="Not authorized")
    _ensure_chat_open(session, conversation)

    image_url = await save_upload_file(file, "messages")
    now = datetime.utcnow()
    message = Message(
        id=str(uuid.uuid4()),
        conversation_id=conversation_id,
        sender_id=current_user["sub"],
        sender_type=current_user.get("role", "customer"),
        text="",
        image_url=image_url,
        is_read=False,
        created_at=now,
    )
    session.add(message)

    conversation.last_message = "Photo"
    conversation.last_message_at = now
    session.commit()
    session.refresh(message)

    return {
        "id": message.id,
        "conversation_id": message.conversation_id,
        "sender_id": message.sender_id,
        "text": "",
        "image_url": message.image_url,
        "is_read": bool(message.is_read),
        "created_at": message.created_at,
    }


@router.patch("/conversations/{conversation_id}/read")
def mark_as_read(
    conversation_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    conversation = session.get(Conversation, conversation_id)
    if not conversation or current_user["sub"] not in (conversation.participants or []):
        raise HTTPException(status_code=403, detail="Not authorized")

    rows = session.execute(
        select(Message).where(
            Message.conversation_id == conversation_id,
            Message.sender_id != current_user["sub"],
        )
    ).scalars().all()

    for row in rows:
        row.is_read = True
    session.commit()
    return {"message": "Messages marked as read"}
