import uuid
from django.db import models
from django.conf import settings


class Notification(models.Model):
    ROLE_CHOICES = [
        ('ALL',             'All Users'),
        ('TRADER',          'Traders'),
        ('BUYER',           'Buyers'),
        ('TRANSPORTER',     'Transporters'),
        ('BORDER_OFFICIAL', 'Border Officials'),
    ]

    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recipient   = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='notifications', null=True, blank=True,
        help_text='Null = broadcast to a role group',
    )
    target_role = models.CharField(max_length=20, choices=ROLE_CHOICES, null=True, blank=True)
    title       = models.CharField(max_length=255)
    body        = models.TextField()
    is_read     = models.BooleanField(default=False)
    sent_by     = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        related_name='sent_notifications', null=True, blank=True,
    )
    created_at  = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']
        indexes  = [
            models.Index(fields=['recipient', 'is_read']),
            models.Index(fields=['target_role', 'created_at']),
        ]

    def __str__(self):
        return f'[{self.target_role or self.recipient}] {self.title}'
