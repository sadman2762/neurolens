from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore


def initialize_firebase():
    if firebase_admin._apps:
        return

    # Render Secret File
    render_secret = Path("/etc/secrets/service_account.json")

    # Local development
    local_secret = (
        Path(__file__).resolve().parents[2]
        / "firebase"
        / "service_account.json"
    )

    if render_secret.exists():
        service_account_path = render_secret
    elif local_secret.exists():
        service_account_path = local_secret
    else:
        raise FileNotFoundError(
            "Firebase service_account.json not found."
        )

    cred = credentials.Certificate(service_account_path)

    firebase_admin.initialize_app(cred)


initialize_firebase()

db = firestore.client()