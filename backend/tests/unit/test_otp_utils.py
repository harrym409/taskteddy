"""Unit tests for OTP helper utilities (pure functions)."""
import pytest

from utils.otp import _normalize_phone, _hash_otp, _generate_otp

pytestmark = pytest.mark.unit


@pytest.mark.parametrize(
    "raw,expected",
    [
        ("9876543210", "+919876543210"),
        ("+91 98765 43210", "+919876543210"),
        ("098765-43210", "+919876543210"),
        ("+919876543210", "+919876543210"),
    ],
)
def test_normalize_phone(raw, expected):
    assert _normalize_phone(raw) == expected


def test_hash_otp_is_deterministic_and_phone_bound():
    a = _hash_otp("123456", "+919876543210")
    b = _hash_otp("123456", "+919876543210")
    c = _hash_otp("123456", "+919999999999")
    assert a == b            # same input → same hash
    assert a != c            # bound to the phone number
    assert len(a) == 64      # sha256 hex, truncated


def test_generate_otp_shape():
    otp = _generate_otp()
    assert len(otp) == 6
    assert otp.isdigit()
