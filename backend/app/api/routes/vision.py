from fastapi import APIRouter, File, UploadFile

from app.schemas.vision import VisionMetadata
from app.services.image_validation_service import validate_uploaded_image
from app.services.vision_service import VisionService

router = APIRouter(
    prefix="/api/v1/vision",
    tags=["Vision"],
)

vision_service = VisionService()


@router.post(
    "/analyze",
    response_model=VisionMetadata,
)
async def analyze_image(
    image: UploadFile = File(...),
) -> VisionMetadata:
    image_bytes = await validate_uploaded_image(image)

    return await vision_service.analyze_image(image_bytes)