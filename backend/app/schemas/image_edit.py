from pydantic import BaseModel, Field


class ImageEditHealthResponse(BaseModel):
    status: str = "ok"
    service: str = "image-edit"


class RemoveObjectResponse(BaseModel):
    success: bool
    edited_image_base64: str | None = None
    mime_type: str | None = None
    model: str | None = None
    processing_time_ms: int | None = Field(
        default=None,
        ge=0,
    )
    message: str | None = None