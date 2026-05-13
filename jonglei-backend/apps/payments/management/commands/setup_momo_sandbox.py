"""
Run once: python manage.py setup_momo_sandbox --subscription-key YOUR_PRIMARY_KEY
"""
import uuid
import requests
from django.core.management.base import BaseCommand

SANDBOX = 'https://sandbox.momodeveloper.mtn.com'


class Command(BaseCommand):
    help = 'Create MTN MoMo sandbox API user + key and print credentials'

    def add_arguments(self, parser):
        parser.add_argument('--subscription-key', required=True)

    def handle(self, *args, **options):
        sub_key   = options['subscription_key']
        user_id   = str(uuid.uuid4())

        # 1. Create API user
        r = requests.post(
            f'{SANDBOX}/v1_0/apiuser',
            json={'providerCallbackHost': 'localhost'},
            headers={
                'X-Reference-Id':            user_id,
                'Ocp-Apim-Subscription-Key': sub_key,
                'Content-Type':             'application/json',
            },
            timeout=15,
        )
        if r.status_code not in (200, 201):
            self.stdout.write(self.style.ERROR(f'Failed to create API user: {r.status_code} {r.text}'))
            return

        # 2. Create API key
        r2 = requests.post(
            f'{SANDBOX}/v1_0/apiuser/{user_id}/apikey',
            headers={
                'Ocp-Apim-Subscription-Key': sub_key,
                'Content-Type':             'application/json',
            },
            timeout=15,
        )
        if r2.status_code not in (200, 201):
            self.stdout.write(self.style.ERROR(f'Failed to create API key: {r2.status_code} {r2.text}'))
            return

        api_key = r2.json().get('apiKey', '')
        self.stdout.write(self.style.SUCCESS('Paste these into jonglei-backend/.env:'))
        self.stdout.write(f'MOMO_SUBSCRIPTION_KEY={sub_key}')
        self.stdout.write(f'MOMO_API_USER_ID={user_id}')
        self.stdout.write(f'MOMO_API_KEY={api_key}')
