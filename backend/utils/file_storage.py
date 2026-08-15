"""File storage utilities for handling image uploads.

Supports both local filesystem storage (development) and S3 (production).
Switch by setting USE_S3=true in environment.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from pathlib import Path

from fastapi import UploadFile

from config import get_settings

settings = get_settings()

# Configuration
UPLOAD_DIR = Path("uploads/tasks")
ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "gif"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB per file
MAX_FILES = 6

# S3 Configuration (lazy-loaded)
_s3_client = None

def _get_s3_config():
    """Get S3 configuration from settings."""
    return {
        "USE_S3": settings.get("USE_S3", False),
        "S3_BUCKET": settings.get("S3_BUCKET", ""),
        "S3_REGION": settings.get("S3_REGION", "us-east-1"),
        "S3_ACCESS_KEY": settings.get("S3_ACCESS_KEY", ""),
        "S3_SECRET_KEY": settings.get("S3_SECRET_KEY", ""),
        "S3_ENDPOINT_URL": settings.get("S3_ENDPOINT_URL", ""),
        "S3_PUBLIC_URL": settings.get("S3_PUBLIC_URL", ""),
    }


def get_upload_dir() -> Path:
    """Get or create the upload directory (local storage only)."""
    upload_dir = UPLOAD_DIR
    # Ensure parent 'uploads' directory exists for StaticFiles mounting
    upload_dir.parent.mkdir(parents=True, exist_ok=True)
    upload_dir.mkdir(parents=True, exist_ok=True)
    return upload_dir


def allowed_file(filename: str) -> bool:
    """Check if file extension is allowed."""
    if not filename or "." not in filename:
        return False
    ext = filename.rsplit(".", 1)[-1].lower()
    return ext in ALLOWED_EXTENSIONS


def validate_file_size(content: bytes) -> tuple[bool, str]:
    """Validate file size.
    
    Returns:
        (is_valid, error_message)
    """
    if len(content) == 0:
        return False, "File is empty"
    if len(content) > MAX_FILE_SIZE:
        max_mb = MAX_FILE_SIZE / (1024 * 1024)
        return False, f"File exceeds {max_mb:.0f}MB limit"
    return True, ""


# MIME type signatures for image validation
IMAGE_SIGNATURES = {
    b'\xff\xd8\xff': 'jpeg',           # JPEG
    b'\x89PNG\r\n\x1a\n': 'png',       # PNG
    b'GIF87a': 'gif',                   # GIF87a
    b'GIF89a': 'gif',                   # GIF89a
    b'RIFF': 'webp',                    # WebP (starts with RIFF, ends with WEBP)
}


def validate_mime_type(content: bytes, filename: str) -> tuple[bool, str]:
    """Validate actual MIME type by checking file signatures.
    
    This prevents users from uploading malicious files with fake extensions.
    
    Returns:
        (is_valid, error_message)
    """
    if not content:
        return False, "File is empty"
    
    # Check file signature
    detected_type = None
    for signature, file_type in IMAGE_SIGNATURES.items():
        if content.startswith(signature):
            detected_type = file_type
            break
    
    # Special check for WebP (RIFF....WEBP)
    if content.startswith(b'RIFF') and content.endswith(b'WEBP'):
        detected_type = 'webp'
    
    if detected_type is None:
        return False, "Invalid image format"
    
    # Verify extension matches detected type
    ext = get_file_extension(filename)
    allowed_exts = {'jpg': 'jpeg', 'jpeg': 'jpeg', 'png': 'png', 'gif': 'gif', 'webp': 'webp'}
    
    if ext not in allowed_exts:
        return False, f"Extension not allowed: .{ext}"
    
    if allowed_exts[ext] != detected_type:
        return False, f"File content doesn't match extension: expected .{ext}, detected {detected_type}"
    
    return True, ""


def get_file_extension(filename: str) -> str:
    """Get lowercase file extension."""
    if "." not in filename:
        return ""
    return filename.rsplit(".", 1)[-1].lower()


def generate_unique_filename(original_filename: str, customer_id: str = "") -> str:
    """Generate unique filename while preserving extension.
    
    Args:
        original_filename: Original file name
        customer_id: Customer ID for path organization
    """
    ext = get_file_extension(original_filename)
    timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    unique_id = uuid.uuid4().hex[:8]
    
    if customer_id:
        # Sanitize customer_id (remove any path chars)
        safe_id = customer_id.replace("/", "_").replace("\\", "_")
        return f"{safe_id}_{timestamp}_{unique_id}.{ext}"
    else:
        return f"task_{timestamp}_{unique_id}.{ext}"


# ============================================================================
# S3 Storage
# ============================================================================

def _get_s3_client():
    """Get S3 client (lazy initialization)."""
    global _s3_client
    
    if _s3_client is not None:
        return _s3_client
    
    import boto3
    from botocore.config import Config
    
    cfg = _get_s3_config()
    
    config = Config(
        region_name=cfg["S3_REGION"],
        signature_version='s3v4',
        retries={'max_attempts': 3, 'mode': 'standard'}
    )
    
    client_kwargs = {
        'aws_access_key_id': cfg["S3_ACCESS_KEY"],
        'aws_secret_access_key': cfg["S3_SECRET_KEY"],
        'region_name': cfg["S3_REGION"],
        'config': config,
    }
    
    # Optional endpoint URL (for MinIO or custom S3-compatible storage)
    if cfg["S3_ENDPOINT_URL"]:
        client_kwargs['endpoint_url'] = cfg["S3_ENDPOINT_URL"]
    
    _s3_client = boto3.client('s3', **client_kwargs)
    return _s3_client


def _get_s3_key(filename: str, customer_id: str = "") -> str:
    """Generate S3 key (path) for the file.
    
    Path format: tasks/{customer_id}/{date}/{filename}
    Example: tasks/CUST_abc123/2026/06/02/CUST_abc123_20250602_abc123.jpg
    """
    date_prefix = datetime.utcnow().strftime("%Y/%m/%d")
    
    if customer_id:
        # Sanitize customer_id for S3 key
        safe_id = customer_id.replace("/", "_").replace("\\", "_")
        return f"tasks/{safe_id}/{date_prefix}/{filename}"
    else:
        return f"tasks/{date_prefix}/{filename}"


def _get_public_url(key: str) -> str:
    """Get public URL for S3 object."""
    cfg = _get_s3_config()
    
    if cfg["S3_PUBLIC_URL"]:
        # Use custom domain/CloudFront
        return f"{cfg['S3_PUBLIC_URL'].rstrip('/')}/{key}"
    else:
        # Use S3 native URL
        return f"https://{cfg['S3_BUCKET']}.s3.{cfg['S3_REGION']}.amazonaws.com/{key}"


async def _save_to_s3(file: UploadFile, filename: str, customer_id: str = "") -> str | None:
    """Save file to S3 and return public URL."""
    try:
        content = await file.read()
        
        # Check file size
        if len(content) > MAX_FILE_SIZE:
            return None
        
        # Generate S3 key with customer_id
        key = _get_s3_key(filename, customer_id)
        
        # Determine content type
        ext = get_file_extension(filename)
        content_types = {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'gif': 'image/gif',
            'webp': 'image/webp',
        }
        content_type = content_types.get(ext, 'application/octet-stream')
        
        # Upload to S3
        client = _get_s3_client()
        cfg = _get_s3_config()
        client.put_object(
            Bucket=cfg["S3_BUCKET"],
            Key=key,
            Body=content,
            ContentType=content_type,
            CacheControl='max-age=31536000',  # 1 year cache
        )
        
        return _get_public_url(key)
        
    except Exception as e:
        print(f"S3 upload error: {e}")
        return None


def _delete_from_s3(url: str) -> bool:
    """Delete file from S3 by URL."""
    try:
        cfg = _get_s3_config()
        
        # Extract key from URL
        key = None
        if cfg["S3_PUBLIC_URL"] and url.startswith(cfg["S3_PUBLIC_URL"]):
            key = url[len(cfg["S3_PUBLIC_URL"]):].lstrip('/')
        elif cfg["S3_BUCKET"] and f"{cfg['S3_BUCKET']}.s3." in url:
            # Extract from S3 native URL: https://bucket.s3.region.amazonaws.com/key
            parts = url.split('/')
            key = '/'.join(parts[3:])  # Skip https:, '', bucket, region
        
        if not key or not key.strip():
            return False
        
        client = _get_s3_client()
        client.delete_object(Bucket=cfg["S3_BUCKET"], Key=key)
        return True
        
    except Exception as e:
        print(f"S3 delete error: {e}")
        return False


# ============================================================================
# Local Storage
# ============================================================================

async def _save_to_local(file: UploadFile, filename: str, customer_id: str = "") -> str | None:
    """Save file to local filesystem and return URL."""
    try:
        content = await file.read()
        
        # Check file size
        if len(content) > MAX_FILE_SIZE:
            return None
        
        # Create customer subdirectory if customer_id provided
        upload_dir = get_upload_dir()
        if customer_id:
            safe_id = customer_id.replace("/", "_").replace("\\", "_")
            upload_dir = upload_dir / safe_id
            upload_dir.mkdir(parents=True, exist_ok=True)
        
        # Write file
        destination = upload_dir / filename
        with open(destination, "wb") as f:
            f.write(content)
        
        if customer_id:
            return f"/uploads/tasks/{safe_id}/{filename}"
        else:
            return f"/uploads/tasks/{filename}"
        
    except Exception as e:
        print(f"Local storage error: {e}")
        return None


def _delete_from_local(url: str) -> bool:
    """Delete file from local storage by URL."""
    try:
        if not url:
            return False
        
        # Extract path after /uploads/
        if url.startswith("/uploads/"):
            relative_path = url[len("/uploads/"):]
        else:
            relative_path = url
        
        # Prevent path traversal attacks
        if ".." in relative_path or relative_path.startswith("/"):
            return False
        
        file_path = Path("uploads") / relative_path
        
        # Ensure file is within uploads directory
        uploads_dir = Path("uploads").resolve()
        if not file_path.resolve().is_relative_to(uploads_dir):
            return False
        
        if file_path.exists():
            file_path.unlink()
            return True
        return False
        
    except Exception as e:
        print(f"Local delete error: {e}")
        return False


# ============================================================================
# Unified API (auto-selects storage based on USE_S3)
# ============================================================================

async def save_task_image(file: UploadFile, customer_id: str = "") -> str | None:
    """Save a task image and return its URL.
    
    Automatically uses S3 if USE_S3=true, otherwise local storage.
    
    Args:
        file: UploadFile from FastAPI
        customer_id: Customer ID for path organization
        
    Returns:
        URL path to the saved file, or None if failed
    """
    if not allowed_file(file.filename or ""):
        return None
    
    filename = generate_unique_filename(file.filename or "image.jpg", customer_id)
    
    cfg = _get_s3_config()
    if cfg["USE_S3"] and cfg["S3_BUCKET"]:
        return await _save_to_s3(file, filename, customer_id)
    else:
        return await _save_to_local(file, filename, customer_id)


async def save_task_images(files: list[UploadFile], customer_id: str = "") -> list[str]:
    """Save multiple task images and return their URLs.
    
    Args:
        files: List of UploadFile objects
        customer_id: Customer ID for path organization
        
    Returns:
        List of URL paths to saved files
    """
    urls = []
    
    for file in files:
        if len(urls) >= MAX_FILES:
            break
        
        url = await save_task_image(file, customer_id)
        if url:
            urls.append(url)
    
    return urls


def delete_task_image(url: str) -> bool:
    """Delete a task image by its URL.
    
    Args:
        url: URL path to the file
        
    Returns:
        True if deleted, False otherwise
    """
    if not url:
        return False
    
    cfg = _get_s3_config()
    if cfg["USE_S3"] and cfg["S3_BUCKET"]:
        return _delete_from_s3(url)
    else:
        return _delete_from_local(url)


def cleanup_task_images(urls: list[str]) -> int:
    """Delete multiple task images.
    
    Args:
        urls: List of URL paths
        
    Returns:
        Number of files successfully deleted
    """
    deleted = 0
    for url in urls:
        if delete_task_image(url):
            deleted += 1
    return deleted
