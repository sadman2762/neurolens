import hmac
import logging
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Header, HTTPException, status

from app.core.config import get_settings
from app.core.firebase_admin import db

logger = logging.getLogger(__name__)
settings = get_settings()

router = APIRouter(
    prefix="/api/v1/revenuecat",
    tags=["RevenueCat"],
)

PREMIUM_ENTITLEMENT_ID = "premium"
FREE_MONTHLY_CREDITS = 20
PREMIUM_MONTHLY_CREDITS = 500

PREMIUM_EVENTS = {
    "INITIAL_PURCHASE",
    "RENEWAL",
    "UNCANCELLATION",
    "PRODUCT_CHANGE",
    "PURCHASE_REDEEMED",
}

FREE_EVENTS = {
    "EXPIRATION",
}


@router.post("/webhook")
async def revenuecat_webhook(
    payload: dict[str, Any],
    authorization: str | None = Header(default=None),
) -> dict[str, str]:
    _verify_authorization(authorization)

    event = payload.get("event")

    if not isinstance(event, dict):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid RevenueCat webhook payload.",
        )

    event_type = str(event.get("type", "")).upper()
    event_id = str(event.get("id", ""))
    app_user_id = str(event.get("app_user_id", ""))
    entitlement_ids = event.get("entitlement_ids") or []

    if event_type == "TEST":
        logger.info("RevenueCat test webhook received.")
        return {"status": "ok"}

    if not event_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="RevenueCat event ID is missing.",
        )

    if not app_user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="RevenueCat App User ID is missing.",
        )

    if app_user_id.startswith("$RCAnonymousID:"):
        logger.warning(
            "Ignoring anonymous RevenueCat webhook event %s",
            event_id,
        )
        return {"status": "ignored"}

    if PREMIUM_ENTITLEMENT_ID not in entitlement_ids:
        logger.info(
            "Ignoring RevenueCat event %s without premium entitlement.",
            event_id,
        )
        return {"status": "ignored"}

    event_ref = db.collection("revenuecat_webhook_events").document(
        event_id,
    )
    event_snapshot = event_ref.get()

    if event_snapshot.exists:
        logger.info(
            "RevenueCat webhook event %s already processed.",
            event_id,
        )
        return {"status": "duplicate"}

    if event_type in PREMIUM_EVENTS:
        _activate_premium(app_user_id, event)
    elif event_type in FREE_EVENTS:
        _deactivate_premium(app_user_id)
    else:
        logger.info(
            "RevenueCat event %s ignored: %s",
            event_id,
            event_type,
        )

    event_ref.set(
        {
            "eventId": event_id,
            "eventType": event_type,
            "appUserId": app_user_id,
            "processedAt": datetime.now(timezone.utc),
        },
    )

    return {"status": "ok"}


def _verify_authorization(authorization: str | None) -> None:
    expected = settings.revenuecat_webhook_secret.strip()

    if not expected:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="RevenueCat webhook is not configured.",
        )

    received = (authorization or "").strip()

    if not hmac.compare_digest(received, expected):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid RevenueCat webhook authorization.",
        )


def _activate_premium(
    uid: str,
    event: dict[str, Any],
) -> None:
    user_ref = db.collection("users").document(uid)
    snapshot = user_ref.get()

    if not snapshot.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile was not found.",
        )

    expiration_at_ms = event.get("expiration_at_ms")

    premium_expires_at = None

    if isinstance(expiration_at_ms, int):
        premium_expires_at = datetime.fromtimestamp(
            expiration_at_ms / 1000,
            tz=timezone.utc,
        )

    user_ref.update(
        {
            "plan": "premium",
            "creditsRemaining": PREMIUM_MONTHLY_CREDITS,
            "creditsUsed": 0,
            "premiumExpiresAt": premium_expires_at,
            "updatedAt": datetime.now(timezone.utc),
        },
    )

    logger.info(
        "Premium activated for Firebase user %s",
        uid,
    )


def _deactivate_premium(uid: str) -> None:
    user_ref = db.collection("users").document(uid)
    snapshot = user_ref.get()

    if not snapshot.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile was not found.",
        )

    user_ref.update(
        {
            "plan": "free",
            "creditsRemaining": FREE_MONTHLY_CREDITS,
            "creditsUsed": 0,
            "premiumExpiresAt": None,
            "updatedAt": datetime.now(timezone.utc),
        },
    )

    logger.info(
        "Premium removed from Firebase user %s",
        uid,
    )