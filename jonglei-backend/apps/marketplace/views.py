import datetime
from decimal import Decimal

from rest_framework import status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from django.core.cache import cache

from .models import FishListing, Order, SellerRating
from .serializers import FishListingSerializer, OrderSerializer, SellerRatingSerializer
from apps.notifications.utils import notify_user


@api_view(['GET'])
@permission_classes([AllowAny])
def price_list(request):
    cached = cache.get('marketplace_prices')
    if cached:
        return Response(cached)

    # Group active listings by location+species and compute avg price
    listings = FishListing.objects.filter(status='ACTIVE')

    city_map = {}
    for listing in listings:
        city = listing.location.upper()
        if city not in city_map:
            city_map[city] = {}
        species = listing.species
        if species not in city_map[city]:
            city_map[city][species] = []
        city_map[city][species].append(float(listing.price_ssp))

    result = []
    for city, species_dict in city_map.items():
        prices = []
        for species, vals in species_dict.items():
            avg = sum(vals) / len(vals)
            prices.append({
                'species': species,
                'price_ssp': round(avg),
                'delta': 0,  # Historical delta requires price history table (Sprint 6)
            })
        result.append({
            'city': city,
            'prices': prices,
            'updated': datetime.datetime.now().strftime('%H:%M CAT'),
        })

    # Fall back to static data if no active listings
    if not result:
        result = _static_price_data()

    cache.set('marketplace_prices', result, 300)  # 5-minute TTL
    return Response(result)


def _static_price_data():
    return [
        {'city': 'BOR', 'region': 'Jonglei State', 'updated': 'Live', 'prices': [
            {'species': 'Nile Perch', 'price_ssp': 2450, 'delta': 80},
            {'species': 'Tilapia', 'price_ssp': 1800, 'delta': -20},
            {'species': 'Catfish', 'price_ssp': 1200, 'delta': 0},
        ]},
        {'city': 'JUBA', 'region': 'Central Equatoria', 'updated': 'Live', 'prices': [
            {'species': 'Nile Perch', 'price_ssp': 3200, 'delta': 150},
            {'species': 'Tilapia', 'price_ssp': 2000, 'delta': -50},
            {'species': 'Catfish', 'price_ssp': 1900, 'delta': 100},
        ]},
        {'city': 'WAU', 'region': 'W. Bahr el Ghazal', 'updated': 'Live', 'prices': [
            {'species': 'Nile Perch', 'price_ssp': 2800, 'delta': -30},
            {'species': 'Tilapia', 'price_ssp': 1500, 'delta': 0},
            {'species': 'Catfish', 'price_ssp': 1100, 'delta': 60},
        ]},
        {'city': 'MALAKAL', 'region': 'Upper Nile', 'updated': 'Live', 'prices': [
            {'species': 'Nile Perch', 'price_ssp': 3500, 'delta': 200},
            {'species': 'Tilapia', 'price_ssp': 1700, 'delta': -40},
            {'species': 'Catfish', 'price_ssp': 1050, 'delta': 0},
        ]},
        {'city': 'RENK', 'region': 'Upper Nile', 'updated': 'Live', 'prices': [
            {'species': 'Nile Perch', 'price_ssp': 2950, 'delta': 50},
            {'species': 'Tilapia', 'price_ssp': 1650, 'delta': 20},
            {'species': 'Catfish', 'price_ssp': 980, 'delta': -15},
        ]},
    ]


class FishListingViewSet(ModelViewSet):
    serializer_class = FishListingSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    filterset_fields = ['status', 'location', 'species']
    search_fields  = ['species', 'location', 'seller__username', 'description']
    ordering_fields = ['created_at', 'price_ssp', 'quantity_kg']
    ordering = ['-created_at']

    def get_queryset(self):
        qs = FishListing.objects.select_related('seller')
        params = self.request.query_params
        status_filter = params.get('status')
        species       = params.get('species')
        location      = params.get('location')
        mine          = params.get('mine')
        price_min     = params.get('price_min')
        price_max     = params.get('price_max')
        if status_filter:
            qs = qs.filter(status=status_filter.upper())
        if species:
            qs = qs.filter(species__icontains=species)
        if location:
            qs = qs.filter(location__icontains=location)
        if mine:
            qs = qs.filter(seller=self.request.user)
        if price_min:
            qs = qs.filter(price_ssp__gte=price_min)
        if price_max:
            qs = qs.filter(price_ssp__lte=price_max)
        return qs

    def perform_create(self, serializer):
        serializer.save(seller=self.request.user)

    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        listing = self.get_object()
        if listing.seller != request.user and not request.user.is_staff:
            return Response({'detail': 'Not your listing.'}, status=status.HTTP_403_FORBIDDEN)
        listing.status = 'ACTIVE'
        listing.save(update_fields=['status', 'updated_at'])
        return Response(FishListingSerializer(listing).data)

    @action(detail=True, methods=['post'])
    def remove(self, request, pk=None):
        listing = self.get_object()
        if listing.seller != request.user and not request.user.is_staff:
            return Response({'detail': 'Not your listing.'}, status=status.HTTP_403_FORBIDDEN)
        listing.status = 'REMOVED'
        listing.save(update_fields=['status', 'updated_at'])
        return Response(FishListingSerializer(listing).data)


class OrderViewSet(ModelViewSet):
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['status', 'listing__species']

    def get_queryset(self):
        user = self.request.user
        qs   = Order.objects.select_related('listing', 'listing__seller', 'buyer')
        role = getattr(user, 'role', '')
        if role == 'BUYER':
            return qs.filter(buyer=user)
        if role in ('TRADER', 'MARKET_OFFICIAL'):
            return qs.filter(listing__seller=user)
        return qs

    def perform_create(self, serializer):
        serializer.save()
        order = serializer.instance
        listing = order.listing
        listing.status = 'SOLD'
        listing.save(update_fields=['status', 'updated_at'])
        notify_user(
            listing.seller,
            'New Order Received',
            f'{order.buyer.username} ordered {order.quantity_kg} kg of {listing.species}.',
            {'order_id': str(order.id), 'type': 'order'},
        )

    @action(detail=True, methods=['post'])
    def confirm(self, request, pk=None):
        order = self.get_object()
        if order.listing.seller != request.user:
            return Response({'detail': 'Only the seller can confirm.'}, status=status.HTTP_403_FORBIDDEN)
        order.status = 'CONFIRMED'
        order.save(update_fields=['status', 'updated_at'])
        notify_user(
            order.buyer,
            'Order Confirmed',
            f'Your order for {order.listing.species} has been confirmed by the seller.',
            {'order_id': str(order.id), 'status': 'CONFIRMED'},
        )
        return Response(OrderSerializer(order).data)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        order = self.get_object()
        if order.buyer != request.user and order.listing.seller != request.user:
            return Response({'detail': 'Not authorised.'}, status=status.HTTP_403_FORBIDDEN)
        if order.status in ('CLEARED', 'IN_TRANSIT'):
            return Response({'detail': 'Cannot cancel in-transit or cleared order.'}, status=status.HTTP_400_BAD_REQUEST)
        order.status = 'CANCELLED'
        order.save(update_fields=['status', 'updated_at'])
        # Restore listing to ACTIVE if no other live orders remain
        listing = order.listing
        has_live = listing.orders.filter(
            status__in=('PENDING', 'CONFIRMED', 'IN_TRANSIT')
        ).exists()
        if not has_live:
            listing.status = 'ACTIVE'
            listing.save(update_fields=['status', 'updated_at'])
        notify_user(
            order.buyer,
            'Order Cancelled',
            f'Your order for {listing.species} has been cancelled.',
            {'order_id': str(order.id), 'status': 'CANCELLED'},
        )
        return Response(OrderSerializer(order).data)

    @action(detail=False, methods=['get'], url_path='my-orders')
    def my_orders(self, request):
        qs = Order.objects.filter(buyer=request.user).select_related('listing', 'listing__seller')
        status_filter = request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter.upper())
        page = self.paginate_queryset(qs)
        if page is not None:
            return self.get_paginated_response(OrderSerializer(page, many=True).data)
        return Response(OrderSerializer(qs, many=True).data)

    @action(detail=True, methods=['post'])
    def ship(self, request, pk=None):
        from apps.transport.models import Shipment, TransportJob

        order = self.get_object()
        if order.listing.seller != request.user:
            return Response({'detail': 'Only the seller can mark as shipped.'}, status=status.HTTP_403_FORBIDDEN)
        if order.status != 'CONFIRMED':
            return Response({'detail': 'Order must be CONFIRMED before shipping.'}, status=status.HTTP_400_BAD_REQUEST)
        order.status = 'IN_TRANSIT'
        order.save(update_fields=['status', 'updated_at'])

        # Auto-create Shipment + open TransportJob so drivers can see and accept this delivery
        try:
            shipment, _ = Shipment.objects.get_or_create(
                order=order,
                defaults={
                    'origin': order.listing.location or 'Bor',
                    'destination': order.buyer.location or 'Juba',
                    'status': 'IN_TRANSIT',
                },
            )
            if not TransportJob.objects.filter(shipment=shipment).exists():
                pay = (order.total_price * Decimal('0.05')) if order.total_price else None
                TransportJob.objects.create(shipment=shipment, pay_ssp=pay)
        except Exception:
            pass

        notify_user(
            order.buyer,
            'Order Shipped',
            f'Your order for {order.listing.species} is now on its way.',
            {'order_id': str(order.id), 'status': 'IN_TRANSIT'},
        )
        return Response(OrderSerializer(order).data)


class SellerRatingViewSet(ModelViewSet):
    serializer_class   = SellerRatingSerializer
    permission_classes = [IsAuthenticated]
    http_method_names  = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        seller_id = self.request.query_params.get('seller')
        qs = SellerRating.objects.select_related('buyer')
        if seller_id:
            qs = qs.filter(seller_id=seller_id)
        return qs

    def perform_create(self, serializer):
        order = serializer.validated_data.get('order')
        seller = order.listing.seller if order else None
        serializer.save(buyer=self.request.user, seller=seller)
