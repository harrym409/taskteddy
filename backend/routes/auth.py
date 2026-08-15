"""Simplified authentication - Phone + OTP only with multi-tenant support."""
from datetime import datetime
import re

from fastapi import APIRouter, Depends, HTTPException, Request, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field, field_validator

from database import User, get_db_session
from models.schemas import AuthResponse, UserType
from routes._helpers import user_to_public
from utils.auth import create_access_token, get_current_user, revoke_token
from utils.otp import send_otp, verify_otp

_bearer = HTTPBearer()

router = APIRouter()


class SendOtpRequest(BaseModel):
    phone: str = Field(..., min_length=10)
    user_type: UserType = Field(default=UserType.customer, description="customer or tasker")


class VerifyOtpRequest(BaseModel):
    phone: str = Field(..., min_length=10)
    otp: str = Field(..., min_length=6, max_length=6)
    
    @field_validator("otp")
    @classmethod
    def otp_must_be_numeric(cls, v: str) -> str:
        if not re.match(r"^\d{6}$", v):
            raise ValueError("OTP must be exactly 6 digits")
        return v


@router.post("/send-otp")
def send_otp_endpoint(data: SendOtpRequest):
    """Send OTP to phone number for authentication."""
    result = send_otp(data.phone, user_type=data.user_type.value)
    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=result.get("message", "Failed to send OTP")
        )
    return result


@router.post("/verify-otp")
def verify_otp_endpoint(data: VerifyOtpRequest):
    """Verify OTP and login/register user."""
    result = verify_otp(data.phone, data.otp)
    
    if not result.get("valid"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=result.get("message", "Invalid OTP")
        )
    
    # Get user from database using dependency
    from database import SessionLocal
    with SessionLocal() as session:
        user = session.get(User, result["user_id"])
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Update last login
        user.last_login_at = datetime.utcnow()
        user.updated_at = datetime.utcnow()
        session.commit()
        session.refresh(user)
        
        # Create JWT token with user_type
        token = create_access_token({
            "sub": user.id,
            "phone": user.phone,
            "role": user.user_type,
            "user_type": user.user_type,
        })
        
        return {
            "access_token": token,
            "token_type": "bearer",
            "user": user_to_public(user),
            "is_new_user": result.get("is_new_user", False),
            "user_type": user.user_type,
        }


@router.post("/login", response_model=AuthResponse)
def login(data: SendOtpRequest):
    """Legacy login - redirect to OTP flow."""
    return send_otp(data.phone, user_type=data.user_type.value)


@router.post("/logout")
def logout(
    credentials: HTTPAuthorizationCredentials = Security(_bearer),
):
    """Logout: revoke the presented token so it can't be reused.

    Revocation is backed by Redis (token jti blacklist until its natural expiry).
    Without Redis this is a no-op and the client must still discard the token.
    """
    revoked = revoke_token(credentials.credentials)
    return {"message": "Logged out successfully", "revoked": revoked}