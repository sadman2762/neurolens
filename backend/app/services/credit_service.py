from datetime import datetime, timezone

from fastapi import HTTPException, status
from google.cloud import firestore
from google.cloud.firestore_v1.base_document import DocumentSnapshot

from app.core.firebase_admin import db


class CreditService:
    FREE_MONTHLY_CREDITS = 20
    PREMIUM_MONTHLY_CREDITS = 500

    def __init__(self) -> None:
        self._users = db.collection("users")

    def consume_one_credit(self, uid: str) -> dict:
        user_ref = self._users.document(uid)
        transaction = db.transaction()

        @firestore.transactional
        def consume(transaction: firestore.Transaction) -> dict:
            snapshot: DocumentSnapshot = user_ref.get(
                transaction=transaction,
            )

            if not snapshot.exists:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User profile was not found.",
                )

            data = snapshot.to_dict() or {}

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

            return {
                "plan": plan,
                "monthlyLimit": monthly_limit,
                "creditsRemaining": new_remaining,
                "creditsUsed": new_used,
                "creditResetAt": credit_reset_at,
            }

        return consume(transaction)

    def _monthly_limit_for_plan(self, plan: str) -> int:
        if plan == "premium":
            return self.PREMIUM_MONTHLY_CREDITS

        return self.FREE_MONTHLY_CREDITS

    def _should_reset(
        self,
        *,
        credit_reset_at,
        now: datetime,
    ) -> bool:
        if credit_reset_at is None:
            return True

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