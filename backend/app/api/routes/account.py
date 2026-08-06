import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import auth

from app.core.auth import get_current_user
from app.core.firebase_admin import db

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1/account",
    tags=["Account"],
)


@router.delete("")
async def delete_account(
    current_user: dict[str, Any] = Depends(get_current_user),
) -> dict[str, str]:
    uid = current_user.get("uid")

    if not isinstance(uid, str) or not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authenticated user ID is missing.",
        )

    user_ref = db.collection("users").document(uid)

    try:
        await _delete_subcollection(
            user_ref.collection("ai_requests"),
        )

        user_ref.delete()

        auth.delete_user(uid)

        logger.info(
            "Deleted NeuroLens account for Firebase user %s",
            uid,
        )

        return {
            "status": "deleted",
        }
    except auth.UserNotFoundError:
        logger.warning(
            "Firebase Authentication user %s was already deleted.",
            uid,
        )

        return {
            "status": "deleted",
        }
    except HTTPException:
        raise
    except Exception as error:
        logger.exception(
            "Failed to delete NeuroLens account for user %s",
            uid,
        )

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not delete your account. Please try again.",
        ) from error


async def _delete_subcollection(collection_reference) -> None:
    batch_size = 100

    while True:
        documents = list(
            collection_reference.limit(batch_size).stream(),
        )

        if not documents:
            return

        batch = db.batch()

        for document in documents:
            batch.delete(document.reference)

        batch.commit()