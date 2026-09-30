from datetime import datetime
import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import and_, select
from sqlalchemy.orm import Session

from database import Application, Setting, Task, User, get_db_session
from models.schemas import ApplicationCreate
from routes._helpers import safe_user, task_to_response, notify_user
from utils.auth import get_current_user

router = APIRouter()


def _verification_required(session: Session) -> bool:
    """Whether taskers must be KYC-verified before applying. Defaults to True;
    admins can relax it via the `require_tasker_verification` setting."""
    row = session.get(Setting, "require_tasker_verification")
    if row is None or row.value is None:
        return True
    return str(row.value).strip().lower() in ("1", "true", "yes", "on")


def _application_to_dict(app: Application) -> dict:
    return {
        "id": app.id,
        "task_id": app.task_id,
        "applicant_id": app.applicant_id,
        "bid_amount": float(app.bid_amount),
        "cover_letter": app.cover_letter,
        "status": app.status,
        "created_at": app.created_at,
        "updated_at": app.updated_at,
    }


@router.post("", status_code=201)
def create_application(
    data: ApplicationCreate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    # Safety gate: only KYC-verified taskers may apply (admin-toggleable).
    applicant = session.get(User, current_user["sub"])
    if applicant is not None and _verification_required(session) and not applicant.is_verified:
        raise HTTPException(
            status_code=403,
            detail="Please complete verification before applying to tasks.",
        )

    task = session.get(Task, data.task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status != "open":
        raise HTTPException(status_code=400, detail="Task is not open for applications")

    existing = session.execute(
        select(Application).where(
            and_(Application.task_id == data.task_id, Application.applicant_id == current_user["sub"])
        )
    ).scalar_one_or_none()
    if existing:
        if existing.status == "withdrawn":
            # Re-applying after a withdrawal resubmits the same application.
            existing.status = "pending"
            existing.bid_amount = float(data.bid_amount)
            existing.cover_letter = data.cover_letter
            existing.updated_at = datetime.utcnow()
            task.applicants_count = (task.applicants_count or 0) + 1
            session.commit()
            session.refresh(existing)
            return {
                "id": existing.id,
                "task_id": existing.task_id,
                "bid_amount": float(existing.bid_amount),
                "status": existing.status,
                "message": "Application resubmitted",
            }
        raise HTTPException(status_code=400, detail="You have already applied to this task")

    now = datetime.utcnow()
    application = Application(
        id=str(uuid.uuid4()),
        task_id=data.task_id,
        applicant_id=current_user["sub"],
        bid_amount=float(data.bid_amount),
        cover_letter=data.cover_letter,
        status="pending",
        created_at=now,
        updated_at=now,
    )
    session.add(application)
    task.applicants_count = int(task.applicants_count or 0) + 1
    task.updated_at = now
    notify_user(session, task.posted_by, "New Application",
                f"A tasker bid ₹{float(data.bid_amount):.0f} on '{task.title}'.",
                emoji="📥", notif_type="bid", related_id=task.id)
    session.commit()
    session.refresh(application)
    # Live push: nudge the customer's task-detail to refetch offers instantly.
    try:
        from realtime import notify_new_bid
        notify_new_bid(task.posted_by, data.task_id)
    except Exception:
        pass
    return _application_to_dict(application)


@router.get("/my-applications")
def get_my_applications(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    applications = session.execute(
        select(Application)
        .where(Application.applicant_id == current_user["sub"])
        .order_by(Application.created_at.desc())
    ).scalars().all()

    response: list[dict] = []
    for app in applications:
        row = _application_to_dict(app)
        task = session.get(Task, app.task_id)
        if task:
            task_payload = task_to_response(session, task)
            row["task"] = task_payload
            if task.posted_by:
                row.setdefault("task", {})["posted_by_info"] = safe_user(session, task.posted_by)
        response.append(row)
    return response


@router.get("/task/{task_id}")
def get_task_applications(
    task_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.posted_by != current_user["sub"]:
        raise HTTPException(status_code=403, detail="Not authorized")

    applications = session.execute(
        select(Application)
        .where(Application.task_id == task_id)
        .order_by(Application.created_at.desc())
    ).scalars().all()

    payload = []
    for app in applications:
        row = _application_to_dict(app)
        row["applicant"] = safe_user(session, app.applicant_id)
        payload.append(row)
    return payload


import random

@router.patch("/{application_id}/accept")
def accept_application(
    application_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    application = session.get(Application, application_id)
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")

    task = session.get(Task, application.task_id)
    if not task or task.posted_by != current_user["sub"]:
        raise HTTPException(status_code=403, detail="Not authorized")

    now = datetime.utcnow()
    application.status = "accepted"
    application.updated_at = now

    task.status = "assigned"
    task.assigned_to = application.applicant_id
    task.updated_at = now
    if not task.completion_otp:
        # 6-digit completion OTP (matches login/email OTPs and both apps' UI).
        task.completion_otp = str(random.randint(100000, 999999))

    others = session.execute(
        select(Application).where(
            and_(Application.task_id == application.task_id, Application.id != application_id)
        )
    ).scalars().all()
    for other in others:
        other.status = "rejected"
        other.updated_at = now

    notify_user(session, application.applicant_id, "You Got the Job!",
                f"Your bid on '{task.title}' was accepted. Chat with the customer to coordinate.",
                emoji="🎉", notif_type="task", related_id=task.id)
    for other in others:
        notify_user(session, other.applicant_id, "Application Update",
                    f"'{task.title}' has been assigned to another tasker.",
                    emoji="📋", notif_type="applied")
    session.commit()
    # Live push: refresh every affected tasker's "My Applications" instantly,
    # and the task is no longer open so nudge the browse feeds too.
    try:
        from realtime import notify_applications_changed, notify_new_task
        notify_applications_changed(application.applicant_id)
        for other in others:
            notify_applications_changed(other.applicant_id)
        notify_new_task()
    except Exception:
        pass
    return {"message": "Application accepted successfully"}


@router.patch("/{application_id}/reject")
def reject_application(
    application_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    application = session.get(Application, application_id)
    if not application:
        raise HTTPException(status_code=404, detail="Application not found")

    task = session.get(Task, application.task_id)
    if not task or task.posted_by != current_user["sub"]:
        raise HTTPException(status_code=403, detail="Not authorized")

    application.status = "rejected"
    application.updated_at = datetime.utcnow()
    session.commit()

    return {"message": "Application rejected"}
