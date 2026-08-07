from __future__ import annotations

from fastapi import UploadFile

from app.schemas.image_edit import RemoveObjectResponse
from app.services.openai_image_edit_service import (
    openai_image_edit_service,
)


class ImageEditService:
    """
    Coordinates image-editing requests.

    This service is intentionally provider-agnostic.
    Today it uses OpenAI for object removal, but later
    Gemini, Flux, or another provider can be swapped in
    without changing the API route.
    """

    async def remove_object(
        self,
        image: UploadFile,
        mask: UploadFile,
    ) -> RemoveObjectResponse:
        image_bytes = await image.read()
        mask_bytes = await mask.read()

        if not image_bytes:
            return RemoveObjectResponse(
                success=False,
                message="Image file is empty.",
            )

        if not mask_bytes:
            return RemoveObjectResponse(
                success=False,
                message="Mask file is empty.",
            )

        if not self._is_supported_image_type(
            image.content_type,
        ):
            return RemoveObjectResponse(
                success=False,
                message=(
                    "Unsupported image type. "
                    "Use JPEG, PNG, or WebP."
                ),
            )

        if not self._is_supported_mask_type(
            mask.content_type,
        ):
            return RemoveObjectResponse(
                success=False,
                message="Mask must be a PNG image.",
            )

        try:
            return await openai_image_edit_service.remove_object(
                image_bytes=image_bytes,
                mask_bytes=mask_bytes,
            )

        except ValueError as error:
            return RemoveObjectResponse(
                success=False,
                message=str(error),
            )

        except RuntimeError as error:
            return RemoveObjectResponse(
                success=False,
                message=str(error),
            )

        except Exception as error:
            return RemoveObjectResponse(
                success=False,
                message=(
                    "Unexpected image editing error: "
                    f"{type(error).__name__}"
                ),
            )

    @staticmethod
    def _is_supported_image_type(
        content_type: str | None,
    ) -> bool:
        if content_type is None:
            return False

        return content_type.lower() in {
            "image/jpeg",
            "image/jpg",
            "image/png",
            "image/webp",
        }

    @staticmethod
    def _is_supported_mask_type(
        content_type: str | None,
    ) -> bool:
        if content_type is None:
            return False

        return content_type.lower() == "image/png"


image_edit_service = ImageEditService()