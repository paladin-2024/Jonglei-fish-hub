import uuid
from django.db import models
from django.conf import settings


class Shipment(models.Model):
    STATUS_CHOICES = [
        ('PENDING',    'Pending'),
        ('CONFIRMED',  'Confirmed'),
        ('IN_TRANSIT', 'In Transit'),
        ('CLEARED',    'Cleared'),
        ('DELIVERED',  'Delivered'),
        ('CANCELLED',  'Cancelled'),
    ]

    id             = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order          = models.OneToOneField('marketplace.Order', on_delete=models.PROTECT, related_name='shipment')
    carrier_name   = models.CharField(max_length=200, blank=True, default='')
    transporter    = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True,
        on_delete=models.SET_NULL, related_name='shipments'
    )
    origin         = models.CharField(max_length=200)
    destination    = models.CharField(max_length=200)
    status         = models.CharField(max_length=12, choices=STATUS_CHOICES, default='PENDING')
    progress       = models.DecimalField(max_digits=3, decimal_places=2, default=0,
                                         help_text='0.0–1.0 transit completion ratio')
    estimated_date = models.DateField(null=True, blank=True)
    created_at     = models.DateTimeField(auto_now_add=True)
    updated_at     = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'shipments'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['transporter']),
        ]

    def __str__(self):
        return f'Shipment {self.id} {self.origin} → {self.destination} [{self.status}]'


class TrackingEvent(models.Model):
    STAGE_CHOICES = [
        ('LOADED',        'Fish Loaded'),
        ('DEPARTED',      'Departed Origin'),
        ('EN_ROUTE',      'En Route'),
        ('AT_CHECKPOINT', 'At Checkpoint'),
        ('ARRIVED',       'Arrived Destination'),
        ('DELIVERED',     'Delivered'),
    ]

    id       = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    shipment = models.ForeignKey(Shipment, on_delete=models.CASCADE, related_name='events')
    stage    = models.CharField(max_length=16, choices=STAGE_CHOICES)
    note     = models.TextField(blank=True, default='')
    recorded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True,
        on_delete=models.SET_NULL, related_name='tracking_events'
    )
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'tracking_events'
        ordering = ['timestamp']

    def __str__(self):
        return f'{self.shipment_id} — {self.stage} at {self.timestamp}'


class TransportJob(models.Model):
    STATUS_CHOICES = [
        ('OPEN',      'Open'),
        ('ACCEPTED',  'Accepted'),
        ('ACTIVE',    'Active'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    ]

    id           = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    shipment     = models.OneToOneField(Shipment, on_delete=models.CASCADE, related_name='job')
    pay_ssp      = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    transporter  = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True,
        on_delete=models.SET_NULL, related_name='transport_jobs'
    )
    status       = models.CharField(max_length=10, choices=STATUS_CHOICES, default='OPEN')
    created_at   = models.DateTimeField(auto_now_add=True)
    updated_at   = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'transport_jobs'
        ordering = ['-created_at']
        indexes = [models.Index(fields=['status'])]

    def __str__(self):
        return f'Job {self.id} [{self.status}]'
