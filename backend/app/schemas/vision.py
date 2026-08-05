from pydantic import BaseModel, Field


class VisionMetadata(BaseModel):
    image_hash: str = Field(
        ...,
        description="SHA-256 hash of the uploaded image.",
    )

    caption: str = Field(
        ...,
        description="Short natural-language description of the image.",
    )

    scene: str = Field(
        ...,
        description="General environment or scene type.",
    )

    objects: list[str] = Field(
        default_factory=list,
        description="Important objects visible in the image.",
    )

    keywords: list[str] = Field(
        default_factory=list,
        description="Search-friendly keywords and short phrases.",
    )

    colors: list[str] = Field(
        default_factory=list,
        description="Important visible colors.",
    )

    visible_text: list[str] = Field(
        default_factory=list,
        description="Relevant text visibly present in the image.",
    )

    confidence: float = Field(
        ...,
        ge=0,
        le=1,
        description="Overall confidence between zero and one.",
    )

    model: str = Field(
        ...,
        description="Vision model used for analysis.",
    )

    processing_time_ms: int = Field(
        ...,
        ge=0,
        description="Total processing duration in milliseconds.",
    )


class VisionErrorResponse(BaseModel):
    detail: str