"""Unit tests for the anti-disintermediation chat guards (pure functions)."""
import pytest
from fastapi import HTTPException

from routes.chat import _contains_contact_info, _clean_location, LocationPayload

pytestmark = pytest.mark.unit


@pytest.mark.parametrize(
    "text,blocked",
    [
        ("Please call me 9876543210", True),        # plain 10-digit number
        ("my number is 98765 43210", True),         # spaced number
        ("reach me at 987-654-3210", True),         # dashed number
        ("email me at foo@bar.com", True),          # email
        ("Sounds good, let's proceed.", False),     # normal preset
        ("I'll reach in 15 minutes.", False),       # small number ok
        ("The budget is 1200.", False),             # price ok
        ("", False),                                # empty
    ],
)
def test_contains_contact_info(text, blocked):
    assert _contains_contact_info(text) is blocked


def test_clean_location_valid():
    out = _clean_location(
        LocationPayload(lat=28.61, lng=77.20, label="Home", address="Green Park")
    )
    assert out["lat"] == 28.61
    assert out["lng"] == 77.20
    assert out["label"] == "Home"
    assert out["address"] == "Green Park"


def test_clean_location_blocks_phone_in_address():
    with pytest.raises(HTTPException) as exc:
        _clean_location(
            LocationPayload(lat=28.6, lng=77.2, address="Call 9876543210 at gate")
        )
    assert exc.value.status_code == 400


def test_clean_location_blocks_email_in_landmark():
    with pytest.raises(HTTPException):
        _clean_location(
            LocationPayload(lat=28.6, lng=77.2, address="Gate 2", landmark="me@x.com")
        )


def test_clean_location_rejects_out_of_range_coords():
    with pytest.raises(HTTPException):
        _clean_location(LocationPayload(lat=200.0, lng=77.2))
    with pytest.raises(HTTPException):
        _clean_location(LocationPayload(lat=28.6, lng=999.0))
