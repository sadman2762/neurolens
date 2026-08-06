from datetime import datetime, timezone
from typing import Any

from fastapi import HTTPException, status
from google.cloud import firestore
from google.cloud.firestore_v1.base_document import DocumentSnapshot

from app.core.firebase_admin import db


class CreditService:
    FREE_MONTHLY_CREDITS = 20
    PREMIUM_MONTHLY_CREDITS = 500

    def __init__(self) -> None:
        self._users = db.collection("users")

    def reserve_credit(
        self,
        *,
        uid: str,
        request_id: str,
    ) -> dict[str, Any]:
        user_ref = self._users.document(uid)
        request_ref = user_ref.collection("ai_requests").document(request_id)
        transaction = db.transaction()

        @firestore.transactional
        def reserve(transaction: firestore.Transaction) -> dict[str, Any]:
            request_snapshot = request_ref.get(transaction=transaction)

            if request_snapshot.exists:
                request_data = request_snapshot.to_dict() or {}

                return {
                    "duplicate": True,
                    "status": request_data.get("status", "unknown"),
                    "creditsRemaining": request_data.get(
                        "creditsRemainingAfterReservation",
                    ),
                }

            user_snapshot: DocumentSnapshot = user_ref.get(
                transaction=transaction,
            )

            if not user_snapshot.exists:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User profile was not found.",
                )

            data = user_snapshot.to_dict() or {}
            now = datetime.now(timezone.utc)

            plan = str(data.get("plan", "free")).lower()
            credits_remaining = int(data.get("creditsRemaining", 0))
            credits_used = int(data.get("creditsUsed", 0))
            credit_reset_at = data.get("creditResetAt")

            monthly_limit = self._monthly_limit_for_plan(plan)

            if self._should_reset(
                credit_reset_at=credit_reset_at,
                now=now,
            ):
                credits_remaining = monthly_limit
                credits_used = 0
                credit_reset_at = self._next_month_start(now)

            if credits_remaining <= 0:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You do not have enough AI credits.",
                )

            new_remaining = credits_remaining - 1
            new_used = credits_used + 1

            transaction.update(
                user_ref,
                {
                    "creditsRemaining": new_remaining,
                    "creditsUsed": new_used,
                    "creditResetAt": credit_reset_at,
                    "updatedAt": now,
                },
            )

            transaction.set(
                request_ref,
                {
                    "requestId": request_id,
                    "type": "vision",
                    "status": "reserved",
                    "plan": plan,
                    "creditsCharged": 1,
                    "creditsRemainingAfterReservation": new_remaining,
                    "createdAt": now,
                    "updatedAt": now,
                },
            )

            return {
                "duplicate": False,
                "status": "reserved",
                "plan": plan,
                "monthlyLimit": monthly_limit,
                "creditsRemaining": new_remaining,
                "creditsUsed": new_used,
                "creditResetAt": credit_reset_at,
            }

        return reserve(transaction)

    def complete_request(
        self,
        *,
        uid: str,
        request_id: str,
    ) -> None:
        request_ref = (
            self._users.document(uid)
            .collection("ai_requests")
            .document(request_id)
        )

        transaction = db.transaction()

        @firestore.transactional
        def complete(transaction: firestore.Transaction) -> None:
            snapshot = request_ref.get(transaction=transaction)

            if not snapshot.exists:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="AI request reservation was not found.",
                )

            data = snapshot.to_dict() or {}
            current_status = str(data.get("status", ""))

            if current_status == "completed":
                return

            if current_status != "reserved":
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=(
                        "AI request cannot be completed from its "
                        f"current state: {current_status}."
                    ),
                )

            transaction.update(
                request_ref,
                {
                    "status": "completed",
                    "completedAt": datetime.now(timezone.utc),
                    "updatedAt": datetime.now(timezone.utc),
                },
            )

        complete(transaction)

    def refund_credit(
        self,
        *,
        uid: str,
        request_id: str,
        reason: str,
    ) -> bool:
        user_ref = self._users.document(uid)
        request_ref = user_ref.collection("ai_requests").document(request_id)
        transaction = db.transaction()

        @firestore.transactional
        def refund(transaction: firestore.Transaction) -> bool:
            request_snapshot = request_ref.get(transaction=transaction)

            if not request_snapshot.exists:
                return False

            request_data = request_snapshot.to_dict() or {}
            current_status = str(request_data.get("status", ""))

            if current_status == "refunded":
                return False

            if current_status != "reserved":
                return False

            user_snapshot = user_ref.get(transaction=transaction)

            if not user_snapshot.exists:
                return False

            user_data = user_snapshot.to_dict() or {}

            credits_remaining = int(
                user_data.get("creditsRemaining", 0),
            )
            credits_used = int(
                user_data.get("creditsUsed", 0),
            )

            now = datetime.now(timezone.utc)

            transaction.update(
                user_ref,
                {
                    "creditsRemaining": credits_remaining + 1,
                    "creditsUsed": max(0, credits_used - 1),
                    "updatedAt": now,
                },
            )

            transaction.update(
                request_ref,
                {
                    "status": "refunded",
                    "refundReason": reason[:500],
                    "refundedAt": now,
                    "updatedAt": now,
                },
            )

            return True

        return refund(transaction)

    def _monthly_limit_for_plan(self, plan: str) -> int:
        if plan == "premium":
            return self.PREMIUM_MONTHLY_CREDITS

        return self.FREE_MONTHLY_CREDITS

    def _should_reset(
        self,
        *,
        credit_reset_at: Any,
        now: datetime,
    ) -> bool:
        if not isinstance(credit_reset_at, datetime):
            return True

        if credit_reset_at.tzinfo is None:
            credit_reset_at = credit_reset_at.replace(
                tzinfo=timezone.utc,
            )

        return now >= credit_reset_at

    def _next_month_start(self, now: datetime) -> datetime:
        if now.month == 12:
            return datetime(
                now.year + 1,
                1,
                1,
                tzinfo=timezone.utc,
            )

        return datetime(
            now.year,
            now.month + 1,
            1,
            tzinfo=timezone.utc,
        )


credit_service = CreditService()