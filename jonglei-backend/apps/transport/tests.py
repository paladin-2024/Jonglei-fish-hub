from decimal import Decimal

from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.marketplace.models import FishListing, Order
from apps.transport.models import Shipment, TrackingEvent, TransportJob

User = get_user_model()

# ─── Shared factories ─────────────────────────────────────────────────────────

_ROLE_CODE = {
    'TRADER': 'TD', 'BUYER': 'BY', 'TRANSPORTER': 'TP',
    'BORDER_OFFICIAL': 'BO', 'DRIVER': 'DR',
}

def make_user(role, n=1):
    code = _ROLE_CODE.get(role, role[:2].upper())
    return User.objects.create_user(
        phone_number=f'+211915{code}{n:04d}',
        username=f'{role.lower()}{n}',
        password='pass123',
        role=role,
        location='Bor',
    )

def _setup_shipped_order(trader, buyer):
    """Create listing → place order → confirm → ship. Returns (order, shipment, job)."""
    listing = FishListing.objects.create(
        seller=trader, species='Nile Perch',
        quantity_kg=Decimal('100'), price_ssp=Decimal('2000'),
        location='Bor', status='ACTIVE',
    )
    order = Order.objects.create(
        listing=listing, buyer=buyer,
        quantity_kg=Decimal('20'), total_price=Decimal('40000'),
        status='CONFIRMED',
    )
    shipment = Shipment.objects.create(
        order=order, origin='Bor', destination='Juba', status='IN_TRANSIT',
    )
    job = TransportJob.objects.create(shipment=shipment, pay_ssp=Decimal('2000'))
    return order, shipment, job


# ─── Shipment model ───────────────────────────────────────────────────────────

class ShipmentModelTest(APITestCase):
    def test_shipment_str(self):
        trader = make_user('TRADER')
        buyer = make_user('BUYER')
        order, shipment, _ = _setup_shipped_order(trader, buyer)
        self.assertIn('Bor', str(shipment))
        self.assertIn('Juba', str(shipment))

    def test_shipment_has_uuid_pk(self):
        import uuid
        trader = make_user('TRADER')
        buyer = make_user('BUYER')
        _, shipment, _ = _setup_shipped_order(trader, buyer)
        self.assertIsInstance(shipment.pk, uuid.UUID)

    def test_transport_job_str(self):
        trader = make_user('TRADER', 2)
        buyer = make_user('BUYER', 2)
        _, _, job = _setup_shipped_order(trader, buyer)
        self.assertIn('Job', str(job))


# ─── ShipmentViewSet API ──────────────────────────────────────────────────────

class ShipmentAPITest(APITestCase):
    BASE = '/api/v1/transport/shipments/'

    def setUp(self):
        self.trader = make_user('TRADER', 10)
        self.buyer = make_user('BUYER', 10)
        self.transporter = make_user('TRANSPORTER', 10)
        self.order, self.shipment, self.job = _setup_shipped_order(
            self.trader, self.buyer
        )

    def test_requires_auth(self):
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_trader_sees_own_shipments(self):
        self.client.force_authenticate(self.trader)
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        results = r.data.get('results', r.data)
        self.assertTrue(len(results) >= 1)

    def test_buyer_can_filter_by_order_uuid(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.get(f'{self.BASE}?order={self.order.id}')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        results = r.data.get('results', r.data)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['id'], str(self.shipment.id))

    def test_serializer_includes_order_seller_name(self):
        self.client.force_authenticate(self.trader)
        r = self.client.get(f'{self.BASE}{self.shipment.id}/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertIn('order_seller_name', r.data)
        self.assertEqual(r.data['order_seller_name'], self.trader.username)

    def test_serializer_includes_order_buyer_name(self):
        self.client.force_authenticate(self.trader)
        r = self.client.get(f'{self.BASE}{self.shipment.id}/')
        self.assertIn('order_buyer_name', r.data)
        self.assertEqual(r.data['order_buyer_name'], self.buyer.username)

    def test_serializer_includes_price_fields(self):
        self.client.force_authenticate(self.trader)
        r = self.client.get(f'{self.BASE}{self.shipment.id}/')
        self.assertIn('order_price_ssp', r.data)
        self.assertIn('order_total_price', r.data)

    def test_add_tracking_event(self):
        self.client.force_authenticate(self.transporter)
        r = self.client.post(f'{self.BASE}{self.shipment.id}/add_event/', {
            'stage': 'LOADED',
            'note': 'Fish loaded at Bor dock',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertEqual(r.data['stage'], 'LOADED')
        self.assertTrue(TrackingEvent.objects.filter(shipment=self.shipment).exists())

    def test_get_events(self):
        TrackingEvent.objects.create(
            shipment=self.shipment, stage='EN_ROUTE',
            note='On the road', recorded_by=self.transporter,
        )
        self.client.force_authenticate(self.trader)
        r = self.client.get(f'{self.BASE}{self.shipment.id}/events/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(len(r.data), 1)
        self.assertEqual(r.data[0]['stage'], 'EN_ROUTE')


# ─── TransportJobViewSet API ──────────────────────────────────────────────────

class TransportJobAPITest(APITestCase):
    BASE = '/api/v1/transport/jobs/'

    def setUp(self):
        self.trader = make_user('TRADER', 20)
        self.buyer = make_user('BUYER', 20)
        self.transporter = make_user('TRANSPORTER', 20)
        self.order, self.shipment, self.job = _setup_shipped_order(
            self.trader, self.buyer
        )

    def test_transporter_sees_open_jobs(self):
        self.client.force_authenticate(self.transporter)
        r = self.client.get(self.BASE + '?status=OPEN')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        results = r.data.get('results', r.data)
        open_ids = [item['id'] for item in results]
        self.assertIn(str(self.job.id), open_ids)

    def test_accept_job_changes_status_and_assigns_transporter(self):
        self.client.force_authenticate(self.transporter)
        r = self.client.post(f'{self.BASE}{self.job.id}/accept_job/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data['status'], 'ACCEPTED')
        self.job.refresh_from_db()
        self.assertEqual(self.job.transporter, self.transporter)
        self.assertEqual(self.job.status, 'ACCEPTED')

    def test_cannot_accept_already_accepted_job(self):
        self.job.transporter = self.transporter
        self.job.status = 'ACCEPTED'
        self.job.save()
        transporter2 = make_user('TRANSPORTER', 21)
        self.client.force_authenticate(transporter2)
        r = self.client.post(f'{self.BASE}{self.job.id}/accept_job/')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_start_transit_requires_assigned_transporter(self):
        other = make_user('TRANSPORTER', 22)
        self.client.force_authenticate(other)
        r = self.client.post(f'{self.BASE}{self.job.id}/start_transit/')
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)

    def test_start_transit_sets_job_active(self):
        self.job.transporter = self.transporter
        self.job.status = 'ACCEPTED'
        self.job.save()
        self.client.force_authenticate(self.transporter)
        r = self.client.post(f'{self.BASE}{self.job.id}/start_transit/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data['status'], 'ACTIVE')

    def test_deliver_sets_job_completed_and_shipment_delivered(self):
        self.job.transporter = self.transporter
        self.job.status = 'ACTIVE'
        self.job.save()
        self.client.force_authenticate(self.transporter)
        r = self.client.post(f'{self.BASE}{self.job.id}/deliver/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data['status'], 'COMPLETED')
        self.shipment.refresh_from_db()
        self.assertEqual(self.shipment.status, 'DELIVERED')
        self.assertEqual(self.shipment.progress, Decimal('1'))

    def test_requires_authentication(self):
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)
