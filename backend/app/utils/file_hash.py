import hashlib


def calculate_sha256(file_bytes: bytes) -> str:
    """Return the SHA-256 hash for uploaded image bytes."""
    return hashlib.sha256(file_bytes).hexdigest()