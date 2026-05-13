import uuid
import qrcode
import io
import base64
from django.db import models
from django.conf import settings


class BorderClearance(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('CLEARED', 'Cleared'),
        ('HELD',    'Held'),
    ]

    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    shipment    = models.ForeignKey('transport.Shipment', on_delete=models.PROTECT, related_name='clearances')
    checkpoint  = models.CharField(max_length=200)
    officer     = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True,
        on_delete=models.SET_NULL, related_name='clearances'
    )
    status      = models.CharField(max_length=8, choices=STATUS_CHOICES, default='PENDING')
    notes       = models.TextField(blank=True, default='')
    qr_code     = models.TextField(blank=True, default='', help_text='Base64-encoded QR PNG')
    cleared_at  = models.DateTimeField(null=True, blank=True)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'border_clearances'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['checkpoint']),
        ]

    def __str__(self):
        return f'Clearance {self.id} @ {self.checkpoint} [{self.status}]'

    def generate_qr(self):
        payload = f'JONGLEI:CLEARANCE:{self.id}'
        img = qrcode.make(payload)
        buf = io.BytesIO()
        img.save(buf, format='PNG')
        self.qr_code = base64.b64encode(buf.getvalue()).decode()

    def save(self, *args, **kwargs):
        if not self.qr_code:
            self.generate_qr()
        super().save(*args, **kwargs)
