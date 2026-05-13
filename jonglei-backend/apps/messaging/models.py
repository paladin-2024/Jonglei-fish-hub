import uuid
from django.db import models
from django.conf import settings


class Thread(models.Model):
    id      = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing = models.ForeignKey(
        'marketplace.FishListing', on_delete=models.CASCADE,
        related_name='threads', null=True, blank=True,
    )
    buyer  = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='buyer_threads',
    )
    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='seller_threads',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'message_threads'
        ordering = ['-updated_at']
        unique_together = [['listing', 'buyer']]
        indexes = [
            models.Index(fields=['buyer']),
            models.Index(fields=['seller']),
        ]

    def __str__(self):
        return f'Thread {self.id}: {self.buyer} ↔ {self.seller}'


class Message(models.Model):
    id      = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    thread  = models.ForeignKey(Thread, on_delete=models.CASCADE, related_name='messages')
    sender  = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sent_messages',
    )
    body    = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'messages'
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['thread', 'is_read']),
        ]

    def __str__(self):
        return f'{self.sender} → {self.thread_id}: {self.body[:40]}'
