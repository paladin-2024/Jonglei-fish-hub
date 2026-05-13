from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.notifications.models import Notification

User = get_user_model()

# ─── Shared factories ─────────────────────────────────────────────────────────

_ROLE_CODE = {
    'TRADER': 'TD', 'BUYER': 'BY', 'TRANSPORTER': 'TP',
    'BORDER_OFFICIAL': 'BO',
}

def make_user(role, n=1):
    code = _ROLE_CODE.get(role, role[:2].upper())
    return User.objects.create_user(
        phone_number=f'+211918{code}{n:04d}',
        username=f'ntf_{role.lower()}{n}',
        password='pass123',
        role=role,
    )

def make_notification(recipient=None, target_role=None, title='Test', body='Body'):
    return Notification.objects.create(
        recipient=recipient,
        target_role=target_role,
        title=title,
        body=body,
    )


# ─── NotificationViewSet – list ───────────────────────────────────────────────

class NotificationListTest(APITestCase):
    BASE = '/api/v1/notifications/'

    def setUp(self):
        self.trader = make_user('TRADER', 1)
        self.buyer = make_user('BUYER', 1)

    def test_requires_authentication(self):
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_user_sees_own_personal_notification(self):
        make_notification(recipient=self.trader, title='For you')
        make_notification(recipient=self.buyer, title='Not for you')
        self.client.force_authenticate(self.trader)
        r = self.client.get(self.BASE)
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        results = r.data.get('results', r.data)
        titles = [n['title'] for n in results]
        self.assertIn('For you', titles)
        self.assertNotIn('Not for you', titles)

    def test_user_sees_all_broadcast(self):
        make_notification(target_role='ALL', title='System broadcast')
        self.client.force_authenticate(self.trader)
        r = self.client.get(self.BASE)
        results = r.data.get('results', r.data)
        titles = [n['title'] for n in results]
        self.assertIn('System broadcast', titles)

    def test_user_sees_role_targeted_notification(self):
        make_notification(target_role='TRADER', title='For traders')
        make_notification(target_role='BUYER', title='For buyers only')
        self.client.force_authenticate(self.trader)
        r = self.client.get(self.BASE)
        results = r.data.get('results', r.data)
        titles = [n['title'] for n in results]
        self.assertIn('For traders', titles)
        self.assertNotIn('For buyers only', titles)

    def test_buyer_does_not_see_trader_targeted_notification(self):
        make_notification(target_role='TRADER', title='Trader only')
        self.client.force_authenticate(self.buyer)
        r = self.client.get(self.BASE)
        results = r.data.get('results', r.data)
        titles = [n['title'] for n in results]
        self.assertNotIn('Trader only', titles)

    def test_no_duplicates_when_both_personal_and_role_match(self):
        notif = make_notification(
            recipient=self.trader, target_role='TRADER', title='Both match'
        )
        self.client.force_authenticate(self.trader)
        r = self.client.get(self.BASE)
        results = r.data.get('results', r.data)
        matching_ids = [n['id'] for n in results if n['title'] == 'Both match']
        self.assertEqual(len(matching_ids), 1)


# ─── mark_read action ─────────────────────────────────────────────────────────

class NotificationMarkReadTest(APITestCase):
    BASE = '/api/v1/notifications/'

    def setUp(self):
        self.trader = make_user('TRADER', 10)
        self.notif = make_notification(recipient=self.trader, title='Unread')

    def test_mark_read_sets_is_read_true(self):
        self.assertFalse(self.notif.is_read)
        self.client.force_authenticate(self.trader)
        r = self.client.post(f'{self.BASE}{self.notif.id}/mark_read/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.notif.refresh_from_db()
        self.assertTrue(self.notif.is_read)

    def test_mark_read_returns_ok_status(self):
        self.client.force_authenticate(self.trader)
        r = self.client.post(f'{self.BASE}{self.notif.id}/mark_read/')
        self.assertEqual(r.data, {'status': 'ok'})


# ─── mark_all_read action ─────────────────────────────────────────────────────

class NotificationMarkAllReadTest(APITestCase):
    BASE = '/api/v1/notifications/'

    def setUp(self):
        self.trader = make_user('TRADER', 20)
        self.buyer = make_user('BUYER', 20)
        for i in range(3):
            make_notification(recipient=self.trader, title=f'Unread {i}')
        # Buyer's notification — should be unaffected
        make_notification(recipient=self.buyer, title='Buyer unread')

    def test_mark_all_read_marks_only_current_users_notifications(self):
        self.client.force_authenticate(self.trader)
        r = self.client.post(f'{self.BASE}mark_all_read/')
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        unread_trader = Notification.objects.filter(
            recipient=self.trader, is_read=False
        ).count()
        self.assertEqual(unread_trader, 0)
        # Buyer's notifications unchanged
        unread_buyer = Notification.objects.filter(
            recipient=self.buyer, is_read=False
        ).count()
        self.assertEqual(unread_buyer, 1)


# ─── broadcast action ─────────────────────────────────────────────────────────

class NotificationBroadcastTest(APITestCase):
    BASE = '/api/v1/notifications/'

    def setUp(self):
        self.admin = User.objects.create_superuser(
            phone_number='+211918AD0001',
            username='admin_ntf',
            password='adminpass',
        )
        self.trader = make_user('TRADER', 30)

    def test_admin_can_broadcast(self):
        self.client.force_authenticate(self.admin)
        r = self.client.post(f'{self.BASE}broadcast/', {
            'title': 'Market closure',
            'body': 'Market closed tomorrow.',
            'target_role': 'ALL',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_201_CREATED)
        self.assertTrue(
            Notification.objects.filter(title='Market closure').exists()
        )

    def test_non_admin_cannot_broadcast(self):
        self.client.force_authenticate(self.trader)
        r = self.client.post(f'{self.BASE}broadcast/', {
            'title': 'Fake broadcast',
            'body': 'Test',
            'target_role': 'ALL',
        }, format='json')
        self.assertEqual(r.status_code, status.HTTP_403_FORBIDDEN)
