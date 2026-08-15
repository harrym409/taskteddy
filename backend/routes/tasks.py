from datetime import datetime
import re
import uuid


from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import select, and_
from sqlalchemy.orm import Session

from database import Task, User, generate_task_id, get_db_session
from models.schemas import TaskCreate
from routes._helpers import task_to_response
from utils.auth import get_current_user, get_current_user_optional
from utils.file_storage import (
    MAX_FILE_SIZE,
    MAX_FILES,
    allowed_file,
    validate_mime_type,
)

router = APIRouter()

# Budget presets for task creation
BUDGET_PRESETS = [499, 899, 1499, 2499]


@router.get("/posting-meta")
def get_posting_meta(category: str | None = Query(default=None)):
    """Get metadata for task posting form."""
    return {
        "budget_presets": BUDGET_PRESETS,
    }


@router.post("/budget-insights")
def get_budget_insights(
    category: str | None = None,
    location: str | None = None,
    budget: float | None = None,
    urgency: str | None = None,
    expected_hours: float | None = None,
):
    """Get budget insights for task pricing."""
    insights = {
        "note": "Budget insights based on market rates",
        "suggested_budget": 999,
        "price_range": {
            "min": 499,
            "max": 2499,
        },
    }
    
    if category:
        category_prices = {
            "cleaning": {"min": 299, "max": 1999, "avg": 799},
            "repair": {"min": 499, "max": 4999, "avg": 1499},
            "delivery": {"min": 99, "max": 999, "avg": 399},
            "errands": {"min": 199, "max": 999, "avg": 499},
            "moving": {"min": 999, "max": 9999, "avg": 2999},
            "cooking": {"min": 499, "max": 2999, "avg": 999},
            "tutoring": {"min": 299, "max": 1499, "avg": 599},
            "tech": {"min": 499, "max": 4999, "avg": 1299},
            "photography": {"min": 999, "max": 7999, "avg": 2999},
            "painting": {"min": 999, "max": 7999, "avg": 2999},
            "gardening": {"min": 299, "max": 1999, "avg": 799},
            "other": {"min": 499, "max": 2499, "avg": 999},
        }
        if category in category_prices:
            insights = {
                "note": f"Budget range for {category} services",
                "suggested_budget": category_prices[category]["avg"],
                "price_range": {
                    "min": category_prices[category]["min"],
                    "max": category_prices[category]["max"],
                },
            }
    
    return insights


# URL validation patterns for image URLs (supports both local and remote)
LOCAL_IMAGE_PATTERN = re.compile(
    r'^/uploads/tasks/[a-zA-Z0-9_/-]+\.[a-zA-Z0-9]+$'
)

REMOTE_IMAGE_PATTERN = re.compile(
    r'^https?://'
    r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'
    r'localhost|'
    r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
    r'(?::\d+)?'
    r'(?:/?|[/?]\S+)\.(jpg|jpeg|png|webp|gif)$',
    re.IGNORECASE
)


def validate_image_url(url: str) -> bool:
    """Validate that URL is a valid image URL (local or remote)."""
    if not url:
        return False
    if LOCAL_IMAGE_PATTERN.match(url):
        return True
    return bool(REMOTE_IMAGE_PATTERN.match(url))


@router.post("/uploads", status_code=status.HTTP_201_CREATED)
async def upload_task_images(
    files: list[UploadFile] = File(...),
    current_user: dict = Depends(get_current_user),
):
    """Upload images for a task.
    
    Accepts up to 6 images (jpg, png, webp, gif) up to 5MB each.
    Returns array of image URLs.
    Images are stored with customer ID in path for organization.
    """
    if not files:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No files provided"
        )
    
    if len(files) > MAX_FILES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Maximum {MAX_FILES} images allowed"
        )
    
    for file in files:
        if not allowed_file(file.filename or ""):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File type not allowed: {file.filename}. Allowed: jpg, jpeg, png, webp, gif"
            )
        
        content = await file.read()
        is_valid, error_msg = validate_mime_type(content, file.filename or "")
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid file: {file.filename}. {error_msg}"
            )
        # Reading for validation consumed the stream; rewind so the save step
        # below writes the real bytes instead of an empty (0-byte) file.
        await file.seek(0)

    customer_id = current_user.get("sub", "")
    
    from utils.file_storage import save_task_image
    urls = []
    for file in files:
        url = await save_task_image(file, customer_id)
        if url:
            urls.append(url)
    
    return {
        "message": f"Uploaded {len(urls)} image(s)",
        "image_urls": urls,
    }


@router.post("", status_code=status.HTTP_201_CREATED)
def create_task(
    task: TaskCreate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    now = datetime.utcnow()
    
    if not task.title or not task.title.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Title is required"
        )
    
    if not task.description or not task.description.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Description is required"
        )
    
    if not task.location or not task.location.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Location is required"
        )
    
    if task.budget <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Budget must be greater than 0"
        )
    
    if task.deadline <= now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Deadline must be in the future"
        )
    
    images = list(task.images or [])
    if len(images) > MAX_FILES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Maximum {MAX_FILES} images allowed"
        )
    
    for img_url in images:
        if not validate_image_url(img_url):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid image URL: {img_url}"
            )

    try:
        from routes._helpers import task_review_enabled, notify_user, scan_banned_keywords
        # Every task is screened by the team before going live (guards against
        # inappropriate photos/language). Disable via the `task_review_enabled`
        # setting to post directly to `open`.
        initial_status = "pending_review" if task_review_enabled(session) else "open"

        # Auto-flag banned keywords: force review + a note the moderator sees,
        # even if the review gate is otherwise off.
        flagged_word = scan_banned_keywords(session, task.title, task.description)
        review_note = None
        if flagged_word:
            initial_status = "pending_review"
            review_note = f"Auto-flagged: contains \"{flagged_word}\""

        task_id = generate_task_id(session)
        new_task = Task(
            id=task_id,
            title=task.title.strip(),
            description=task.description.strip(),
            category=task.category.value,
            budget=float(task.budget),
            location=task.location.strip(),
            latitude=task.latitude,
            longitude=task.longitude,
            deadline=task.deadline,
            images=images,
            status=initial_status,
            review_reason=review_note,
            posted_by=current_user["sub"],
            assigned_to=None,
            applicants_count=0,
            completion_otp=None,
            created_at=now,
            updated_at=now,
        )

        session.add(new_task)
        if initial_status == "pending_review":
            notify_user(session, current_user["sub"], "Task under review",
                        f"'{new_task.title}' is being reviewed by our team and "
                        "will go live shortly (usually within 5 minutes).",
                        emoji="🕒")
        session.commit()
        session.refresh(new_task)

        return {
            "message": (
                "Task submitted for review"
                if initial_status == "pending_review"
                else "Task posted successfully"
            ),
            "task": task_to_response(session, new_task),
        }
    except Exception as e:
        session.rollback()
        print(f"Task creation error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create task, please try again"
        )


def _viewer_reviewed(session: Session, task_id: str, viewer: str | None) -> bool:
    """Whether ``viewer`` has already left a review for this task (so the app
    can hide the 'Rate' button once a review exists)."""
    if not viewer:
        return False
    from database import Review
    return session.execute(
        select(Review.id).where(
            and_(Review.task_id == task_id, Review.reviewer_id == viewer)
        )
    ).first() is not None


@router.get("")
def get_tasks(
    task_status: str | None = Query(default=None, alias="status"),
    category: str | None = Query(default=None),
    current_user: dict | None = Depends(get_current_user_optional),
    session: Session = Depends(get_db_session),
):
    # Auto-release tasks past their review hold so customers see them go live.
    from routes._helpers import release_pending_tasks
    release_pending_tasks(session)

    query = select(Task)

    if current_user and current_user.get("role") == "customer":
        query = query.where(Task.posted_by == current_user["sub"])
        # A rejected task is removed from the customer's app — they're told why
        # via a notification; the record is kept for the admin/moderation view.
        query = query.where(Task.status != "rejected")

    if task_status:
        query = query.where(Task.status == task_status)
    if category:
        query = query.where(Task.category == category)

    tasks = session.execute(query.order_by(Task.created_at.desc())).scalars().all()
    viewer = current_user["sub"] if current_user else None
    results = []
    for task in tasks:
        row = task_to_response(session, task)
        row["reviewed"] = _viewer_reviewed(session, task.id, viewer)
        # The completion OTP is the customer's sign-off secret — never expose
        # it to taskers or anonymous viewers.
        if task.posted_by != viewer:
            row["completion_otp"] = None
        results.append(row)
    return results


# ========== Task Drafts ==========

@router.get("/drafts")
def get_task_drafts(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get user's task drafts."""
    return []


@router.post("/drafts")
def create_task_draft(
    payload: dict,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Save a task draft."""
    return {
        "draft_id": f"draft_{uuid.uuid4().hex[:12]}",
        "message": "Draft saved",
    }


@router.get("/drafts/{draft_id}")
def get_task_draft(
    draft_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get a specific task draft."""
    return {
        "draft_id": draft_id,
        "data": {},
    }


@router.put("/drafts/{draft_id}")
def update_task_draft(
    draft_id: str,
    payload: dict,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Update a task draft."""
    return {
        "draft_id": draft_id,
        "message": "Draft updated",
    }


@router.delete("/drafts/{draft_id}")
def delete_task_draft(
    draft_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Delete a task draft."""
    return {
        "message": "Draft deleted",
    }


@router.get("/{task_id}")
def get_task_by_id(
    task_id: str,
    current_user: dict | None = Depends(get_current_user_optional),
    session: Session = Depends(get_db_session),
):
    """Get a single task by ID."""
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    row = task_to_response(session, task)
    viewer = current_user["sub"] if current_user else None
    row["reviewed"] = _viewer_reviewed(session, task.id, viewer)
    if task.posted_by != viewer:
        row["completion_otp"] = None
    return row


@router.get("/{task_id}/tasker-location")
def get_task_tasker_location(
    task_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Live location of the tasker assigned to a task, for the customer's
    tracking view. Visible only to the task's poster or the assigned tasker."""
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    viewer = current_user["sub"]
    if viewer not in (task.posted_by, task.assigned_to):
        raise HTTPException(status_code=403, detail="Not allowed")
    if not task.assigned_to:
        raise HTTPException(status_code=404, detail="No tasker assigned yet")

    tasker = session.get(User, task.assigned_to)
    return {
        "task_id": task.id,
        "on_the_way_at": task.on_the_way_at,
        "latitude": tasker.latitude if tasker else None,
        "longitude": tasker.longitude if tasker else None,
        "last_location_at": tasker.last_location_at if tasker else None,
        "tasker": {
            "id": tasker.id,
            "name": (tasker.name or "Your tasker") if tasker else "Your tasker",
            "avatar_url": tasker.avatar_url if tasker else None,
        } if tasker else None,
    }
