import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.health import router as health_router
from app.api.routes.vision import router as vision_router
from app.core.config import get_settings
from app.core.firebase_admin import db
from app.api.routes.revenuecat import router as revenuecat_router
from app.api.routes.account import router as account_router

settings = get_settings()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)

logger = logging.getLogger("neurolens")

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="AI-powered image indexing backend for NeuroLens.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=settings.cors_origins != ["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(health_router)
app.include_router(vision_router)
app.include_router(revenuecat_router)
app.include_router(account_router)


@app.on_event("startup")
async def startup_event() -> None:
    logger.info(
        "Starting %s version %s in %s mode",
        settings.app_name,
        settings.app_version,
        settings.environment,
    )


@app.get("/")
async def root():
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "status": "running",
    }