"""A user's reusable address book, used to speed up booking checkout."""
import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from database import SavedAddress, get_db_session
from routes._helpers import sanitize_text
from utils.auth import get_current_user

router = APIRouter()

_LABELS = {"Home", "Work", "Other"}


class AddressIn(BaseModel):
    label: str = "Home"
    address: str
    landmark: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_default: bool = False

    @field_validator("address")
    @classmethod
    def _addr_not_blank(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("address is required")
        return v.strip()


def _to_dict(a: SavedAddress) -> dict:
    return {
        "id": a.id,
        "label": a.label,
        "address": a.address,
        "landmark": a.landmark,
        "latitude": a.latitude,
        "longitude": a.longitude,
        "is_default": bool(a.is_default),
        "created_at": a.created_at,
        "updated_at": a.updated_at,
    }


def _clear_defaults(session: Session, user_id: str, keep_id: Optional[str] = None) -> None:
    stmt = update(SavedAddress).where(SavedAddress.user_id == user_id)
    if keep_id is not None:
        stmt = stmt.where(SavedAddress.id != keep_id)
    session.execute(stmt.values(is_default=False))


@router.get("")
def list_addresses(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    rows = (
        session.execute(
            select(SavedAddress)
            .where(SavedAddress.user_id == current_user["sub"])
            .order_by(SavedAddress.is_default.desc(), SavedAddress.updated_at.desc())
        )
        .scalars()
        .all()
    )
    return [_to_dict(a) for a in rows]


@router.post("", status_code=201)
def add_address(
    body: AddressIn,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    uid = current_user["sub"]
    label = body.label if body.label in _LABELS else "Other"
    # First address for a user becomes the default automatically.
    count = session.query(SavedAddress).filter(SavedAddress.user_id == uid).count()
    make_default = bool(body.is_default) or count == 0

    addr = SavedAddress(
        id=f"ADDR_{uuid.uuid4().hex[:20]}",
        user_id=uid,
        label=label,
        address=sanitize_text(body.address, 1000),
        landmark=sanitize_text(body.landmark, 200) if body.landmark else None,
        latitude=body.latitude,
        longitude=body.longitude,
        is_default=make_default,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    if make_default:
        _clear_defaults(session, uid)
    session.add(addr)
    session.commit()
    session.refresh(addr)
    return _to_dict(addr)


@router.patch("/{address_id}")
def update_address(
    address_id: str,
    body: AddressIn,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    addr = session.get(SavedAddress, address_id)
    if addr is None or addr.user_id != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Address not found")

    addr.label = body.label if body.label in _LABELS else "Other"
    addr.address = sanitize_text(body.address, 1000)
    addr.landmark = sanitize_text(body.landmark, 200) if body.landmark else None
    addr.latitude = body.latitude
    addr.longitude = body.longitude
    addr.updated_at = datetime.utcnow()
    if body.is_default:
        _clear_defaults(session, addr.user_id, keep_id=addr.id)
        addr.is_default = True
    session.commit()
    session.refresh(addr)
    return _to_dict(addr)


@router.post("/{address_id}/default")
def set_default(
    address_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    addr = session.get(SavedAddress, address_id)
    if addr is None or addr.user_id != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Address not found")
    _clear_defaults(session, addr.user_id, keep_id=addr.id)
    addr.is_default = True
    addr.updated_at = datetime.utcnow()
    session.commit()
    return _to_dict(addr)


@router.delete("/{address_id}", status_code=204)
def delete_address(
    address_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    addr = session.get(SavedAddress, address_id)
    if addr is None or addr.user_id != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Address not found")
    was_default = addr.is_default
    session.delete(addr)
    session.flush()
    # Promote another address to default if we removed the default one.
    if was_default:
        nxt = (
            session.execute(
                select(SavedAddress)
                .where(SavedAddress.user_id == current_user["sub"])
                .order_by(SavedAddress.updated_at.desc())
                .limit(1)
            )
            .scalars()
            .first()
        )
        if nxt is not None:
            nxt.is_default = True
    session.commit()
    return None
