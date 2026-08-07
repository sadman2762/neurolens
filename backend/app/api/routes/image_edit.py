from fastapi import APIRouter, File, UploadFile

from app.schemas.image_edit import (
    ImageEditHealthResponse,
    RemoveObjectResponse,
)
from app.services.image_edit_service import image_edit_service

router = APIRouter(
    prefix="/api/image-edit",
    tags=["image-edit"],
)


@router.get(
    "/health",
    response_model=ImageEditHealthResponse,
)
async def image_edit_health() -> ImageEditHealthResponse:
    return ImageEditHealthResponse()


@router.post(
    "/remove-object",
    response_model=RemoveObjectResponse,
)
async def remove_object(
    image: UploadFile = File(...),
    mask: UploadFile = File(...),
) -> RemoveObjectResponse:
    return await image_edit_service.remove_object(
        image=image,
        mask=mask,
    )