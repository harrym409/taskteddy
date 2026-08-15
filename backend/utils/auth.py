import uuid
from datetime import datetime, timedelta
from typing import Dict, Optional

import redis
from fastapi import Depends, HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from passlib.context import CryptContext

from config import get_settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

# Use config.py for all JWT settings
_settings = get_settings()
JWT_SECRET = _settings["JWT_SECRET"]
JWT_ALGORITHM = _settings["JWT_ALGORITHM"]
JWT_EXPIRATION = _settings["JWT_EXPIRATION"]

# Redis client for token revocation
_redis_client: Optional[redis.Redis] = None


def _get_redis_client() -> Optional[redis.Redis]:
    """Get Redis client for token blacklist."""
    global _redis_client
    if _redis_client is None:
        if _settings.get("redis_enabled") and _settings.get("redis_url"):
            try:
                _redis_client = redis.from_url(_settings["redis_url"])
            except Exception:
                pass
    return _redis_client


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: Dict) -> str:
    """Create JWT with unique jti and iat claims for security."""
    to_encode = data.copy()
    now = datetime.utcnow()
    expire = now + timedelta(seconds=JWT_EXPIRATION)
    
    to_encode.update({
        "exp": expire,
        "iat": now,
        "jti": uuid.uuid4().hex[:16],  # Unique token ID for revocation
    })
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return encoded_jwt


def decode_token(token: str, check_revocation: bool = True) -> Dict:
    """Decode JWT and optionally check token revocation."""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        
        # Check if token is revoked
        if check_revocation:
            jti = payload.get("jti")
            if jti and is_token_revoked(jti):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token has been revoked",
                    headers={"WWW-Authenticate": "Bearer"},
                )
        
        return payload
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


def is_token_revoked(jti: str) -> bool:
    """Check if token jti is in revocation list."""
    redis_client = _get_redis_client()
    if redis_client:
        try:
            return redis_client.exists(f"revoked:{jti}") > 0
        except Exception:
            return False
    return False


def revoke_token(token: str) -> bool:
    """Revoke a token by adding jti to blacklist."""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        jti = payload.get("jti")
        if not jti:
            return False
        
        redis_client = _get_redis_client()
        if redis_client:
            # Calculate TTL remaining
            exp = payload.get("exp")
            if exp:
                ttl = (exp - datetime.utcnow()).total_seconds()
                if ttl > 0:
                    redis_client.setex(f"revoked:{jti}", int(ttl), "1")
                    return True
        return False
    except Exception:
        return False


def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security)) -> Dict:
    """Get current user from JWT token with revocation check."""
    token = credentials.credentials
    payload = decode_token(token, check_revocation=True)
    return payload


def get_current_user_optional(credentials: Optional[HTTPAuthorizationCredentials] = Security(security)) -> Optional[Dict]:
    """Get current user if token provided, None otherwise."""
    if not credentials:
        return None
    try:
        return decode_token(credentials.credentials, check_revocation=True)
    except HTTPException:
        return None


# ============================================================================
# Role-Based Access Control
# ============================================================================

def require_role(
    allowed_roles: list[str]
) -> callable:
    """Dependency factory to require specific roles"""
    def role_checker(current_user: Dict = Depends(get_current_user)) -> Dict:
        user_role = current_user.get("role", "")
        
        # Also check user_type for multi-tenant
        user_type = current_user.get("user_type", "")
        
        # Check both role and user_type for backwards compatibility
        if user_role not in allowed_roles and user_type not in allowed_roles:
            role_names = ", ".join(allowed_roles)
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {role_names}"
            )
        return current_user
    
    return role_checker


def require_customer() -> callable:
    """Dependency to require customer role"""
    return require_role(["customer"])


def require_tasker() -> callable:
    """Dependency to require tasker role"""
    return require_role(["tasker"])


def require_admin() -> callable:
    """Dependency to require admin role"""
    return require_role(["admin"])