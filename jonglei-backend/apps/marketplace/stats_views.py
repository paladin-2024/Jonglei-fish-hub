from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from django.core.cache import cache
from django.db.models import Sum, Count, Q


def get_stats():
    cached = cache.get('dashboard_stats')
    if cached:
        return cached

    from apps.accounts.models import User
    from apps.marketplace.models import FishListing, Order
    from apps.transport.models import Shipment, TransportJob
    from apps.clearance.models import BorderClearance

    stats = {
        'total_users':          User.objects.count(),
        'verified_users':       User.objects.filter(is_verified=True).count(),
        'total_traders':        User.objects.filter(role='TRADER').count(),
        'total_buyers':         User.objects.filter(role='BUYER').count(),
        'total_transporters':   User.objects.filter(role__in=['TRANSPORTER', 'DRIVER']).count(),
        'total_listings':       FishListing.objects.count(),
        'active_listings':      FishListing.objects.filter(status='ACTIVE').count(),
        'total_orders':         Order.objects.count(),
        'pending_orders':       Order.objects.filter(status='PENDING').count(),
        'confirmed_orders':     Order.objects.filter(status='CONFIRMED').count(),
        'total_revenue':        float(Order.objects.filter(status__in=['CONFIRMED', 'IN_TRANSIT', 'CLEARED']).aggregate(s=Sum('total_price'))['s'] or 0),
        'active_shipments':     Shipment.objects.filter(status='IN_TRANSIT').count(),
        'pending_clearances':   BorderClearance.objects.filter(status='PENDING').count(),
        'open_transport_jobs':  TransportJob.objects.filter(status='OPEN').count(),
    }

    cache.set('dashboard_stats', stats, 300)  # 5-minute TTL
    return stats


@api_view(['GET'])
@permission_classes([IsAdminUser])
def dashboard_stats(request):
    return Response(get_stats())


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def transporter_stats(request):
    """Stats for the authenticated transporter."""
    user = request.user
    from apps.transport.models import TransportJob
    active = TransportJob.objects.filter(
        transporter=user, status__in=['ACCEPTED', 'ACTIVE']
    ).count()
    completed = TransportJob.objects.filter(
        transporter=user, status='COMPLETED'
    ).count()
    return Response({
        'active_jobs': active,
        'completed_jobs': completed,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def border_stats(request):
    """Stats for the authenticated border official."""
    from apps.clearance.models import BorderClearance
    from django.utils import timezone
    today = timezone.now().date()
    pending = BorderClearance.objects.filter(status='PENDING').count()
    cleared_today = BorderClearance.objects.filter(
        status='CLEARED', cleared_at__date=today
    ).count()
    flagged = BorderClearance.objects.filter(status='HELD').count()
    recent = BorderClearance.objects.select_related('shipment').order_by(
        '-created_at'
    )[:5]
    from apps.clearance.serializers import BorderClearanceSerializer
    return Response({
        'pending_clearances': pending,
        'cleared_today': cleared_today,
        'flagged': flagged,
        'recent': BorderClearanceSerializer(recent, many=True).data,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_stats(request):
    """Personal stats for the authenticated trader/user."""
    user = request.user
    from .models import FishListing, Order
    from apps.transport.models import Shipment

    active_listings = FishListing.objects.filter(
        seller=user, status='ACTIVE'
    ).count()
    pending_orders = Order.objects.filter(
        listing__seller=user, status='PENDING'
    ).count()
    active_shipments = Shipment.objects.filter(
        order__listing__seller=user, status='IN_TRANSIT'
    ).count()

    return Response({
        'active_listings': active_listings,
        'pending_orders':  pending_orders,
        'active_shipments': active_shipments,
    })
