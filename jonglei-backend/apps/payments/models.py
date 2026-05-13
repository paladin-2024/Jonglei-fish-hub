import uuid
from django.db import models
from django.conf import settings


class Payment(models.Model):
    STATUS_CHOICES = [
        ('PENDING',    'Pending'),
        ('SUCCESSFUL', 'Successful'),
        ('FAILED',     'Failed'),
    ]
    id             = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order          = models.OneToOneField('marketplace.Order', on_delete=models.PROTECT, related_name='payment')
    payer_phone    = models.CharField(max_length=20)
    amount         = models.DecimalField(max_digits=14, decimal_places=2)
    currency       = models.CharField(max_length=5, default='EUR')  # EUR for sandbox, UGX for production
    momo_reference = models.UUIDField(default=uuid.uuid4)  # X-Reference-Id sent to MTN
    status         = models.CharField(max_length=12, choices=STATUS_CHOICES, default='PENDING')
    provider_msg   = models.TextField(blank=True, default='')
    created_at     = models.DateTimeField(auto_now_add=True)
    updated_at     = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'payments'
        ordering = ['-created_at']

    def __str__(self):
        return f'Payment {self.id} [{self.status}] — {self.amount} {self.currency}'
