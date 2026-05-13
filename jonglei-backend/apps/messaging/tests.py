from decimal import Decimal

from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.marketplace.models import FishListing
from apps.messaging.models import Thread, Message

User = get_user_model()

# ─── Shared factories ─────────────────────────────────────────────────────────

_ROLE_CODE = {
    'TRADER': 'TD', 'BUYER': 'BY', 'TRANSPORTER': 'TP',
    'BORDER_OFFICIAL': 'BO',
}

def make_user(role, n=1):
    code = _ROLE_CODE.get(role, role[:2].upper())
    return User.objects.create_user(
        phone_number=f'+211917{code}{n:04d}',
        username=f'msg_{role.lower()}{n}',
        password='pass123',
        role=role,
    )

def make_listing(seller, species='Tilapia'):
    return FishListing.objects.create(
        seller=seller, species=species,
        quantity_kg=Decimal('50'), price_ssp=Decimal('1000'),
        location='Bor', status='ACTIVE',
    )


# ─── Thread model ─────────────────────────────────────────────────────────────

class ThreadModelTest(APITestCase):
    def test_str(self):
        trader = make_user('TRADER')
        buyer = make_user('BUYER')
        thread = Thread.objects.create(buyer=buyer, seller=trader)
        self.assertIn(str(buyer), str(thread))

    def test_unique_together_listing_buyer(self):
        from django.db import IntegrityError
        trader = make_user('TRADER', 10)
        buyer = make_user('BUYER', 10)
        listing = make_listing(trader)
        Thread.objects.create(listing=listing, buyer=buyer, seller=trader)
        with self.assertRaises(IntegrityError):
            Thread.objects.create(listing=listing, buyer=buyer, seller=trader)


# ─── Thread API – create ──────────────────────────────────────────────────────

class ThreadCreateTest(APITestCase):
    BASE = '/api/v1/messaging/threads/'

    def setUp(self):
        self.trader = make_user('TRADER', 20)
        self.buyer = make_user('BUYER', 20)
        self.listing = make_listing(self.trader)

    def test_buyer_can_open_thread(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.post(self.BASE, {'listing': str(self.listing.id)}, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertIn('id', r.data)

    def test_second_post_returns_200_not_201(self):
        self.client.force_authenticate(self.buyer)
        self.client.post(self.BASE, {'listing': str(self.listing.id)}, format='json')
        r2 = self.client.post(self.BASE, {'listing': str(self.listing.id)}, format='json')
        self.assertEqual(r2.status_code, status.HTTP_200_OK)

    def test_second_post_returns_same_thread(self):
        self.client.force_authenticate(self.buyer)
        r1 = self.client.post(self.BASE, {'listing': str(self.listing.id)}, format='json')
        r2 = self.client.post(self.BASE, {'listing': str(self.listing.id)}, format='json')
        self.assertEqual(r1.data['id'], r2.data['id'])

    def test_seller_cannot_open_thread_on_own_listing(self):
        self.client.force_authenticate(self.trader)
        r = self.client.post(self.BASE, {'listing': str(self.listing.id)}, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_missing_listing_id_returns_400(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.post(self.BASE, {}, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_invalid_listing_id_returns_404(self):
        import uuid
        self.client.force_authenticate(self.buyer)
        r = self.client.post(self.BASE, {'listing': str(uuid.uuid4())}, format='json')
        self.assertEqual(r.status_code, status.HTTP_404_NOT_FOUND)

    def test_requires_authentication(self):
        r = self.client.post(self.BASE, {'listing': str(self.listing.id)}, format='json')
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)


# ─── Thread API – list ────────────────────────────────────────────────────────

class ThreadListTest(APITestCase):
    BASE = '/api/v1/messaging/threads/'

    def setUp(self):
        self.trader = make_user('TRADER', 30)
        self.buyer = make_user('BUYER', 30)
        self.other_buyer = make_user('BUYER', 31)
        self.listing = make_listing(self.trader)
        listing2 = make_listing(make_user('TRADER', 32), species='Catfish')
        # buyer has 1 thread
        Thread.objects.create(
            listing=self.listing, buyer=self.buyer, seller=self.trader
        )
        # other_buyer has 1 thread (buyer should not see this)
        Thread.objects.create(
            listing=listing2, buyer=self.other_buyer,
            seller=listing2.seller,
        )

    def test_buyer_only_sees_own_threads(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        results = r.data.get('results', r.data)
        self.assertEqual(len(results), 1)

    def test_trader_sees_threads_where_they_are_seller(self):
        self.client.force_authenticate(self.trader)
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        results = r.data.get('results', r.data)
        self.assertEqual(len(results), 1)


# ─── Thread messages action ───────────────────────────────────────────────────

class ThreadMessagesTest(APITestCase):
    def setUp(self):
        self.trader = make_user('TRADER', 40)
        self.buyer = make_user('BUYER', 40)
        self.listing = make_listing(self.trader)
        self.thread = Thread.objects.create(
            listing=self.listing, buyer=self.buyer, seller=self.trader
        )
        self.msg_url = f'/api/v1/messaging/threads/{self.thread.id}/messages/'
        self.send_url = f'/api/v1/messaging/threads/{self.thread.id}/send/'

    def test_get_messages_returns_empty_list(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.get(self.msg_url)
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.data, [])

    def test_send_creates_message(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.post(self.send_url, {'body': 'Hello, is this still available?'}, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertEqual(r.data['body'], 'Hello, is this still available?')
        self.assertTrue(Message.objects.filter(thread=self.thread).exists())

    def test_empty_body_returns_400(self):
        self.client.force_authenticate(self.buyer)
        r = self.client.post(self.send_url, {'body': '   '}, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_messages_marked_read_on_fetch(self):
        # Trader sends a message
        Message.objects.create(
            thread=self.thread, sender=self.trader,
            body='Yes, available', is_read=False,
        )
        # Buyer fetches messages — trader's message should be marked read
        self.client.force_authenticate(self.buyer)
        self.client.get(self.msg_url)
        msg = Message.objects.get(thread=self.thread, sender=self.trader)
        self.assertTrue(msg.is_read)

    def test_own_messages_not_marked_read_by_sender(self):
        # Buyer sends a message
        Message.objects.create(
            thread=self.thread, sender=self.buyer,
            body='How much?', is_read=False,
        )
        # Buyer fetches — their own message should NOT be marked read
        self.client.force_authenticate(self.buyer)
        self.client.get(self.msg_url)
        msg = Message.objects.get(thread=self.thread, sender=self.buyer)
        self.assertFalse(msg.is_read)

    def test_get_messages_returns_all_messages(self):
        Message.objects.create(thread=self.thread, sender=self.buyer, body='Hi')
        Message.objects.create(thread=self.thread, sender=self.trader, body='Hello')
        self.client.force_authenticate(self.buyer)
        r = self.client.get(self.msg_url)
        self.assertEqual(len(r.data), 2)

    def test_send_requires_authentication(self):
        r = self.client.post(self.send_url, {'body': 'test'}, format='json')
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)
