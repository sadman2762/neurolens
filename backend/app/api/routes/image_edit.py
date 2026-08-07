from fastapi import APIRouter

router = APIRouter(
    prefix="/api/image-edit",
    tags=["image-edit"],
)


@router.get("/health")
async def image_edit_health():
    return {
        "status": "ok",
        "service": "image-edit",
    }