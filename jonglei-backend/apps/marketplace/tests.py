from decimal import Decimal

from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.marketplace.models import FishListing, Order, SellerRating

User = get_user_model()

# ─── Shared factories ─────────────────────────────────────────────────────────

def make_trader(n=1, **kw):
    return User.objects.create_user(
        phone_number=f'+211912TD{n:04d}',
        username=f'mkt_trader{n}',
        password='pass123',
        role='TRADER',
        location='Bor',
        **kw,
    )

def make_buyer(n=1, **kw):
    return User.objects.create_user(
        phone_number=f'+211913BY{n:04d}',
        username=f'mkt_buyer{n}',
        password='pass123',
        role='BUYER',
        location='Juba',
        **kw,
    )

def make_listing(seller, species='Tilapia', qty=50, price=1500, st='ACTIVE'):
    return FishListing.objects.create(
        seller=seller,
        species=species,
        quantity_kg=Decimal(str(qty)),
        price_ssp=Decimal(str(price)),
        location='Bor',
        status=st,
    )

# ─── FishListing model ────────────────────────────────────────────────────────

class FishListingModelTest(APITestCase):
    def setUp(self):
        self.trader = make_trader()

    def test_str_contains_species(self):
        listing = make_listing(self.trader, species='Nile Perch')
        self.assertIn('Nile Perch', str(listing))

    def test_default_status_is_draft(self):
        listing = FishListing.objects.create(
            seller=self.trader, species='Catfish',
            quantity_kg=Decimal('10'), price_ssp=Decimal('500'), location='Bor',
        )
        self.assertEqual(listing.status, 'DRAFT')

    def test_listing_has_uuid_pk(self):
        listing = make_listing(self.trader)
        import uuid
        self.assertIsInstance(listing.pk, uuid.UUID)


# ─── FishListing API ──────────────────────────────────────────────────────────

class FishListingAPITest(APITestCase):
    BASE = '/api/v1/marketplace/listings/'

    def setUp(self):
        self.trader = make_trader()
        self.buyer = make_buyer()
        self.listing = make_listing(self.trader)

    def test_list_requires_auth(self):
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_authenticated_user_can_list(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_200_OK)

    def test_filter_by_status_active(self):
        make_listing(self.trader, species='Perch', st='DRAFT')
        self.client.force_authenticate(self.buyer)
        r = self.client.get(self.BASE + '?status=ACTIVE')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        results = r.data.get('results', r.data)
        for item in results:
            self.assertEqual(item['status'], 'ACTIVE')

    def test_trader_can_create_listing(self):
        self.client.force_authenticate(self.trader)
        r = self.client.post(self.BASE, {
            'species': 'Catfish',
            'quantity_kg': '30',
            'price_ssp': '1200',
            'location': 'Panyagoor',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertEqual(r.data['species'], 'Catfish')
        self.assertEqual(r.data['status'], 'DRAFT')

    def test_create_sets_seller_to_current_user(self):
        self.client.force_authenticate(self.trader)
        r = self.client.post(self.BASE, {
            'species': 'Perch', 'quantity_kg': '10',
            'price_ssp': '800', 'location': 'Bor',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertEqual(str(r.data['seller']), str(self.trader.id))

    def test_publish_draft_listing(self):
        draft = make_listing(self.trader, st='DRAFT')
        self.client.force_authenticate(self.trader)
        r = self.client.post(f'{self.BASE}{draft.id}/publish/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        draft.refresh_from_db()
        self.assertEqual(draft.status, 'ACTIVE')

    def test_only_owner_can_publish(self):
        draft = make_listing(self.trader, st='DRAFT')
        self.client.force_authenticate(self.buyer)
        r = self.client.post(f'{self.BASE}{draft.id}/publish/')
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)

    def test_remove_active_listing(self):
        self.client.force_authenticate(self.trader)
        r = self.client.post(f'{self.BASE}{self.listing.id}/remove/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.listing.refresh_from_db()
        self.assertEqual(self.listing.status, 'REMOVED')

    def test_only_owner_can_remove(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.post(f'{self.BASE}{self.listing.id}/remove/')
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)


# ─── Order API ────────────────────────────────────────────────────────────────

class OrderAPITest(APITestCase):
    BASE = '/api/v1/marketplace/orders/'

    def setUp(self):
        self.trader = make_trader()
        self.buyer = make_buyer()
        self.listing = make_listing(self.trader, price=2500, qty=100)

    def _place_order(self, qty=20, buyer=None):
        self.client.force_authenticate(buyer or self.buyer)
        return self.client.post(self.BASE, {
            'listing': str(self.listing.id),
            'quantity_kg': str(qty),
        }, format='json')

    def _confirmed_order_id(self):
        """Place and confirm an order, return its id."""
        r = self._place_order()
        order_id = r.data['id']
        self.client.force_authenticate(self.trader)
        self.client.post(f'{self.BASE}{order_id}/confirm/')
        return order_id

    def test_buyer_can_place_order(self):
        r = self._place_order(qty=10)
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertEqual(r.data['status'], 'PENDING')

    def test_total_price_is_qty_times_price(self):
        r = self._place_order(qty=10)
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Decimal(r.data['total_price']), Decimal('2500') * 10)

    def test_unauthenticated_cannot_place_order(self):
        r = self.client.post(self.BASE, {
            'listing': str(self.listing.id), 'quantity_kg': '5',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_seller_can_confirm_order(self):
        r = self._place_order()
        order_id = r.data['id']
        self.client.force_authenticate(self.trader)
        r = self.client.post(f'{self.BASE}{order_id}/confirm/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data['status'], 'CONFIRMED')

    def test_only_seller_can_confirm(self):
        r = self._place_order()
        order_id = r.data['id']
        buyer2 = make_buyer(2)
        self.client.force_authenticate(buyer2)
        r = self.client.post(f'{self.BASE}{order_id}/confirm/')
        # OrderViewSet excludes other buyers' orders from queryset → 404
        self.assertEqual(r.status_code, status.HTTP_404_NOT_FOUND)

    def test_buyer_can_cancel_pending_order(self):
        r = self._place_order()
        order_id = r.data['id']
        self.client.force_authenticate(self.buyer)
        r = self.client.post(f'{self.BASE}{order_id}/cancel/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data['status'], 'CANCELLED')

    def test_ship_requires_confirmed_status(self):
        r = self._place_order()
        order_id = r.data['id']
        self.client.force_authenticate(self.trader)
        r = self.client.post(f'{self.BASE}{order_id}/ship/')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_ship_sets_order_in_transit(self):
        order_id = self._confirmed_order_id()
        self.client.force_authenticate(self.trader)
        r = self.client.post(f'{self.BASE}{order_id}/ship/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data['status'], 'IN_TRANSIT')

    def test_ship_auto_creates_shipment(self):
        from apps.transport.models import Shipment
        order_id = self._confirmed_order_id()
        self.client.force_authenticate(self.trader)
        self.client.post(f'{self.BASE}{order_id}/ship/')
        self.assertTrue(Shipment.objects.filter(order_id=order_id).exists())

    def test_ship_auto_creates_transport_job(self):
        from apps.transport.models import Shipment, TransportJob
        order_id = self._confirmed_order_id()
        self.client.force_authenticate(self.trader)
        self.client.post(f'{self.BASE}{order_id}/ship/')
        shipment = Shipment.objects.get(order_id=order_id)
        self.assertTrue(TransportJob.objects.filter(shipment=shipment).exists())

    def test_transport_job_pay_is_five_percent(self):
        from apps.transport.models import Shipment, TransportJob
        order_id = self._confirmed_order_id()
        self.client.force_authenticate(self.trader)
        self.client.post(f'{self.BASE}{order_id}/ship/')
        order = Order.objects.get(id=order_id)
        shipment = Shipment.objects.get(order=order)
        job = TransportJob.objects.get(shipment=shipment)
        self.assertEqual(job.pay_ssp, order.total_price * Decimal('0.05'))

    def test_only_seller_can_ship(self):
        order_id = self._confirmed_order_id()
        self.client.force_authenticate(self.buyer)
        r = self.client.post(f'{self.BASE}{order_id}/ship/')
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)

    def test_my_orders_returns_only_current_buyers_orders(self):
        self._place_order()
        buyer2 = make_buyer(2)
        listing2 = make_listing(make_trader(2), species='Perch')
        self.client.force_authenticate(buyer2)
        self.client.post(self.BASE, {
            'listing': str(listing2.id), 'quantity_kg': '5',
        }, format='json')
        self.client.force_authenticate(self.buyer)
        r = self.client.get(self.BASE + 'my-orders/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        results = r.data if isinstance(r.data, list) else r.data.get('results', [])
        for order in results:
            self.assertEqual(str(order['buyer']), str(self.buyer.id))


# ─── SellerRating API ─────────────────────────────────────────────────────────

class SellerRatingAPITest(APITestCase):
    BASE = '/api/v1/marketplace/ratings/'

    def setUp(self):
        self.trader = make_trader()
        self.buyer = make_buyer()
        listing = make_listing(self.trader)
        self.client.force_authenticate(self.buyer)
        order_r = self.client.post('/api/v1/marketplace/orders/', {
            'listing': str(listing.id), 'quantity_kg': '5',
        }, format='json')
        self.order_id = order_r.data['id']
        self.client.force_authenticate(self.trader)
        self.client.post(f'/api/v1/marketplace/orders/{self.order_id}/confirm/')

    def test_buyer_can_rate_seller(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.post(self.BASE, {
            'order': self.order_id,
            'stars': 4,
            'comment': 'Good quality fish',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertEqual(r.data['stars'], 4)

    def test_rating_sets_seller_from_order(self):
        self.client.force_authenticate(self.buyer)
        self.client.post(self.BASE, {
            'order': self.order_id, 'stars': 5,
        }, format='json')
        rating = SellerRating.objects.get(order_id=self.order_id)
        self.assertEqual(rating.seller, self.trader)
        self.assertEqual(rating.buyer, self.buyer)

    def test_stars_must_be_1_to_5(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.post(self.BASE, {
            'order': self.order_id, 'stars': 6,
        }, format='json')
        # Serializer-level validation rejects stars outside 1–5
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_requires_authentication(self):
        self.client.force_authenticate(None)  # log out
        r = self.client.post(self.BASE, {'stars': 5}, format='json')
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)
