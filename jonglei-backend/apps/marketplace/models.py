import uuid
from django.db import models
from django.conf import settings


class FishListing(models.Model):
    STATUS_CHOICES = [
        ('DRAFT',   'Draft'),
        ('ACTIVE',  'Active'),
        ('SOLD',    'Sold'),
        ('REMOVED', 'Removed'),
    ]

    UNIT_CHOICES = [
        ('KG',     'Kilogram'),
        ('PIECE',  'Piece'),
        ('CRATE',  'Crate'),
        ('BUCKET', 'Bucket'),
    ]

    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    seller      = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='listings')
    species     = models.CharField(max_length=100)
    description = models.TextField(blank=True, default='')
    quantity_kg = models.DecimalField(max_digits=10, decimal_places=2)
    price_ssp   = models.DecimalField(max_digits=12, decimal_places=2, help_text='Price in SSP per unit')
    unit        = models.CharField(max_length=10, choices=UNIT_CHOICES, default='KG')
    location    = models.CharField(max_length=200)
    latitude    = models.FloatField(null=True, blank=True)
    longitude   = models.FloatField(null=True, blank=True)
    photo       = models.ImageField(upload_to='listings/', null=True, blank=True)
    status      = models.CharField(max_length=10, choices=STATUS_CHOICES, default='DRAFT')
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'fish_listings'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['seller']),
            models.Index(fields=['species']),
            models.Index(fields=['location']),
        ]

    def __str__(self):
        return f'{self.species} — {self.quantity_kg}kg @ {self.price_ssp} SSP ({self.status})'


class Order(models.Model):
    STATUS_CHOICES = [
        ('PENDING',    'Pending'),
        ('CONFIRMED',  'Confirmed'),
        ('IN_TRANSIT', 'In Transit'),
        ('CLEARED',    'Cleared'),
        ('CANCELLED',  'Cancelled'),
    ]

    id          = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing     = models.ForeignKey(FishListing, on_delete=models.PROTECT, related_name='orders')
    buyer       = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='orders')
    quantity_kg = models.DecimalField(max_digits=10, decimal_places=2)
    total_price = models.DecimalField(max_digits=14, decimal_places=2)
    status      = models.CharField(max_length=12, choices=STATUS_CHOICES, default='PENDING')
    note        = models.TextField(blank=True, default='')
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'orders'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['buyer']),
            models.Index(fields=['listing']),
        ]

    def __str__(self):
        return f'Order {self.id} — {self.listing.species} x{self.quantity_kg}kg [{self.status}]'


class SellerRating(models.Model):
    seller   = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                                  related_name='ratings_received')
    buyer    = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                                  related_name='ratings_given')
    order    = models.OneToOneField(Order, on_delete=models.CASCADE,
                                     related_name='rating', null=True, blank=True)
    stars    = models.PositiveSmallIntegerField()  # 1–5
    comment  = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'seller_ratings'
        ordering = ['-created_at']
        constraints = [
            models.CheckConstraint(condition=models.Q(stars__gte=1, stars__lte=5),
                                   name='stars_1_to_5'),
        ]

    def __str__(self):
        return f'{self.buyer} → {self.seller}: {self.stars}★'


class PriceHistory(models.Model):
    """Time-series price records. Table is promoted to a TimescaleDB hypertable via migration."""
    species     = models.CharField(max_length=100, db_index=True)
    location    = models.CharField(max_length=200, db_index=True)
    price_ssp   = models.DecimalField(max_digits=12, decimal_places=2)
    source      = models.CharField(max_length=50, default='market', help_text='market|reported|system')
    recorded_at = models.DateTimeField(db_index=True)

    class Meta:
        db_table = 'price_history'
        ordering = ['-recorded_at']
        indexes = [
            models.Index(fields=['species', 'recorded_at']),
            models.Index(fields=['location', 'recorded_at']),
        ]

    def __str__(self):
        return f'{self.species} @ {self.location} — {self.price_ssp} SSP ({self.recorded_at:%Y-%m-%d})'
