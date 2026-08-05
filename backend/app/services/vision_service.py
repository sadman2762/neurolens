import base64
from io import BytesIO
from time import perf_counter

from openai import APIConnectionError, APIStatusError, AsyncOpenAI
from PIL import Image
from pydantic import BaseModel, Field

from app.core.config import get_settings
from app.schemas.vision import VisionMetadata
from app.utils.file_hash import calculate_sha256


class VisionAnalysis(BaseModel):
    caption: str = Field(
        description="A clear, searchable one-sentence description of the image.",
    )
    scene: str = Field(
        description="The main scene or environment, such as kitchen, street, office, or beach.",
    )
    objects: list[str] = Field(
        default_factory=list,
        description="Important visible objects, using short lowercase names.",
    )
    keywords: list[str] = Field(
        default_factory=list,
        description="Useful search keywords and short phrases describing the image.",
    )
    colors: list[str] = Field(
        default_factory=list,
        description="Important visible colors connected to major objects.",
    )
    visible_text: list[str] = Field(
        default_factory=list,
        description="Clearly readable text visible in the image.",
    )
    confidence: float = Field(
        ge=0,
        le=1,
        description="Overall confidence from zero to one.",
    )


class VisionService:
    def __init__(self) -> None:
        settings = get_settings()

        self._model = settings.openai_model
        self._client = AsyncOpenAI(
            api_key=settings.openai_api_key.get_secret_value(),
        )

    async def analyze_image(
        self,
        image_bytes: bytes,
    ) -> VisionMetadata:
        started_at = perf_counter()
        image_hash = calculate_sha256(image_bytes)

        mime_type = self._detect_mime_type(image_bytes)
        encoded_image = base64.b64encode(image_bytes).decode("utf-8")
        image_data_url = f"data:{mime_type};base64,{encoded_image}"

        try:
            response = await self._client.responses.parse(
                model=self._model,
                input=[
                    {
                        "role": "system",
                        "content": (
                            "You analyze personal photos for a local keyword "
                            "search application. Return accurate, concise, "
                            "search-friendly metadata. Do not identify unknown "
                            "people. Do not invent objects, text, colors, places, "
                            "brands, or events that are not visibly supported."
                        ),
                    },
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "input_text",
                                "text": (
                                    "Analyze this image for keyword search. "
                                    "Create one concise caption, identify the "
                                    "scene, important objects, useful keywords "
                                    "and short phrases, important object colors, "
                                    "and clearly readable visible text. "
                                    "Use lowercase singular object names where "
                                    "possible. Include combined phrases such as "
                                    "'red car' or 'black laptop' when supported. "
                                    "Remove duplicate and overly generic terms."
                                ),
                            },
                            {
                                "type": "input_image",
                                "image_url": image_data_url,
                                "detail": "auto",
                            },
                        ],
                    },
                ],
                text_format=VisionAnalysis,
            )
        except APIConnectionError as error:
            raise RuntimeError(
                "Could not connect to the OpenAI API.",
            ) from error
        except APIStatusError as error:
            raise RuntimeError(
                f"OpenAI API request failed with status {error.status_code}.",
            ) from error

        analysis = response.output_parsed

        if analysis is None:
            raise RuntimeError(
                "The vision model did not return valid structured metadata.",
            )

        processing_time_ms = int(
            (perf_counter() - started_at) * 1000,
        )

        return VisionMetadata(
            image_hash=image_hash,
            caption=analysis.caption.strip(),
            scene=analysis.scene.strip().lower(),
            objects=self._normalize_values(analysis.objects),
            keywords=self._normalize_values(analysis.keywords),
            colors=self._normalize_values(analysis.colors),
            visible_text=self._normalize_visible_text(
                analysis.visible_text,
            ),
            confidence=analysis.confidence,
            model=self._model,
            processing_time_ms=processing_time_ms,
        )

    @staticmethod
    def _detect_mime_type(image_bytes: bytes) -> str:
        with Image.open(BytesIO(image_bytes)) as image:
            image_format = (image.format or "").upper()

        mime_types = {
            "JPEG": "image/jpeg",
            "PNG": "image/png",
            "WEBP": "image/webp",
        }

        mime_type = mime_types.get(image_format)

        if mime_type is None:
            raise ValueError(
                f"Unsupported image format: {image_format or 'unknown'}",
            )

        return mime_type

    @staticmethod
    def _normalize_values(values: list[str]) -> list[str]:
        normalized: list[str] = []
        seen: set[str] = set()

        for value in values:
            cleaned = " ".join(value.lower().strip().split())

            if not cleaned or cleaned in seen:
                continue

            seen.add(cleaned)
            normalized.append(cleaned)

        return normalized

    @staticmethod
    def _normalize_visible_text(values: list[str]) -> list[str]:
        normalized: list[str] = []
        seen: set[str] = set()

        for value in values:
            cleaned = " ".join(value.strip().split())

            if not cleaned:
                continue

            comparison_value = cleaned.lower()

            if comparison_value in seen:
                continue

            seen.add(comparison_value)
            normalized.append(cleaned)

        return normalized