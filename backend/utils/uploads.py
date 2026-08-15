from fastapi import UploadFile, HTTPException
from pathlib import Path
import uuid
import os
from PIL import Image
import aiofiles

# Must match the StaticFiles mount in server.py (app.mount("/uploads",
# directory="uploads")) — i.e. "uploads" relative to the app root — otherwise
# every saved file 404s when served.
UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "uploads"))
MAX_SIZE = int(os.getenv("MAX_UPLOAD_SIZE", "10485760"))  # 10MB
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}

async def save_upload_file(file: UploadFile, folder: str = "general") -> str:
    # Validate file size
    contents = await file.read()
    if len(contents) > MAX_SIZE:
        raise HTTPException(status_code=400, detail="File too large (max 10MB)")
    
    # Validate extension
    ext = Path(file.filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail=f"File type not allowed. Allowed: {ALLOWED_EXTENSIONS}")
    
    # Create folder
    folder_path = UPLOAD_DIR / folder
    folder_path.mkdir(parents=True, exist_ok=True)
    
    # Generate unique filename
    filename = f"{uuid.uuid4()}{ext}"
    file_path = folder_path / filename
    
    # Save file
    async with aiofiles.open(file_path, 'wb') as f:
        await f.write(contents)
    
    # Optionally compress image
    if ext in {".jpg", ".jpeg", ".png"}:
        try:
            img = Image.open(file_path)
            if img.width > 1920 or img.height > 1920:
                img.thumbnail((1920, 1920), Image.Resampling.LANCZOS)
                img.save(file_path, optimize=True, quality=85)
        except:
            pass
    
    return f"/uploads/{folder}/{filename}"

def delete_upload_file(file_url: str):
    try:
        if file_url.startswith("/uploads/"):
            file_path = UPLOAD_DIR / file_url.replace("/uploads/", "")
            if file_path.exists():
                file_path.unlink()
    except:
        pass