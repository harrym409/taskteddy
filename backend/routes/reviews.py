from datetime import datetime
import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import and_, func, select
from sqlalchemy.orm import Session

from database import Review, Task, User, get_db_session
from models.schemas import ReviewCreate
from routes._helpers import safe_user
from utils.auth import get_current_user

router = APIRouter()


def _review_to_dict(review: Review) -> dict:
    return {
        "id": review.id,
        "task_id": review.task_id,
        "reviewer_id": review.reviewer_id,
        "reviewed_user_id": review.reviewed_user_id,
        "rating": float(review.rating),
        "comment": review.comment,
        "created_at": review.created_at,
    }


@router.post("/", status_code=201)
def create_review(
    data: ReviewCreate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    task = session.get(Task, data.task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status != "completed":
        raise HTTPException(status_code=400, detail="Task must be completed to leave a review")

    if current_user["sub"] not in [task.posted_by, task.assigned_to]:
        raise HTTPException(status_code=403, detail="Not authorized")

    existing = session.execute(
        select(Review).where(
            and_(
                Review.task_id == data.task_id,
                Review.reviewer_id == current_user["sub"],
                Review.reviewed_user_id == data.reviewed_user_id,
            )
        )
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="You have already reviewed this user for this task")

    review = Review(
        id=str(uuid.uuid4()),
        task_id=data.task_id,
        reviewer_id=current_user["sub"],
        reviewed_user_id=data.reviewed_user_id,
        rating=float(data.rating),
        comment=data.comment,
        created_at=datetime.utcnow(),
    )
    session.add(review)
    session.commit()

    stats = session.execute(
        select(func.avg(Review.rating), func.count(Review.id)).where(Review.reviewed_user_id == data.reviewed_user_id)
    ).one()
    avg_rating = float(stats[0] or 0.0)
    total_count = int(stats[1] or 0)

    target_user = session.get(User, data.reviewed_user_id)
    if target_user:
        target_user.rating = round(avg_rating, 1)
        target_user.total_reviews = total_count
        target_user.updated_at = datetime.utcnow()
        session.commit()

    session.refresh(review)
    return _review_to_dict(review)


@router.get("/user/{user_id}")
def get_user_reviews(user_id: str, limit: int = 20, session: Session = Depends(get_db_session)):
    reviews = session.execute(
        select(Review)
        .where(Review.reviewed_user_id == user_id)
        .order_by(Review.created_at.desc())
        .limit(limit)
    ).scalars().all()

    payload = []
    for review in reviews:
        row = _review_to_dict(review)
        row["reviewer"] = safe_user(session, review.reviewer_id)
        payload.append(row)
    return payload
