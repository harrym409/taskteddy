from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class UserRole(str, Enum):
    customer = "customer"
    tasker = "tasker"
    admin = "admin"


class UserType(str, Enum):
    """User type for multi-tenant architecture"""
    customer = "customer"
    tasker = "tasker"

class TaskStatus(str, Enum):
    open = "open"
    assigned = "assigned"
    inProgress = "inProgress"
    completed = "completed"
    cancelled = "cancelled"

class TaskCategory(str, Enum):
    cleaning = "cleaning"
    repair = "repair"
    delivery = "delivery"
    errands = "errands"
    moving = "moving"
    cooking = "cooking"
    tutoring = "tutoring"
    tech = "tech"
    photography = "photography"
    painting = "painting"
    gardening = "gardening"
    other = "other"

class ApplicationStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"
    withdrawn = "withdrawn"

# Auth Schemas
class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: UserRole = UserRole.customer
    phone: Optional[str] = None
    firebase_id_token: Optional[str] = None

class LoginRequest(BaseModel):
    identifier: str
    password: str

class LoginStartResponse(BaseModel):
    pending_login_token: str
    phone: str
    expires_in_minutes: int = 10

class LoginCompleteRequest(BaseModel):
    pending_login_token: str
    firebase_id_token: str

class PhoneAuthRequest(BaseModel):
    phone: str
    firebase_id_token: str
    role: UserRole = UserRole.customer

class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict

# User Schemas
class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    avatar_url: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None
    title: Optional[str] = None
    gender: Optional[str] = None

# Service Schemas
class ServiceCreate(BaseModel):
    name: str
    emoji: Optional[str] = None
    category: str
    description: str
    price: float
    original_price: float
    includes: List[str] = []
    is_hot: bool = False
    is_new: bool = False

# Task Schemas
class TaskCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(..., min_length=1, max_length=5000)
    category: TaskCategory
    budget: float = Field(..., gt=0, le=1000000)  # 0 to 10 lakhs
    location: str = Field(..., min_length=1, max_length=500)
    deadline: datetime
    images: List[str] = []
    # Optional coordinates for location-based filtering
    latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    longitude: Optional[float] = Field(default=None, ge=-180, le=180)

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    budget: Optional[float] = None
    location: Optional[str] = None
    deadline: Optional[datetime] = None
    status: Optional[TaskStatus] = None
    latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    longitude: Optional[float] = Field(default=None, ge=-180, le=180)

# Location Schemas
class LocationUpdate(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class LocationQuery(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    radius_km: float = Field(default=20, le=30)

# Booking Schemas
class BookingCreate(BaseModel):
    service_id: str
    scheduled_at: datetime
    address: str
    notes: Optional[str] = None

# Application Schemas
class ApplicationCreate(BaseModel):
    task_id: str
    bid_amount: float
    cover_letter: str

# Message Schemas
class MessageCreate(BaseModel):
    conversation_id: str
    text: Optional[str] = None
    image_url: Optional[str] = None

# Review Schemas
class ReviewCreate(BaseModel):
    reviewed_user_id: str
    task_id: str
    rating: float
    # Optional: a star-only rating (no written comment) is valid. When omitted
    # by the app it must not 422 — default to an empty string.
    comment: str = ""

# Wallet Schemas
class WithdrawalRequest(BaseModel):
    amount: float
    method: str
    details: dict

class WalletTopUpRequest(BaseModel):
    amount: float

class EmailVerifyRequest(BaseModel):
    code: str