import logging
from typing import Any

from fastapi import APIRouter, Depends, File, UploadFile

from app.core.auth import get_current_user
from app.schemas.vision import VisionMetadata
from app.services.credit_service import credit_service
from app.services.image_validation_service import validate_uploaded_image
from app.services.vision_service import VisionService

logger = logging.getLogger(__name__)

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
    current_user: dict[str, Any] = Depends(get_current_user),
) -> VisionMetadata:
    uid = current_user["uid"]

    logger.info(
        "Vision request received from Firebase user %s",
        uid,
    )

    image_bytes = await validate_uploaded_image(image)

    metadata = await vision_service.analyze_image(image_bytes)

    credit_result = credit_service.consume_one_credit(uid)

    logger.info(
        "Vision analysis completed for user %s. Remaining credits: %s",
        uid,
        credit_result["creditsRemaining"],
    )

    return metadata