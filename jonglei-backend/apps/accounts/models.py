import uuid
import random
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class User(AbstractUser):
    ROLE_CHOICES = [
        ('TRADER', 'Fish Trader'),
        ('BUYER', 'Buyer'),
        ('TRANSPORTER', 'Transporter'),
        ('DRIVER', 'Driver'),
        ('BORDER_OFFICIAL', 'Border Official'),
        ('MARKET_OFFICIAL', 'Market Official'),
        ('ADMIN', 'Administrator'),
    ]

    LANGUAGE_CHOICES = [
        ('EN', 'English'),
        ('AR', 'Arabic'),
        ('DIN', 'Dinka'),
        ('NUE', 'Nuer'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    username = models.CharField(max_length=150, blank=True, default='')
    phone_number = models.CharField(max_length=20, unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='TRADER')
    location = models.CharField(max_length=200, blank=True, default='')
    is_verified = models.BooleanField(default=False)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    total_transactions = models.IntegerField(default=0)
    preferred_language = models.CharField(
        max_length=3, choices=LANGUAGE_CHOICES, default='EN'
    )
    fcm_token  = models.CharField(max_length=512, blank=True, default='',
                                   help_text='Firebase Cloud Messaging device token')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['username']

    class Meta:
        db_table = 'users'
        indexes = [
            models.Index(fields=['phone_number']),
            models.Index(fields=['role']),
        ]

    def __str__(self):
        return f'{self.phone_number} ({self.get_role_display()})'

    @property
    def avg_rating(self):
        from apps.marketplace.models import SellerRating
        from django.db.models import Avg
        result = SellerRating.objects.filter(seller=self).aggregate(avg=Avg('stars'))
        return round(result['avg'] or 0, 1)

    @property
    def rating_count(self):
        from apps.marketplace.models import SellerRating
        return SellerRating.objects.filter(seller=self).count()


class OTP(models.Model):
    phone_number = models.CharField(max_length=20, db_index=True)
    code         = models.CharField(max_length=6)
    created_at   = models.DateTimeField(auto_now_add=True)
    expires_at   = models.DateTimeField()
    is_used      = models.BooleanField(default=False)

    class Meta:
        db_table = 'otps'
        ordering = ['-created_at']

    def __str__(self):
        return f'OTP {self.phone_number} [{self.code}]'

    @classmethod
    def generate(cls, phone_number: str) -> 'OTP':
        cls.objects.filter(phone_number=phone_number, is_used=False).update(is_used=True)
        code = str(random.randint(100000, 999999))
        return cls.objects.create(
            phone_number=phone_number,
            code=code,
            expires_at=timezone.now() + timezone.timedelta(minutes=10),
        )

    def is_valid(self, code: str) -> bool:
        return (
            not self.is_used
            and self.code == code
            and timezone.now() <= self.expires_at
        )
