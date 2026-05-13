from celery import shared_task
from .fcm import send_push


@shared_task(bind=True, max_retries=3)
def notify_push(self, token: str, title: str, body: str, data: dict | None = None):
    """Generic FCM push with 3-retry backoff. Called by notify_user()."""
    try:
        send_push(token, title, body, data or {})
    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)


@shared_task(bind=True, max_retries=3)
def notify_order_status(self, buyer_fcm_token: str, order_id: str, status: str):
    labels = {
        'CONFIRMED':  ('Order Confirmed', f'Your order {order_id} has been confirmed.'),
        'IN_TRANSIT': ('On the Way',      f'Order {order_id} is now in transit.'),
        'CLEARED':    ('Cleared',         f'Order {order_id} has cleared the border.'),
        'CANCELLED':  ('Order Cancelled', f'Order {order_id} was cancelled.'),
    }
    title, body = labels.get(status, ('Order Update', f'Order {order_id} status: {status}'))
    try:
        send_push(buyer_fcm_token, title, body, {'order_id': order_id, 'status': status})
    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)


@shared_task(bind=True, max_retries=3)
def notify_job_accepted(self, transporter_fcm_token: str, job_id: str):
    try:
        send_push(
            transporter_fcm_token,
            'Job Accepted',
            f'Transport job {job_id} has been assigned to you.',
            {'job_id': job_id},
        )
    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)
