import logging
from django.conf import settings

logger = logging.getLogger(__name__)


def send_otp_sms(phone_number: str, code: str) -> bool:
    """
    Send OTP via Africa's Talking.
    In sandbox mode (AT_USERNAME=sandbox) the SMS appears in the AT web simulator
    at https://simulator.africastalking.com — no real SMS is sent.
    Switch AT_USERNAME + AT_API_KEY to live credentials for production.
    """
    username = getattr(settings, 'AT_USERNAME', None)
    api_key  = getattr(settings, 'AT_API_KEY',  None)

    if not username or not api_key:
        # Fallback: just log so development works without AT credentials
        logger.info('OTP for %s: %s  (AT not configured — log-only mode)', phone_number, code)
        return True

    try:
        import africastalking
        africastalking.initialize(username, api_key)
        sms = africastalking.SMS
        response = sms.send(
            message=f'Your Jonglei Fish Hub code is: {code}. Expires in 10 minutes.',
            recipients=[phone_number],
        )
        logger.info('AT SMS response: %s', response)
        return True
    except Exception as exc:
        logger.warning('AT SMS failed for %s: %s', phone_number, exc)
        return False
