import os
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model


class Command(BaseCommand):
    help = 'Create superuser from env vars (idempotent)'

    def handle(self, *args, **options):
        User = get_user_model()
        phone    = os.environ.get('DJANGO_SUPERUSER_PHONE', '')
        password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', '')
        username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin')

        if not phone or not password:
            self.stdout.write('DJANGO_SUPERUSER_PHONE or DJANGO_SUPERUSER_PASSWORD not set — skipping')
            return

        if User.objects.filter(phone_number=phone).exists():
            self.stdout.write(f'Superuser {phone} already exists — skipping')
            return

        User.objects.create_superuser(
            phone_number=phone,
            username=username,
            password=password,
        )
        self.stdout.write(self.style.SUCCESS(f'Superuser {phone} created'))
