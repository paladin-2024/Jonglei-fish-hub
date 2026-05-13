import os
import logging
from django.conf import settings

logger = logging.getLogger(__name__)


def _get_app():
    import firebase_admin
    from firebase_admin import credentials
    if not firebase_admin._apps:
        cred_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', None)
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
        else:
            cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred)
    return firebase_admin.get_app()


def send_push(token: str, title: str, body: str, data: dict | None = None) -> bool:
    try:
        from firebase_admin import messaging
        _get_app()
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
