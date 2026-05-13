import os
import json
import logging
from django.conf import settings

logger = logging.getLogger(__name__)


def _get_app():
    import firebase_admin
    from firebase_admin import credentials
    if not firebase_admin._apps:
        # Option 1: JSON content stored directly in FIREBASE_CREDENTIALS_JSON env var
        cred_json = os.environ.get('FIREBASE_CREDENTIALS_JSON', '')
        # Option 2: path to a credentials file (local dev)
        cred_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', None)

        if cred_json:
            cred = credentials.Certificate(json.loads(cred_json))
        elif cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
        else:
            logger.warning('No Firebase credentials configured — push notifications disabled')
            return None
        firebase_admin.initialize_app(cred)
    return firebase_admin.get_app()


def send_push(token: str, title: str, body: str, data: dict | None = None) -> bool:
    try:
        from firebase_admin import messaging
        app = _get_app()
        if app is None:
            return False
        msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            token=token,
        )
        messaging.send(msg)
        return True
    except Exception as exc:
        logger.warning('FCM send failed: %s', exc)
        return False
