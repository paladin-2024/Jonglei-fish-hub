def notify_user(recipient, title: str, body: str, data: dict | None = None):
    """Create a DB notification record and send an FCM push synchronously (if token exists)."""
    from .models import Notification
    from .fcm import send_push
    Notification.objects.create(recipient=recipient, title=title, body=body)
    token = getattr(recipient, 'fcm_token', None)
    if token:
        try:
            send_push(token, title, body, data or {})
        except Exception:
            pass


def notify_role(role: str, title: str, body: str):
    """Broadcast a DB notification to all users with a given role (no individual FCM)."""
    from .models import Notification
    Notification.objects.create(target_role=role, title=title, body=body)
