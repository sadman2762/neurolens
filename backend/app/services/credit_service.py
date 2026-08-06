from datetime import datetime, timezone

from fastapi import HTTPException, status
from google.cloud import firestore

from app.core.firebase_admin import db


class CreditService:
    def __init__(self) -> None:
        self._users = db.collection("users")

    def consume_one_credit(self, uid: str) -> dict:
        user_ref = self._users.document(uid)
        transaction = db.transaction()

        @firestore.transactional
        def consume(transaction: firestore.Transaction) -> dict:
            snapshot = user_ref.get(transaction=transaction)

            if not snapshot.exists:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User profile was not found.",
                )

            data = snapshot.to_dict() or {}

            plan = str(data.get("plan", "free"))
            credits_remaining = int(data.get("creditsRemaining", 0))
            credits_used = int(data.get("creditsUsed", 0))

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
                    "updatedAt": datetime.now(timezone.utc),
                },
            )

            return {
                "plan": plan,
                "creditsRemaining": new_remaining,
                "creditsUsed": new_used,
            }

        return consume(transaction)


credit_service = CreditService()