import logging
from typing import Any

from fastapi import APIRouter, Depends, File, Header, HTTPException, UploadFile, status

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
    request_id: str | None = Header(
        default=None,
        alias="X-Request-ID",
    ),
) -> VisionMetadata:
    uid = current_user["uid"]
    clean_request_id = (request_id or "").strip()

    if not clean_request_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Request-ID header is required.",
        )

    if len(clean_request_id) > 128:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="X-Request-ID is too long.",
        )

    logger.info(
        "Vision request received from Firebase user %s with request ID %s",
        uid,
        clean_request_id,
    )

    image_bytes = await validate_uploaded_image(image)

    reservation = credit_service.reserve_credit(
        uid=uid,
        request_id=clean_request_id,
    )

    if reservation.get("duplicate") is True:
        request_status = str(reservation.get("status", ""))

        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "This AI request has already been submitted "
                f"with status: {request_status}."
            ),
        )

    try:
        metadata = await vision_service.analyze_image(image_bytes)

        credit_service.complete_request(
            uid=uid,
            request_id=clean_request_id,
        )

        logger.info(
            "Vision analysis completed for user %s. Remaining credits: %s",
            uid,
            reservation["creditsRemaining"],
        )

        return metadata
    except Exception as error:
        refunded = credit_service.refund_credit(
            uid=uid,
            request_id=clean_request_id,
            reason=str(error),
        )

        logger.exception(
            "Vision analysis failed for user %s and request %s. "
            "Credit refunded: %s",
            uid,
            clean_request_id,
            refunded,
        )

        raise