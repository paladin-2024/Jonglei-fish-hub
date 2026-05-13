from celery import shared_task
from django.core.cache import cache
from django.db.models import Avg
from .models import PriceHistory


@shared_task
def refresh_price_cache():
    """Pre-warm the price cache every 5 minutes (Celery Beat task)."""
    from datetime import timedelta
    from django.utils import timezone

    cutoff = timezone.now() - timedelta(days=30)
    prices = (
        PriceHistory.objects
        .filter(recorded_at__gte=cutoff)
        .values('species', 'location')
        .annotate(avg_price=Avg('price_ssp'))
    )
    cache.set('price_summary', list(prices), timeout=360)
