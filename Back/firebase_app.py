"""
Firebase support for the Jaclang backend.
Initializes Firebase Admin SDK and exposes Firestore and Auth helpers.
Uses GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_CREDENTIALS_PATH for credentials.
"""

import os
from typing import Optional

_firebase_app = None


def _get_credentials_path() -> Optional[str]:
    """Resolve path to service account JSON."""
    path = os.environ.get("FIREBASE_CREDENTIALS_PATH") or os.environ.get(
        "GOOGLE_APPLICATION_CREDENTIALS"
    )
    if path and os.path.isfile(path):
        return path
    return None


def init_firebase(credentials_path: Optional[str] = None) -> bool:
    """
    Initialize Firebase Admin SDK. Safe to call multiple times; only initializes once.
    Returns True if initialized (or already initialized), False if credentials missing.
    """
    global _firebase_app
    if _firebase_app is not None:
        return True

    import firebase_admin
    from firebase_admin import credentials

    path = credentials_path or _get_credentials_path()
    if not path:
        return False

    cred = credentials.Certificate(path)
    _firebase_app = firebase_admin.initialize_app(cred)
    return True


def is_initialized() -> bool:
    """Return whether Firebase has been initialized."""
    return _firebase_app is not None


def get_firestore():
    """Return Firestore client. Call init_firebase() first."""
    from firebase_admin import firestore
    return firestore.client()


def get_auth():
    """Return Firebase Auth client. Call init_firebase() first."""
    from firebase_admin import auth
    return auth


def get_app():
    """Return the Firebase app instance, or None if not initialized."""
    return _firebase_app


def server_timestamp():
    """Return a Firestore server timestamp sentinel."""
    from google.cloud.firestore import SERVER_TIMESTAMP
    return SERVER_TIMESTAMP
