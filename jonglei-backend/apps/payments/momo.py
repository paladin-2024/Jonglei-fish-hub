import uuid
import base64
import logging
import requests
from django.conf import settings

logger = logging.getLogger(__name__)

SANDBOX_BASE  = 'https://sandbox.momodeveloper.mtn.com'
PROD_BASE     = 'https://proxy.momoapi.mtn.com'


def _base_url():
    return SANDBOX_BASE if getattr(settings, 'MOMO_ENVIRONMENT', 'sandbox') == 'sandbox' else PROD_BASE


def _sub_key():
    return getattr(settings, 'MOMO_SUBSCRIPTION_KEY', '')


def _api_user():
    return getattr(settings, 'MOMO_API_USER_ID', '')


def _api_key():
    return getattr(settings, 'MOMO_API_KEY', '')


def _credentials_ready():
    return bool(_sub_key() and _api_user() and _api_key())


def get_access_token():
    """Fetch OAuth2 bearer token for Collections."""
    creds = base64.b64encode(f'{_api_user()}:{_api_key()}'.encode()).decode()
    r = requests.post(
        f'{_base_url()}/collection/token/',
        headers={
            'Authorization': f'Basic {creds}',
            'Ocp-Apim-Subscription-Key': _sub_key(),
        },
        timeout=10,
    )
    r.raise_for_status()
    return r.json()['access_token']


def request_to_pay(payer_phone: str, amount: str, currency: str, reference_id: str, note: str = '') -> bool:
    """
    Initiate a MoMo Collection request.
    Returns True if request was accepted (status 202), False otherwise.
    In mock mode (no credentials) returns True immediately.
    """
    if not _credentials_ready():
        logger.info('[MOMO MOCK] requesttopay %s %s %s — accepted (mock)', amount, currency, payer_phone)
        return True
    try:
        token = get_access_token()
        r = requests.post(
            f'{_base_url()}/collection/v1_0/requesttopay',
            json={
                'amount':         str(amount),
                'currency':       currency,
                'externalId':     reference_id,
                'payer':          {'partyIdType': 'MSISDN', 'partyId': payer_phone.lstrip('+')},
                'payerMessage':   note or 'Jonglei Fish Hub payment',
                'payeeNote':      note or 'Fish order payment',
            },
            headers={
                'Authorization':             f'Bearer {token}',
                'X-Reference-Id':             reference_id,
                'X-Target-Environment':       getattr(settings, 'MOMO_ENVIRONMENT', 'sandbox'),
                'Ocp-Apim-Subscription-Key':  _sub_key(),
                'Content-Type':              'application/json',
            },
            timeout=15,
        )
        return r.status_code == 202
    except Exception as exc:
        logger.warning('[MOMO] request_to_pay failed: %s', exc)
        return False


def get_payment_status(reference_id: str) -> str:
    """
    Poll the status of a payment.
    Returns 'SUCCESSFUL', 'FAILED', or 'PENDING'.
    In mock mode always returns 'SUCCESSFUL' after first call.
    """
    if not _credentials_ready():
        logger.info('[MOMO MOCK] status for %s → SUCCESSFUL (mock)', reference_id)
        return 'SUCCESSFUL'
    try:
        token = get_access_token()
        r = requests.get(
            f'{_base_url()}/collection/v1_0/requesttopay/{reference_id}',
            headers={
                'Authorization':             f'Bearer {token}',
                'X-Target-Environment':       getattr(settings, 'MOMO_ENVIRONMENT', 'sandbox'),
                'Ocp-Apim-Subscription-Key':  _sub_key(),
            },
            timeout=10,
        )
        r.raise_for_status()
        data = r.json()
        status = data.get('status', 'PENDING').upper()
        # MTN returns SUCCESSFUL / FAILED / PENDING
        if status in ('SUCCESSFUL', 'FAILED'):
            return status
        return 'PENDING'
    except Exception as exc:
        logger.warning('[MOMO] get_payment_status failed: %s', exc)
        return 'PENDING'
