"""Application constants - centralized magic numbers and defaults.

This file centralizes all hardcoded values that were previously scattered
across the codebase. All values maintain existing behavior.
"""
from typing import Final

# ============================================================================
# Pagination Defaults (unchanged from existing defaults)
# ============================================================================
DEFAULT_PAGE_SIZE: Final[int] = 20
MAX_PAGE_SIZE: Final[int] = 100
DEFAULT_MESSAGE_LIMIT: Final[int] = 50

# ============================================================================
# Upload Limits (matching existing MAX_UPLOAD_SIZE = 10485760)
# ============================================================================
MAX_UPLOAD_SIZE_BYTES: Final[int] = 10 * 1024 * 1024  # 10MB
ALLOWED_IMAGE_TYPES: Final[list[str]] = ["image/jpeg", "image/png", "image/webp", "image/gif"]
ALLOWED_DOCUMENT_TYPES: Final[list[str]] = ["application/pdf"]

# ============================================================================
# Validation Limits (matching existing field constraints)
# ============================================================================
NAME_MIN_LENGTH: Final[int] = 1
NAME_MAX_LENGTH: Final[int] = 100
TITLE_MIN_LENGTH: Final[int] = 5
TITLE_MAX_LENGTH: Final[int] = 200
DESCRIPTION_MIN_LENGTH: Final[int] = 10
PHONE_MIN_LENGTH: Final[int] = 10
OTP_LENGTH: Final[int] = 6
OTP_EXPIRY_SECONDS: Final[int] = 60

# ============================================================================
# Wallet Limits (matching existing validation)
# ============================================================================
MIN_WITHDRAWAL_AMOUNT: Final[float] = 100.0
TOPUP_BONUS_PERCENTAGE: Final[float] = 0.05  # 5%
TOPUP_BONUS_THRESHOLD: Final[float] = 250.0

# ============================================================================
# Rate Limiting (matching existing middleware)
# ============================================================================
DEFAULT_RATE_LIMIT_PER_MINUTE: Final[int] = 120
AUTH_RATE_LIMIT_PER_MINUTE: Final[int] = 20
OTP_RATE_LIMIT_PER_HOUR: Final[int] = 5

# ============================================================================
# Task & Service Limits
# ============================================================================
MIN_TASK_BUDGET: Final[float] = 0.01
MIN_SERVICE_PRICE: Final[float] = 0.01
MAX_APPLICATION_COVER_LETTER: Final[int] = 2000

# ============================================================================
# Chat & Messaging
# ============================================================================
MAX_MESSAGE_LENGTH: Final[int] = 1000
MAX_CONVERSATION_PREVIEW: Final[int] = 100  # For last_message preview
IMAGE_MESSAGE_PLACEHOLDER: Final[str] = "📷 Photo"

# ============================================================================
# Review Limits
# ============================================================================
MIN_RATING: Final[float] = 1.0
MAX_RATING: Final[float] = 5.0

# ============================================================================
# User Fields
# ============================================================================
VALID_TITLES: Final[list[str]] = ["Mr", "Ms"]
VALID_GENDERS: Final[list[str]] = ["male", "female", "other"]

# ============================================================================
# Task Statuses (matching existing enum)
# ============================================================================
TASK_STATUS_OPEN: Final[str] = "open"
TASK_STATUS_ASSIGNED: Final[str] = "assigned"
TASK_STATUS_IN_PROGRESS: Final[str] = "inProgress"
TASK_STATUS_COMPLETED: Final[str] = "completed"
TASK_STATUS_CANCELLED: Final[str] = "cancelled"

# ============================================================================
# Application Statuses
# ============================================================================
APPLICATION_STATUS_PENDING: Final[str] = "pending"
APPLICATION_STATUS_ACCEPTED: Final[str] = "accepted"
APPLICATION_STATUS_REJECTED: Final[str] = "rejected"
APPLICATION_STATUS_WITHDRAWN: Final[str] = "withdrawn"

# ============================================================================
# Booking Statuses
# ============================================================================
BOOKING_STATUS_CONFIRMED: Final[str] = "confirmed"
BOOKING_STATUS_COMPLETED: Final[str] = "completed"
BOOKING_STATUS_CANCELLED: Final[str] = "cancelled"

# ============================================================================
# Withdrawal Statuses
# ============================================================================
WITHDRAWAL_STATUS_PENDING: Final[str] = "pending"
WITHDRAWAL_STATUS_APPROVED: Final[str] = "approved"
WITHDRAWAL_STATUS_REJECTED: Final[str] = "rejected"
WITHDRAWAL_STATUS_COMPLETED: Final[str] = "completed"

# ============================================================================
# ID Prefixes (matching database.py)
# ============================================================================
ID_PREFIX_CUSTOMER: Final[str] = "CUST"
ID_PREFIX_TASKER: Final[str] = "TSKR"
ID_PREFIX_TASK: Final[str] = "TASK"
ID_PREFIX_SERVICE: Final[str] = "SERV"
ID_PREFIX_BOOKING: Final[str] = "BOOK"
ID_PREFIX_APPLICATION: Final[str] = "APP"

# ============================================================================
# Cache TTL (in seconds)
# ============================================================================
TOKEN_CACHE_TTL: Final[int] = 300  # 5 minutes
OTP_CACHE_TTL: Final[int] = 60  # 1 minute

# ============================================================================
# Error Messages (consistent with existing)
# ============================================================================
ERROR_USER_NOT_FOUND: Final[str] = "User not found"
ERROR_TASK_NOT_FOUND: Final[str] = "Task not found"
ERROR_SERVICE_NOT_FOUND: Final[str] = "Service not found"
ERROR_BOOKING_NOT_FOUND: Final[str] = "Booking not found"
ERROR_UNAUTHORIZED: Final[str] = "Not authorized"
ERROR_FORBIDDEN: Final[str] = "Access denied"
ERROR_INVALID_OTP: Final[str] = "Invalid or expired OTP"
ERROR_RATE_LIMIT_EXCEEDED: Final[str] = "Too many requests"