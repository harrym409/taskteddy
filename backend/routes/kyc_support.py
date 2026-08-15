"""User-facing KYC document upload and support-ticket endpoints.

KYC: taskers upload documents here; admins review them in the panel and then
grant the verified badge. Support: any user can open a ticket from the app's
help centre; admins reply/resolve from the panel (user is notified in-app).
"""
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import KycDocument, SupportTicket, get_db_session
from utils.auth import get_current_user
from utils.uploads import save_upload_file

kyc_router = APIRouter()
support_router = APIRouter()

ALLOWED_DOC_TYPES = {"aadhaar", "pan", "address", "selfie"}


def _doc_to_dict(d: KycDocument) -> dict:
    return {
        "id": d.id,
        "doc_type": d.doc_type,
        "file_url": d.file_url,
        "status": d.status,
        "reason": d.reason,
        "updated_at": d.updated_at.isoformat(),
    }


@kyc_router.post("/documents", status_code=201)
async def upload_kyc_document(
    doc_type: str = Form(...),
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    doc_type = doc_type.strip().lower()
    if doc_type not in ALLOWED_DOC_TYPES:
        raise HTTPException(status_code=400, detail=f"doc_type must be one of {sorted(ALLOWED_DOC_TYPES)}")

    file_url = await save_upload_file(file, "kyc")
    now = datetime.utcnow()

    existing = session.execute(
        select(KycDocument).where(
            KycDocument.user_id == current_user["sub"],
            KycDocument.doc_type == doc_type,
        )
    ).scalar_one_or_none()

    if existing:
        # Re-submission replaces the file and resets review status.
        existing.file_url = file_url
        existing.status = "pending"
        existing.reason = None
        existing.updated_at = now
        doc = existing
    else:
        doc = KycDocument(
            id=str(uuid.uuid4()),
            user_id=current_user["sub"],
            doc_type=doc_type,
            file_url=file_url,
            status="pending",
            created_at=now,
            updated_at=now,
        )
        session.add(doc)

    session.commit()
    session.refresh(doc)
    return _doc_to_dict(doc)


@kyc_router.get("/documents")
def get_my_kyc_documents(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    docs = session.execute(
        select(KycDocument).where(KycDocument.user_id == current_user["sub"])
    ).scalars().all()
    return [_doc_to_dict(d) for d in docs]


class TicketCreate(BaseModel):
    subject: str = Field(..., min_length=3, max_length=200)
    message: str = Field(..., min_length=5, max_length=4000)


@support_router.post("/tickets", status_code=201)
def create_ticket(
    data: TicketCreate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    now = datetime.utcnow()
    ticket = SupportTicket(
        id=str(uuid.uuid4()),
        user_id=current_user["sub"],
        subject=data.subject.strip(),
        message=data.message.strip(),
        status="open",
        created_at=now,
        updated_at=now,
    )
    session.add(ticket)
    session.commit()
    session.refresh(ticket)
    return {
        "id": ticket.id,
        "subject": ticket.subject,
        "status": ticket.status,
        "created_at": ticket.created_at.isoformat(),
        "message": "Ticket created. Our team will get back to you soon.",
    }


@support_router.get("/tickets")
def get_my_tickets(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    tickets = session.execute(
        select(SupportTicket)
        .where(SupportTicket.user_id == current_user["sub"])
        .order_by(SupportTicket.created_at.desc())
    ).scalars().all()
    return [
        {
            "id": t.id,
            "subject": t.subject,
            "message": t.message,
            "status": t.status,
            "reply": t.reply,
            "created_at": t.created_at.isoformat(),
            "updated_at": t.updated_at.isoformat(),
        }
        for t in tickets
    ]
