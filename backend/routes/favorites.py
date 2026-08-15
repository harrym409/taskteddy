"""Saved taskers and services for a customer's Favorites list."""
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import Favorite, Service, User, get_db_session
from routes._helpers import user_to_public
from utils.auth import get_current_user

router = APIRouter()

_TYPES = {"tasker", "service"}


class FavoriteIn(BaseModel):
    target_type: str
    target_id: str


def _enrich(session: Session, fav: Favorite) -> dict:
    base = {
        "id": fav.id,
        "target_type": fav.target_type,
        "target_id": fav.target_id,
        "created_at": fav.created_at,
        "target": None,
    }
    if fav.target_type == "service":
        svc = session.get(Service, fav.target_id)
        if svc is not None:
            base["target"] = {
                "id": svc.id,
                "name": svc.name,
                "emoji": svc.emoji,
                "icon_asset": svc.icon_asset,
                "category": svc.category,
                "price": float(svc.price),
                "original_price": float(svc.original_price),
                "rating": float(svc.rating or 0.0),
                "review_count": int(svc.review_count or 0),
            }
    elif fav.target_type == "tasker":
        usr = session.get(User, fav.target_id)
        if usr is not None:
            base["target"] = user_to_public(usr, include_wallet=False)
    return base


@router.get("")
def list_favorites(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    favs = (
        session.execute(
            select(Favorite)
            .where(Favorite.user_id == current_user["sub"])
            .order_by(Favorite.created_at.desc())
        )
        .scalars()
        .all()
    )
    # Drop favorites whose target no longer exists, keep the list clean.
    return [e for e in (_enrich(session, f) for f in favs) if e["target"] is not None]


@router.get("/ids")
def favorite_ids(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Lightweight list of favorited target ids, for toggling heart icons."""
    rows = (
        session.execute(
            select(Favorite.target_type, Favorite.target_id).where(
                Favorite.user_id == current_user["sub"]
            )
        )
        .all()
    )
    return {
        "service": [tid for t, tid in rows if t == "service"],
        "tasker": [tid for t, tid in rows if t == "tasker"],
    }


@router.post("", status_code=201)
def add_favorite(
    body: FavoriteIn,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    if body.target_type not in _TYPES:
        raise HTTPException(status_code=400, detail="Invalid target_type")

    # Verify the target exists before saving.
    if body.target_type == "service" and session.get(Service, body.target_id) is None:
        raise HTTPException(status_code=404, detail="Service not found")
    if body.target_type == "tasker" and session.get(User, body.target_id) is None:
        raise HTTPException(status_code=404, detail="Tasker not found")

    existing = (
        session.execute(
            select(Favorite).where(
                Favorite.user_id == current_user["sub"],
                Favorite.target_type == body.target_type,
                Favorite.target_id == body.target_id,
            )
        )
        .scalars()
        .first()
    )
    if existing is not None:
        return _enrich(session, existing)

    fav = Favorite(
        id=f"FAV_{uuid.uuid4().hex[:20]}",
        user_id=current_user["sub"],
        target_type=body.target_type,
        target_id=body.target_id,
        created_at=datetime.utcnow(),
    )
    session.add(fav)
    session.commit()
    session.refresh(fav)
    return _enrich(session, fav)


@router.delete("/{target_type}/{target_id}", status_code=204)
def remove_favorite(
    target_type: str,
    target_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    fav = (
        session.execute(
            select(Favorite).where(
                Favorite.user_id == current_user["sub"],
                Favorite.target_type == target_type,
                Favorite.target_id == target_id,
            )
        )
        .scalars()
        .first()
    )
    if fav is not None:
        session.delete(fav)
        session.commit()
    return None
