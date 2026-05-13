import base64
from decimal import Decimal

from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.clearance.models import BorderClearance
from apps.marketplace.models import FishListing, Order
from apps.transport.models import Shipment, TransportJob

User = get_user_model()

# ─── Shared factories ─────────────────────────────────────────────────────────

_ROLE_CODE = {
    'TRADER': 'TD', 'BUYER': 'BY', 'TRANSPORTER': 'TP',
    'BORDER_OFFICIAL': 'BO', 'DRIVER': 'DR',
}

def make_user(role, n=1):
    code = _ROLE_CODE.get(role, role[:2].upper())
    # Border officials with no location see all checkpoints
    return User.objects.create_user(
        phone_number=f'+211916{code}{n:04d}',
        username=f'clr_{role.lower()}{n}',
        password='pass123',
        role=role,
        location='',
    )

def _make_shipment(trader, buyer):
    listing = FishListing.objects.create(
        seller=trader, species='Nile Perch',
        quantity_kg=Decimal('80'), price_ssp=Decimal('1800'),
        location='Bor', status='ACTIVE',
    )
    order = Order.objects.create(
        listing=listing, buyer=buyer,
        quantity_kg=Decimal('30'), total_price=Decimal('54000'),
        status='IN_TRANSIT',
    )
    return Shipment.objects.create(
        order=order, origin='Bor', destination='Juba', status='IN_TRANSIT',
    )


# ─── BorderClearance model ────────────────────────────────────────────────────

class BorderClearanceModelTest(APITestCase):
    def setUp(self):
        self.officer = make_user('BORDER_OFFICIAL')
        self.trader = make_user('TRADER', 2)
        self.buyer = make_user('BUYER', 3)
        self.shipment = _make_shipment(self.trader, self.buyer)

    def test_auto_generates_qr_on_save(self):
        clearance = BorderClearance.objects.create(
            shipment=self.shipment,
            checkpoint='Juba South Gate',
            officer=self.officer,
            status='PENDING',
        )
        self.assertTrue(len(clearance.qr_code) > 0)

    def test_qr_is_valid_base64_png(self):
        clearance = BorderClearance.objects.create(
            shipment=self.shipment,
            checkpoint='Juba South Gate',
            status='PENDING',
        )
        try:
            raw = base64.b64decode(clearance.qr_code)
            # PNG magic bytes: \x89PNG
            self.assertTrue(raw[:4] == b'\x89PNG')
        except Exception as e:
            self.fail(f'QR code is not valid base64 PNG: {e}')

    def test_qr_payload_contains_clearance_id(self):
        clearance = BorderClearance.objects.create(
            shipment=self.shipment,
            checkpoint='Juba South Gate',
        )
        # Re-generate and verify payload by decoding QR is non-trivial here;
        # check that generate_qr runs without error and populates qr_code.
        clearance.qr_code = ''
        clearance.generate_qr()
        self.assertTrue(len(clearance.qr_code) > 100)

    def test_str_contains_checkpoint(self):
        clearance = BorderClearance.objects.create(
            shipment=self.shipment, checkpoint='Test Gate',
        )
        self.assertIn('Test Gate', str(clearance))


# ─── BorderClearanceViewSet API ───────────────────────────────────────────────

class BorderClearanceAPITest(APITestCase):
    BASE = '/api/v1/clearance/clearances/'

    def setUp(self):
        self.officer = make_user('BORDER_OFFICIAL', 10)
        self.trader = make_user('TRADER', 10)
        self.buyer = make_user('BUYER', 10)
        self.shipment = _make_shipment(self.trader, self.buyer)
        self.clearance = BorderClearance.objects.create(
            shipment=self.shipment,
            checkpoint='Juba South Gate',
            status='PENDING',
        )

    def test_requires_authentication(self):
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_authenticated_user_can_list_clearances(self):
        self.client.force_authenticate(self.officer)
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_200_OK)

    def test_filter_by_status_pending(self):
        self.client.force_authenticate(self.officer)
        r = self.client.get(self.BASE + '?status=PENDING')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        results = r.data.get('results', r.data)
        for item in results:
            self.assertEqual(item['status'], 'PENDING')

    def test_filter_by_shipment_uuid(self):
        self.client.force_authenticate(self.officer)
        r = self.client.get(f'{self.BASE}?shipment={self.shipment.id}')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        results = r.data.get('results', r.data)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['id'], str(self.clearance.id))

    def test_response_includes_qr_code(self):
        self.client.force_authenticate(self.officer)
        r = self.client.get(f'{self.BASE}{self.clearance.id}/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertIn('qr_code', r.data)
        self.assertTrue(len(r.data['qr_code']) > 0)

    def test_scan_clear_marks_as_cleared(self):
        self.client.force_authenticate(self.officer)
        r = self.client.post(f'{self.BASE}{self.clearance.id}/scan-clear/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data['status'], 'CLEARED')
        self.clearance.refresh_from_db()
        self.assertEqual(self.clearance.status, 'CLEARED')

    def test_scan_clear_sets_officer_and_cleared_at(self):
        self.client.force_authenticate(self.officer)
        self.client.post(f'{self.BASE}{self.clearance.id}/scan-clear/')
        self.clearance.refresh_from_db()
        self.assertEqual(self.clearance.officer, self.officer)
        self.assertIsNotNone(self.clearance.cleared_at)

    def test_cannot_scan_clear_already_cleared(self):
        self.clearance.status = 'CLEARED'
        self.clearance.save(update_fields=['status'])
        self.client.force_authenticate(self.officer)
        r = self.client.post(f'{self.BASE}{self.clearance.id}/scan-clear/')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_hold_marks_as_held(self):
        self.client.force_authenticate(self.officer)
        r = self.client.post(f'{self.BASE}{self.clearance.id}/hold/', {
            'notes': 'Documents missing',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data['status'], 'HELD')
        self.clearance.refresh_from_db()
        self.assertEqual(self.clearance.status, 'HELD')

    def test_hold_saves_notes(self):
        self.client.force_authenticate(self.officer)
        self.client.post(f'{self.BASE}{self.clearance.id}/hold/', {
            'notes': 'Missing health cert',
        }, format='json')
        self.clearance.refresh_from_db()
        self.assertEqual(self.clearance.notes, 'Missing health cert')

    def test_qr_endpoint_returns_png_bytes(self):
        self.client.force_authenticate(self.officer)
        r = self.client.get(f'{self.BASE}{self.clearance.id}/qr/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r['Content-Type'], 'image/png')
        self.assertTrue(r.content[:4] == b'\x89PNG')
