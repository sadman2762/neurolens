from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore


def initialize_firebase():
    if firebase_admin._apps:
        return

    service_account_path = (
        Path(__file__).resolve().parents[2]
        / "firebase"
        / "service_account.json"
    )

    cred = credentials.Certificate(service_account_path)

    firebase_admin.initialize_app(cred)


initialize_firebase()

db = firestore.client()