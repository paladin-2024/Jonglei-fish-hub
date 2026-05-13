import uuid
from django.test import TestCase
from django.contrib.auth import get_user_model

User = get_user_model()


class UserModelTest(TestCase):
    def test_user_uses_uuid_primary_key(self):
        user = User.objects.create_user(
            phone_number='+211912345678',
            username='testuser',
            password='testpass123',
            role='TRADER',
        )
        self.assertIsInstance(user.pk, uuid.UUID)

    def test_phone_number_is_username_field(self):
        self.assertEqual(User.USERNAME_FIELD, 'phone_number')

    def test_user_default_is_not_verified(self):
        user = User.objects.create_user(
            phone_number='+211912345679',
            username='testuser2',
            password='testpass123',
        )
        self.assertFalse(user.is_verified)

    def test_user_role_choices(self):
        valid_roles = ['TRADER', 'BUYER', 'TRANSPORTER', 'DRIVER',
                       'BORDER_OFFICIAL', 'MARKET_OFFICIAL', 'ADMIN']
        for role in valid_roles:
            user = User(
                phone_number=f'+211912{valid_roles.index(role):06d}',
                username=f'user_{role}',
                role=role,
            )
            user.set_password('testpass123')
            user.full_clean(exclude=['password'])

    def test_rating_default_is_zero(self):
        user = User.objects.create_user(
            phone_number='+211912345680',
            username='ratinguser',
            password='testpass123',
        )
        self.assertEqual(user.rating, 0)

    def test_preferred_language_default_is_english(self):
        user = User.objects.create_user(
            phone_number='+211912345681',
            username='languser',
            password='testpass123',
        )
        self.assertEqual(user.preferred_language, 'EN')


from apps.accounts.serializers import (
    RegistrationSerializer, LoginSerializer, UserSerializer
)


class RegistrationSerializerTest(TestCase):
    def test_valid_registration_data_is_accepted(self):
        data = {
            'phone_number': '+211912345690',
            'username': 'newtrader',
            'password': 'securepass123',
            'role': 'TRADER',
            'location': 'Juba',
            'preferred_language': 'EN',
        }
        serializer = RegistrationSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_duplicate_phone_number_is_rejected(self):
        User.objects.create_user(
            phone_number='+211912345691',
            username='existing',
            password='pass123',
        )
        data = {
            'phone_number': '+211912345691',
            'username': 'duplicate',
            'password': 'pass123',
        }
        serializer = RegistrationSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('phone_number', serializer.errors)

    def test_registration_creates_user(self):
        data = {
            'phone_number': '+211912345692',
            'username': 'createduser',
            'password': 'securepass123',
            'role': 'BUYER',
        }
        serializer = RegistrationSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        user = serializer.save()
        self.assertEqual(user.phone_number, '+211912345692')
        self.assertTrue(user.check_password('securepass123'))


class UserSerializerTest(TestCase):
    def test_serializer_includes_role_display(self):
        user = User.objects.create_user(
            phone_number='+211912345693',
            username='displayuser',
            password='pass123',
            role='TRADER',
        )
        serializer = UserSerializer(user)
        self.assertEqual(serializer.data['role_display'], 'Fish Trader')


from rest_framework.test import APITestCase
from rest_framework import status


class AuthAPITest(APITestCase):
    def setUp(self):
        self.register_url = '/api/v1/auth/register/'
        self.login_url = '/api/v1/auth/login/'
        self.profile_url = '/api/v1/auth/profile/'
        self.valid_user_data = {
            'phone_number': '+211912000001',
            'username': 'apiuser',
            'password': 'securepass123',
            'role': 'TRADER',
        }

    def test_register_creates_user_and_returns_tokens(self):
        response = self.client.post(self.register_url, self.valid_user_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('access_token', response.data)
        self.assertIn('refresh_token', response.data)
        self.assertIn('user', response.data)
        self.assertEqual(response.data['user']['phone_number'], '+211912000001')

    def test_register_with_duplicate_phone_returns_400(self):
        self.client.post(self.register_url, self.valid_user_data, format='json')
        response = self.client.post(self.register_url, self.valid_user_data, format='json')
        # Rate limiter may kick in (429) or duplicate phone rejected (400)
        self.assertIn(response.status_code, [
            status.HTTP_400_BAD_REQUEST,
            status.HTTP_429_TOO_MANY_REQUESTS,
        ])

    def test_login_returns_tokens(self):
        self.client.post(self.register_url, self.valid_user_data, format='json')
        response = self.client.post(self.login_url, {
            'phone_number': '+211912000001',
            'password': 'securepass123',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access_token', response.data)

    def test_login_with_wrong_password_returns_400(self):
        self.client.post(self.register_url, self.valid_user_data, format='json')
        response = self.client.post(self.login_url, {
            'phone_number': '+211912000001',
            'password': 'wrongpassword',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_profile_requires_authentication(self):
        response = self.client.get(self.profile_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_profile_returns_current_user(self):
        reg_response = self.client.post(self.register_url, self.valid_user_data, format='json')
        token = reg_response.data['access_token']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.get(self.profile_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['phone_number'], '+211912000001')
