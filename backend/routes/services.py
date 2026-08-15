from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from data.service_catalog import DEFAULT_SERVICES
from database import Service, User, generate_user_id, get_db_session

router = APIRouter()


def _bootstrap_services_if_empty(session: Session) -> None:
    existing_count = session.query(Service).count()
    if existing_count > 0:
        return

    now = datetime.utcnow()
    fallback_tasker = (
        session.execute(
            select(User)
            .where(User.user_type == "tasker")
            .order_by(User.created_at.asc())
            .limit(1)
        )
        .scalars()
        .first()
    )
    if fallback_tasker is None:
        fallback_tasker = User(
            id=generate_user_id("tasker"),
            user_type="tasker",
            name="TaskTeddy Services",
            created_at=now,
            updated_at=now,
        )
        session.add(fallback_tasker)
        session.flush()

    for service in DEFAULT_SERVICES:
        session.add(
            Service(
                id=str(service.get("id")),
                name=service["name"],
                emoji=service.get("emoji"),
                icon_asset=service.get("icon_asset"),
                category=service["category"],
                description=service["description"],
                price=float(service["price"]),
                original_price=float(service["original_price"]),
                rating=float(service.get("rating", 5.0)),
                review_count=int(service.get("review_count", 0)),
                is_hot=bool(service.get("is_hot", False)),
                is_new=bool(service.get("is_new", False)),
                includes=list(service.get("includes", [])),
                tasker_id=fallback_tasker.id,
                created_at=now,
            )
        )
    session.commit()


def _service_to_dict(service: Service) -> dict:
    return {
        "id": service.id,
        "name": service.name,
        "emoji": service.emoji,
        "icon_asset": service.icon_asset,
        "category": service.category,
        "description": service.description,
        "price": float(service.price),
        "original_price": float(service.original_price),
        "rating": float(service.rating or 0.0),
        "review_count": int(service.review_count or 0),
        "is_hot": bool(service.is_hot),
        "is_new": bool(service.is_new),
        "includes": service.includes or [],
        "created_at": service.created_at,
    }


_SORTS = {"recommended", "price_low", "price_high", "rating", "newest"}


@router.get("/categories")
def get_categories(session: Session = Depends(get_db_session)):
    """Distinct service categories with a live count, for browse-by-category."""
    _bootstrap_services_if_empty(session)
    rows = (
        session.execute(
            select(Service.category, func.count(Service.id))
            .where(Service.is_active == True)  # noqa: E712
            .group_by(Service.category)
            .order_by(func.count(Service.id).desc())
        )
        .all()
    )
    return [{"category": c, "count": int(n)} for c, n in rows if c]


@router.get("/")
def get_services(
    session: Session = Depends(get_db_session),
    q: Optional[str] = Query(None, description="Free-text search on name/description"),
    category: Optional[str] = Query(None),
    min_price: Optional[float] = Query(None, ge=0),
    max_price: Optional[float] = Query(None, ge=0),
    min_rating: Optional[float] = Query(None, ge=0, le=5),
    sort: str = Query("recommended"),
):
    _bootstrap_services_if_empty(session)

    stmt = select(Service).where(Service.is_active == True)  # noqa: E712

    if q:
        term = f"%{q.strip().lower()}%"
        stmt = stmt.where(
            or_(
                func.lower(Service.name).like(term),
                func.lower(Service.description).like(term),
                func.lower(Service.category).like(term),
            )
        )
    if category and category.lower() not in ("all", ""):
        stmt = stmt.where(func.lower(Service.category) == category.strip().lower())
    if min_price is not None:
        stmt = stmt.where(Service.price >= min_price)
    if max_price is not None:
        stmt = stmt.where(Service.price <= max_price)
    if min_rating is not None:
        stmt = stmt.where(Service.rating >= min_rating)

    sort = sort if sort in _SORTS else "recommended"
    if sort == "price_low":
        stmt = stmt.order_by(Service.price.asc())
    elif sort == "price_high":
        stmt = stmt.order_by(Service.price.desc())
    elif sort == "rating":
        stmt = stmt.order_by(Service.rating.desc(), Service.review_count.desc())
    elif sort == "newest":
        stmt = stmt.order_by(Service.created_at.desc())
    else:  # recommended: hot first, then rating, then popularity
        stmt = stmt.order_by(
            Service.is_hot.desc(), Service.rating.desc(), Service.review_count.desc()
        )

    services = session.execute(stmt).scalars().all()
    return [_service_to_dict(s) for s in services]


@router.get("/{service_id}")
def get_service(service_id: str, session: Session = Depends(get_db_session)):
    _bootstrap_services_if_empty(session)
    service = session.get(Service, str(service_id))
    if service is None:
        raise HTTPException(status_code=404, detail="Service not found")
    return _service_to_dict(service)
