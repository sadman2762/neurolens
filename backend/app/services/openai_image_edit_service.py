from io import BytesIO
from time import perf_counter

from openai import (
    APIConnectionError,
    APIStatusError,
    AsyncOpenAI,
)
from PIL import Image

from app.core.config import get_settings
from app.schemas.image_edit import RemoveObjectResponse


class OpenAIImageEditService:
    def __init__(self) -> None:
        settings = get_settings()

        self._model = settings.openai_image_model

        self._client = AsyncOpenAI(
            api_key=settings.openai_api_key.get_secret_value(),
        )

    async def remove_object(
        self,
        image_bytes: bytes,
        mask_bytes: bytes,
    ) -> RemoveObjectResponse:
        started_at = perf_counter()

        image_png, image_size = self._prepare_image(
            image_bytes,
        )

        mask_png = self._prepare_mask(
            mask_bytes,
            target_size=image_size,
        )

        image_file = (
            "image.png",
            image_png,
            "image/png",
        )

        mask_file = (
            "mask.png",
            mask_png,
            "image/png",
        )

        try:
            response = await self._client.images.edit(
                model=self._model,
                image=image_file,
                mask=mask_file,
                prompt=(
                    "Remove the object inside the transparent masked area. "
                    "Fill the removed region naturally using the surrounding "
                    "background. Preserve the rest of the photo as closely "
                    "as possible. Match the scene's lighting, texture, "
                    "perspective, shadows, colors, and depth of field. "
                    "Do not introduce a replacement object."
                ),
                output_format="png",
                quality="medium",
            )

        except APIConnectionError as error:
            raise RuntimeError(
                "Could not connect to the OpenAI image editing API.",
            ) from error

        except APIStatusError as error:
            detail = self._extract_api_error(
                error,
            )

            raise RuntimeError(
                "OpenAI image editing failed "
                f"with status {error.status_code}: "
                f"{detail}"
            ) from error

        if not response.data:
            raise RuntimeError(
                "OpenAI did not return an edited image.",
            )

        encoded = response.data[0].b64_json

        if not encoded:
            raise RuntimeError(
                "OpenAI returned an empty edited image.",
            )

        processing_time_ms = int(
            (perf_counter() - started_at) * 1000,
        )

        return RemoveObjectResponse(
            success=True,
            edited_image_base64=encoded,
            mime_type="image/png",
            model=self._model,
            processing_time_ms=processing_time_ms,
            message="Object removed successfully.",
        )

    @staticmethod
    def _prepare_image(
        image_bytes: bytes,
    ) -> tuple[bytes, tuple[int, int]]:
        try:
            with Image.open(
                BytesIO(image_bytes),
            ) as source:
                image = source.convert(
                    "RGBA",
                )

                width, height = image.size

                if width <= 0 or height <= 0:
                    raise ValueError(
                        "Input image has invalid dimensions.",
                    )

                buffer = BytesIO()

                image.save(
                    buffer,
                    format="PNG",
                )

                return (
                    buffer.getvalue(),
                    (width, height),
                )

        except ValueError:
            raise

        except Exception as error:
            raise ValueError(
                "Could not decode the input image.",
            ) from error

    @staticmethod
    def _prepare_mask(
        mask_bytes: bytes,
        *,
        target_size: tuple[int, int],
    ) -> bytes:
        try:
            with Image.open(
                BytesIO(mask_bytes),
            ) as source:
                mask = source.convert(
                    "RGBA",
                )

                #
                # Your MobileSAM mask currently uses:
                #
                # selected object:
                #     white + opaque
                #
                # background:
                #     transparent
                #
                # OpenAI editing uses transparent pixels
                # as the editable region.
                #
                # Therefore:
                #
                # selected object -> transparent
                # everything else -> opaque
                #

                mask = mask.resize(
                    target_size,
                    resample=Image.Resampling.NEAREST,
                )

                source_alpha = mask.getchannel(
                    "A",
                )

                inverted_alpha = source_alpha.point(
                    lambda value: 255 - value,
                )

                prepared = Image.new(
                    "RGBA",
                    target_size,
                    (
                        255,
                        255,
                        255,
                        255,
                    ),
                )

                prepared.putalpha(
                    inverted_alpha,
                )

                buffer = BytesIO()

                prepared.save(
                    buffer,
                    format="PNG",
                )

                return buffer.getvalue()

        except Exception as error:
            raise ValueError(
                "Could not decode or prepare the mask image.",
            ) from error

    @staticmethod
    def _extract_api_error(
        error: APIStatusError,
    ) -> str:
        response = getattr(
            error,
            "response",
            None,
        )

        if response is not None:
            try:
                body = response.json()

                if isinstance(body, dict):
                    api_error = body.get(
                        "error",
                    )

                    if isinstance(
                        api_error,
                        dict,
                    ):
                        message = api_error.get(
                            "message",
                        )

                        if message:
                            return str(
                                message,
                            )

                    message = body.get(
                        "message",
                    )

                    if message:
                        return str(
                            message,
                        )

            except Exception:
                pass

            try:
                text = response.text

                if text:
                    return text[:500]

            except Exception:
                pass

        message = str(error)

        return (
            message
            if message
            else "Unknown OpenAI API error."
        )


openai_image_edit_service = OpenAIImageEditService()