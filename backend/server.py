import logging
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path

import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from config import get_settings
from database import health_check, init_db
from middleware import RateLimitMiddleware, RequestIDMiddleware, SecurityHeadersMiddleware, rate_limit_store
from middleware.request_id import get_request_id
from utils.logging_config import configure_logging

settings = get_settings()
configure_logging(settings)
logger = logging.getLogger("taskteddy")


@asynccontextmanager
async def lifespan(app: FastAPI):
    if settings["IS_PRODUCTION"]:
        # In production the schema is owned by Alembic. Apply migrations with
        # `alembic upgrade head` (e.g. in the container entrypoint) — never
        # create_all() at runtime. We only verify connectivity here.
        health_check()
    else:
        # Dev convenience: create tables/sequences directly.
        init_db()
    yield


app = FastAPI(
    title="TaskTeddy API",
    version="2.0.0",
    description="TaskTeddy backend on SQLAlchemy + PostgreSQL",
    docs_url="/docs" if not settings["IS_PRODUCTION"] else None,
    redoc_url="/redoc" if not settings["IS_PRODUCTION"] else None,
    lifespan=lifespan,
    # Keep slash handling permissive: collection routes are defined inconsistently
    # (some as "/", some as ""), and the mobile clients call a mix of both. Letting
    # FastAPI redirect between "/path" and "/path/" avoids 404s that silently render
    # empty screens in the apps.
    redirect_slashes=True,
)

if settings["CORS_ORIGINS"] == ["*"] and not settings["IS_PRODUCTION"]:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
elif settings["CORS_ORIGINS"]:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings["CORS_ORIGINS"],
        allow_credentials=settings["CORS_ALLOW_CREDENTIALS"],
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )

app.add_middleware(RequestIDMiddleware)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RateLimitMiddleware, store=rate_limit_store)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    """Log unhandled errors with the request id and return a safe 500.

    The response never leaks internals in production; clients get the request id
    so support can correlate it with the server log line.
    """
    request_id = get_request_id() or "-"
    logger.exception(
        "Unhandled error on %s %s (request_id=%s)",
        request.method,
        request.url.path,
        request_id,
    )
    detail = "Internal server error"
    if not settings["IS_PRODUCTION"]:
        detail = f"{type(exc).__name__}: {exc}"
    return JSONResponse(
        status_code=500,
        content={"detail": detail, "request_id": request_id},
        headers={"X-Request-ID": request_id},
    )

from routes import applications, auth, bookings, chat, notifications, reviews, services, tasks, users, wallet
from routes import customer, tasker
from routes import addresses, favorites
from routes.admin import main as admin_router

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])

# Admin endpoints
app.include_router(admin_router.router, prefix="/api/admin", tags=["admin"])
from routes.admin import extra as admin_extra
app.include_router(admin_extra.router, prefix="/api/admin", tags=["admin"])
from routes.admin import analytics as admin_analytics
app.include_router(admin_analytics.router, prefix="/api/admin", tags=["admin"])

# KYC + support (user-facing)
from routes import kyc_support
app.include_router(kyc_support.kyc_router, prefix="/api/kyc", tags=["kyc"])
app.include_router(kyc_support.support_router, prefix="/api/support", tags=["support"])

# Customer endpoints
app.include_router(customer.router, prefix="/api/customer", tags=["customer"])
app.include_router(tasks.router, prefix="/api/tasks", tags=["tasks"])
app.include_router(bookings.router, prefix="/api/bookings", tags=["bookings"])

# Tasker endpoints
app.include_router(tasker.router, prefix="/api/tasker", tags=["tasker"])
app.include_router(services.router, prefix="/api/services", tags=["services"])
app.include_router(applications.router, prefix="/api/applications", tags=["applications"])

# Shared endpoints
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(chat.router, prefix="/api/chat", tags=["chat"])
app.include_router(reviews.router, prefix="/api/reviews", tags=["reviews"])
app.include_router(wallet.router, prefix="/api/wallet", tags=["wallet"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["notifications"])
app.include_router(favorites.router, prefix="/api/favorites", tags=["favorites"])
app.include_router(addresses.router, prefix="/api/addresses", tags=["addresses"])
from routes import safety
app.include_router(safety.router, prefix="/api/safety", tags=["safety"])

# Serve uploaded task images
from utils.file_storage import UPLOAD_DIR
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
# Mount at parent 'uploads' directory so /uploads/tasks/... URLs work correctly
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


@app.get("/")
def root():
    return {
        "message": "TaskTeddy Backend API",
        "status": "running",
        "environment": settings["ENVIRONMENT"],
        "database": "PostgreSQL",
    }


@app.get("/api/health")
def health():
    try:
        health_check()
        return {
            "status": "healthy",
            "database": "connected",
            "environment": settings["ENVIRONMENT"],
            "timestamp": datetime.utcnow().isoformat(),
        }
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "unhealthy",
                "database": f"error: {exc}",
                "environment": settings["ENVIRONMENT"],
                "timestamp": datetime.utcnow().isoformat(),
            },
        )


if __name__ == "__main__":
    uvicorn.run(
        "server:app",
        host=settings["HOST"],
        port=settings["PORT"],
        reload=not settings["IS_PRODUCTION"],
    )
