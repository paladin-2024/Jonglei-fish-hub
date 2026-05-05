# Jonglei Fish Hub — Day 1 Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up working JWT authentication across Django REST API, Flutter mobile app, and React admin dashboard — all sharing the same PostgreSQL database and token strategy.

**Architecture:** Django acts as the single auth source of truth issuing JWTs via djangorestframework-simplejwt; Flutter stores tokens in FlutterSecureStorage and auto-refreshes on 401; React persists tokens in localStorage with Axios interceptors. All three layers share the same `/api/v1/auth/` contract.

**Tech Stack:** Django 6.0.4, DRF 3.14, simplejwt 5.3, PostgreSQL, Flutter 3.x + Provider, React + Vite + Tailwind + Axios

---

## Prerequisites (verify before starting)

```bash
# PostgreSQL running and database created
psql -U postgres -c "CREATE USER jonglei_admin WITH PASSWORD 'jonglei2024';"
psql -U postgres -c "CREATE DATABASE jonglei_fish_hub OWNER jonglei_admin;"

# Flutter SDK installed
flutter --version

# Node.js installed
node --version  # should be 18+
```

> **PostGIS note:** The spec requests `django.contrib.gis.db.backends.postgis`. This requires system packages (`sudo apt install postgis postgresql-postgis`). The plan uses standard `django.db.backends.postgresql` for Day 1 and documents the PostGIS upgrade path at the end of Task 2.

---

## File Map

### Django (`jonglei-backend/`)
| Action | Path |
|--------|------|
| Create | `requirements.txt` |
| Modify | `core/settings.py` |
| Modify | `core/urls.py` |
| Create | `apps/__init__.py` |
| Create | `apps/accounts/models.py` |
| Create | `apps/accounts/serializers.py` |
| Create | `apps/accounts/views.py` |
| Create | `apps/accounts/urls.py` |
| Modify | `apps/accounts/admin.py` |
| Create | `utils/__init__.py` |
| Create | `utils/permissions.py` |
| Create | `apps/accounts/tests.py` |

### Flutter (`jonglei-mobile/` — new project at repo root)
| Action | Path |
|--------|------|
| Create | `jonglei-mobile/` (flutter create) |
| Create | `lib/config/api_config.dart` |
| Create | `lib/models/user.dart` |
| Create | `lib/services/storage_service.dart` |
| Create | `lib/services/api_service.dart` |
| Create | `lib/services/auth_service.dart` |
| Create | `lib/providers/auth_provider.dart` |
| Create | `lib/screens/auth/login_screen.dart` |
| Create | `lib/screens/auth/register_screen.dart` |
| Create | `lib/screens/trader/trader_home.dart` |
| Create | `lib/screens/buyer/buyer_home.dart` |
| Create | `lib/screens/transporter/transporter_home.dart` |
| Modify | `lib/main.dart` |
| Create | `test/auth_provider_test.dart` |

### React (`jonglei-dashboard/` — new project at repo root)
| Action | Path |
|--------|------|
| Create | `jonglei-dashboard/` (vite create) |
| Create | `src/api/axios.js` |
| Create | `src/context/AuthContext.jsx` |
| Create | `src/pages/Login.jsx` |
| Create | `src/pages/Dashboard.jsx` |
| Create | `src/components/Sidebar.jsx` |
| Create | `src/components/StatCard.jsx` |
| Modify | `src/App.jsx` |
| Create | `src/test/Login.test.jsx` |

---

## PART 1 — DJANGO BACKEND

---

### Task 1: Install dependencies

**Files:**
- Create: `jonglei-backend/requirements.txt`

- [ ] **Step 1: Write requirements.txt**

```
django==6.0.4
djangorestframework==3.14.0
djangorestframework-simplejwt==5.3.1
psycopg2-binary==2.9.9
django-cors-headers==4.3.1
django-filter==23.5
qrcode[pil]==7.4.2
pillow==10.2.0
python-decouple==3.8
```

Save to `jonglei-backend/requirements.txt`.

- [ ] **Step 2: Activate the venv and install packages**

```bash
cd jonglei-backend
source venv/bin/activate
pip install -r requirements.txt
```

Expected: All packages install without errors.

- [ ] **Step 3: Verify key packages**

```bash
python -c "import rest_framework, rest_framework_simplejwt, corsheaders; print('OK')"
```

Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add requirements.txt
git commit -m "feat: add requirements.txt with DRF, JWT, CORS dependencies"
```

---

### Task 2: Configure settings.py

**Files:**
- Modify: `jonglei-backend/core/settings.py`

- [ ] **Step 1: Write the full settings.py**

Replace `jonglei-backend/core/settings.py` entirely with:

```python
from pathlib import Path
from decouple import config

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config('SECRET_KEY', default='django-insecure-z#f0hk$4d4sz%euro!77wwo-^67@)%ji6om28up80jicgkx)4r')
DEBUG = config('DEBUG', default=True, cast=bool)
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Third party
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'django_filters',
    # Local
    'apps.accounts',
    'apps.marketplace',
    'apps.transport',
    'apps.clearance',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'core.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME', default='jonglei_fish_hub'),
        'USER': config('DB_USER', default='jonglei_admin'),
        'PASSWORD': config('DB_PASSWORD', default='jonglei2024'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
    }
}

AUTH_USER_MODEL = 'accounts.User'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_FILTER_BACKENDS': (
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ),
}

from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': False,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

CORS_ALLOWED_ORIGINS = [
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:5173',  # Vite default
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Juba'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
```

- [ ] **Step 2: Create apps/__init__.py so the apps package is importable**

```bash
touch jonglei-backend/apps/__init__.py
```

- [ ] **Step 3: Verify settings load**

```bash
cd jonglei-backend && source venv/bin/activate
python manage.py check --deploy 2>&1 | grep -v "WARNINGS\|settings.DEBUG\|HSTS\|csrf\|Silenced" || echo "Settings OK"
```

Expected: No `SystemCheckError`. Some deployment warnings are fine at this stage.

> **PostGIS upgrade path (do this after Day 1):**
> ```bash
> sudo apt install postgis postgresql-postgis libgdal-dev
> psql -U jonglei_admin jonglei_fish_hub -c "CREATE EXTENSION postgis;"
> # Then change ENGINE to: django.contrib.gis.db.backends.postgis
> # And add django.contrib.gis to INSTALLED_APPS
> ```

- [ ] **Step 4: Commit**

```bash
git add core/settings.py apps/__init__.py
git commit -m "feat: configure DRF, JWT, CORS, PostgreSQL in settings"
```

---

### Task 3: User model

**Files:**
- Modify: `jonglei-backend/apps/accounts/models.py`
- Modify: `jonglei-backend/apps/accounts/tests.py`

- [ ] **Step 1: Write the failing tests**

Replace `jonglei-backend/apps/accounts/tests.py` with:

```python
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
            user.full_clean()  # Should not raise

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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd jonglei-backend && source venv/bin/activate
python manage.py test apps.accounts.tests -v 2
```

Expected: `ERRORS` — `AttributeError` or `OperationalError` because the User model is not defined yet.

- [ ] **Step 3: Implement the User model**

Replace `jonglei-backend/apps/accounts/models.py` with:

```python
import uuid
from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    ROLE_CHOICES = [
        ('TRADER', 'Fish Trader'),
        ('BUYER', 'Buyer'),
        ('TRANSPORTER', 'Transporter'),
        ('DRIVER', 'Driver'),
        ('BORDER_OFFICIAL', 'Border Official'),
        ('MARKET_OFFICIAL', 'Market Official'),
        ('ADMIN', 'Administrator'),
    ]

    LANGUAGE_CHOICES = [
        ('EN', 'English'),
        ('AR', 'Arabic'),
        ('DIN', 'Dinka'),
        ('NUE', 'Nuer'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    username = models.CharField(max_length=150, blank=True, default='')
    phone_number = models.CharField(max_length=20, unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='TRADER')
    location = models.CharField(max_length=200, blank=True, default='')
    is_verified = models.BooleanField(default=False)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    total_transactions = models.IntegerField(default=0)
    preferred_language = models.CharField(
        max_length=3, choices=LANGUAGE_CHOICES, default='EN'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['username']

    class Meta:
        db_table = 'users'
        indexes = [
            models.Index(fields=['phone_number']),
            models.Index(fields=['role']),
        ]

    def __str__(self):
        return f'{self.phone_number} ({self.get_role_display()})'
```

- [ ] **Step 4: Create and run migrations**

```bash
cd jonglei-backend && source venv/bin/activate
python manage.py makemigrations accounts
python manage.py migrate
```

Expected: Migrations created and applied with no errors.

- [ ] **Step 5: Run tests to verify they pass**

```bash
python manage.py test apps.accounts.tests -v 2
```

Expected: `6 tests, 0 failures`

- [ ] **Step 6: Commit**

```bash
git add apps/accounts/models.py apps/accounts/tests.py apps/accounts/migrations/
git commit -m "feat: add custom User model with phone_number auth and role system"
```

---

### Task 4: Auth serializers

**Files:**
- Create: `jonglei-backend/apps/accounts/serializers.py`

- [ ] **Step 1: Write failing tests for serializers**

Append to `jonglei-backend/apps/accounts/tests.py`:

```python
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
python manage.py test apps.accounts.tests.RegistrationSerializerTest apps.accounts.tests.UserSerializerTest -v 2
```

Expected: `ImportError` — serializers module doesn't exist yet.

- [ ] **Step 3: Create the serializers**

Create `jonglei-backend/apps/accounts/serializers.py`:

```python
from django.contrib.auth import authenticate
from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    role_display = serializers.CharField(source='get_role_display', read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'phone_number', 'username', 'role', 'role_display',
            'location', 'is_verified', 'rating', 'total_transactions',
            'preferred_language', 'created_at',
        ]
        read_only_fields = ['id', 'is_verified', 'rating', 'total_transactions', 'created_at']


class RegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ['phone_number', 'username', 'password', 'role', 'location', 'preferred_language']

    def create(self, validated_data):
        return User.objects.create_user(
            phone_number=validated_data['phone_number'],
            username=validated_data.get('username', ''),
            password=validated_data['password'],
            role=validated_data.get('role', 'TRADER'),
            location=validated_data.get('location', ''),
            preferred_language=validated_data.get('preferred_language', 'EN'),
        )


class LoginSerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        user = authenticate(
            request=self.context.get('request'),
            username=attrs['phone_number'],
            password=attrs['password'],
        )
        if not user:
            raise serializers.ValidationError('Invalid phone number or password.')
        attrs['user'] = user
        return attrs


class TokenSerializer(serializers.Serializer):
    access_token = serializers.CharField()
    refresh_token = serializers.CharField()
    user = UserSerializer()
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
python manage.py test apps.accounts.tests.RegistrationSerializerTest apps.accounts.tests.UserSerializerTest -v 2
```

Expected: `4 tests, 0 failures`

- [ ] **Step 5: Commit**

```bash
git add apps/accounts/serializers.py apps/accounts/tests.py
git commit -m "feat: add auth serializers for registration, login, and user profile"
```

---

### Task 5: Auth views

**Files:**
- Modify: `jonglei-backend/apps/accounts/views.py`

- [ ] **Step 1: Write failing API tests**

Append to `jonglei-backend/apps/accounts/tests.py`:

```python
from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse


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
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
python manage.py test apps.accounts.tests.AuthAPITest -v 2
```

Expected: `ERRORS` — URL not found (404) because views/urls don't exist yet.

- [ ] **Step 3: Implement the views**

Replace `jonglei-backend/apps/accounts/views.py` with:

```python
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import LoginSerializer, RegistrationSerializer, UserSerializer


def _token_response(user):
    refresh = RefreshToken.for_user(user)
    return {
        'access_token': str(refresh.access_token),
        'refresh_token': str(refresh),
        'user': UserSerializer(user).data,
    }


class AuthViewSet(ViewSet):
    @action(detail=False, methods=['post'], permission_classes=[AllowAny])
    def register(self, request):
        serializer = RegistrationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        user = serializer.save()
        return Response(_token_response(user), status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], permission_classes=[AllowAny])
    def login(self, request):
        serializer = LoginSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        return Response(_token_response(serializer.validated_data['user']))

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def profile(self, request):
        return Response(UserSerializer(request.user).data)

    @action(detail=False, methods=['patch'], permission_classes=[IsAuthenticated])
    def update_profile(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(serializer.data)
```

- [ ] **Step 4: Create URL config for accounts**

Create `jonglei-backend/apps/accounts/urls.py`:

```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AuthViewSet

router = DefaultRouter()
router.register('', AuthViewSet, basename='auth')

urlpatterns = [
    path('', include(router.urls)),
]
```

- [ ] **Step 5: Wire up in core/urls.py**

Replace `jonglei-backend/core/urls.py` with:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/auth/', include('apps.accounts.urls')),
]
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
python manage.py test apps.accounts.tests -v 2
```

Expected: `10 tests, 0 failures`

- [ ] **Step 7: Commit**

```bash
git add apps/accounts/views.py apps/accounts/urls.py core/urls.py
git commit -m "feat: add AuthViewSet with register, login, profile endpoints"
```

---

### Task 6: Admin registration and permissions

**Files:**
- Modify: `jonglei-backend/apps/accounts/admin.py`
- Create: `jonglei-backend/utils/__init__.py`
- Create: `jonglei-backend/utils/permissions.py`

- [ ] **Step 1: Register User in admin**

Replace `jonglei-backend/apps/accounts/admin.py` with:

```python
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['phone_number', 'username', 'role', 'rating', 'is_verified', 'created_at']
    list_filter = ['role', 'is_verified', 'preferred_language']
    search_fields = ['phone_number', 'username']
    ordering = ['-created_at']
    fieldsets = (
        (None, {'fields': ('phone_number', 'password')}),
        ('Personal', {'fields': ('username', 'location', 'preferred_language')}),
        ('Role & Status', {'fields': ('role', 'is_verified', 'rating', 'total_transactions')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('phone_number', 'username', 'password1', 'password2', 'role'),
        }),
    )
```

- [ ] **Step 2: Create utils/permissions.py**

```bash
mkdir -p jonglei-backend/utils
touch jonglei-backend/utils/__init__.py
```

Create `jonglei-backend/utils/permissions.py`:

```python
from rest_framework.permissions import BasePermission


class IsTrader(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'TRADER'


class IsBuyer(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'BUYER'


class IsTransporter(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'TRANSPORTER'


class IsDriver(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'DRIVER'


class IsBorderOfficial(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'BORDER_OFFICIAL'


class IsTransportStaff(BasePermission):
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated
            and request.user.role in ('TRANSPORTER', 'DRIVER')
        )
```

- [ ] **Step 3: Create superuser and verify admin access**

```bash
cd jonglei-backend && source venv/bin/activate
python manage.py createsuperuser --phone_number +211900000000
# Enter a password when prompted
python manage.py runserver
```

Visit `http://localhost:8000/admin/` — you should see Users listed with phone_number, role, rating, is_verified columns.

- [ ] **Step 4: Commit**

```bash
git add apps/accounts/admin.py utils/__init__.py utils/permissions.py
git commit -m "feat: add admin registration and role-based permission classes"
```

---

### Task 7: Smoke test the full backend

- [ ] **Step 1: Run the full test suite**

```bash
cd jonglei-backend && source venv/bin/activate
python manage.py test apps.accounts -v 2
```

Expected: All 10 tests pass.

- [ ] **Step 2: Manual smoke test with curl**

```bash
# Register
curl -s -X POST http://localhost:8000/api/v1/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"+211911111111","username":"smoketest","password":"testpass123","role":"TRADER"}' \
  | python -m json.tool

# Login
curl -s -X POST http://localhost:8000/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"+211911111111","password":"testpass123"}' \
  | python -m json.tool
```

Expected: Both return `access_token`, `refresh_token`, and `user` object.

---

## PART 2 — FLUTTER MOBILE APP

> All commands run from `jonglei/` root (the parent repo), not from inside `jonglei-backend`.

---

### Task 8: Scaffold Flutter project

**Files:**
- Create: `jonglei-mobile/` (entire Flutter project)

- [ ] **Step 1: Create Flutter project**

```bash
cd /home/nzabanita/PycharmProjects/jonglei
flutter create jonglei_mobile --org com.jonglei --project-name jonglei_fish_hub
mv jonglei_mobile jonglei-mobile
cd jonglei-mobile
```

- [ ] **Step 2: Add dependencies to pubspec.yaml**

In `jonglei-mobile/pubspec.yaml`, replace the `dependencies:` section with:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  provider: ^6.1.1
  flutter_secure_storage: ^9.0.0
```

> Note: `geolocator`, `qr_code_scanner`, `qr_flutter`, `google_maps_flutter` are Day 2+ features. Keep Day 1 lean.

- [ ] **Step 3: Install dependencies**

```bash
cd jonglei-mobile
flutter pub get
```

Expected: `Got dependencies!`

- [ ] **Step 4: Create folder structure**

```bash
mkdir -p lib/config lib/models lib/services lib/providers
mkdir -p lib/screens/auth lib/screens/trader lib/screens/buyer lib/screens/transporter
mkdir -p lib/widgets
```

- [ ] **Step 5: Commit**

```bash
git add jonglei-mobile/
git commit -m "feat: scaffold Flutter project with http, provider, secure_storage"
```

---

### Task 9: Flutter data layer (config, model, storage)

**Files:**
- Create: `jonglei-mobile/lib/config/api_config.dart`
- Create: `jonglei-mobile/lib/models/user.dart`
- Create: `jonglei-mobile/lib/services/storage_service.dart`

- [ ] **Step 1: Write api_config.dart**

Create `jonglei-mobile/lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Android emulator routes 10.0.2.2 to the host machine's localhost
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  // For iOS simulator or physical device on same WiFi, use your machine's IP:
  // static const String baseUrl = 'http://192.168.x.x:8000/api/v1';
}
```

- [ ] **Step 2: Write user.dart**

Create `jonglei-mobile/lib/models/user.dart`:

```dart
class User {
  final String id;
  final String phoneNumber;
  final String username;
  final String role;
  final String roleDisplay;
  final String location;
  final bool isVerified;
  final double rating;

  const User({
    required this.id,
    required this.phoneNumber,
    required this.username,
    required this.role,
    required this.roleDisplay,
    required this.location,
    required this.isVerified,
    required this.rating,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        phoneNumber: json['phone_number'] as String,
        username: json['username'] as String? ?? '',
        role: json['role'] as String,
        roleDisplay: json['role_display'] as String? ?? '',
        location: json['location'] as String? ?? '',
        isVerified: json['is_verified'] as bool? ?? false,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'username': username,
        'role': role,
        'role_display': roleDisplay,
        'location': location,
        'is_verified': isVerified,
        'rating': rating,
      };
}
```

- [ ] **Step 3: Write storage_service.dart**

Create `jonglei-mobile/lib/services/storage_service.dart`:

```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUser(User user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearAll() async => _storage.deleteAll();
}
```

- [ ] **Step 4: Commit**

```bash
cd jonglei-mobile
git add lib/config/ lib/models/ lib/services/storage_service.dart
git commit -m "feat: add API config, User model, and secure token storage"
```

---

### Task 10: Flutter API and auth services

**Files:**
- Create: `jonglei-mobile/lib/services/api_service.dart`
- Create: `jonglei-mobile/lib/services/auth_service.dart`

- [ ] **Step 1: Write api_service.dart**

Create `jonglei-mobile/lib/services/api_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  final StorageService _storage;

  ApiService(this._storage);

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool requiresAuth = false}) async {
    final headers = requiresAuth
        ? await _authHeaders()
        : {'Content-Type': 'application/json'};
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _authHeaders(),
    );
    return _handle(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    final message = body is Map ? (body['detail'] ?? body.toString()) : body.toString();
    throw ApiException(response.statusCode, message.toString());
  }
}
```

- [ ] **Step 2: Write auth_service.dart**

Create `jonglei-mobile/lib/services/auth_service.dart`:

```dart
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api;
  final StorageService _storage;

  AuthService(this._api, this._storage);

  Future<User> register({
    required String phoneNumber,
    required String username,
    required String password,
    required String role,
    String location = '',
    String preferredLanguage = 'EN',
  }) async {
    final data = await _api.post('/auth/register/', {
      'phone_number': phoneNumber,
      'username': username,
      'password': password,
      'role': role,
      'location': location,
      'preferred_language': preferredLanguage,
    });
    return _saveSession(data as Map<String, dynamic>);
  }

  Future<User> login({
    required String phoneNumber,
    required String password,
  }) async {
    final data = await _api.post('/auth/login/', {
      'phone_number': phoneNumber,
      'password': password,
    });
    return _saveSession(data as Map<String, dynamic>);
  }

  Future<User> _saveSession(Map<String, dynamic> data) async {
    await _storage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveUser(user);
    return user;
  }

  Future<void> logout() => _storage.clearAll();

  Future<User?> getCurrentUser() => _storage.getUser();
}
```

- [ ] **Step 3: Verify Dart analysis**

```bash
cd jonglei-mobile
flutter analyze lib/services/
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/services/
git commit -m "feat: add ApiService and AuthService for HTTP and auth operations"
```

---

### Task 11: Flutter AuthProvider

**Files:**
- Create: `jonglei-mobile/lib/providers/auth_provider.dart`

- [ ] **Step 1: Write auth_provider.dart**

Create `jonglei-mobile/lib/providers/auth_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _currentUser;
  bool _loading = false;
  String? _errorMessage;

  AuthProvider(this._authService);

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<bool> login(String phoneNumber, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authService.login(
        phoneNumber: phoneNumber,
        password: password,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String phoneNumber,
    required String username,
    required String password,
    required String role,
    String location = '',
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authService.register(
        phoneNumber: phoneNumber,
        username: username,
        password: password,
        role: role,
        location: location,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/providers/
git commit -m "feat: add AuthProvider with login, register, logout state management"
```

---

### Task 12: Flutter auth screens

**Files:**
- Create: `jonglei-mobile/lib/screens/auth/login_screen.dart`
- Create: `jonglei-mobile/lib/screens/auth/register_screen.dart`
- Create: `jonglei-mobile/lib/widgets/custom_button.dart`

- [ ] **Step 1: Write custom_button.dart**

Create `jonglei-mobile/lib/widgets/custom_button.dart`:

```dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
```

- [ ] **Step 2: Write login_screen.dart**

Create `jonglei-mobile/lib/screens/auth/login_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+211');
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final ok = await provider.login(
      _phoneController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      _navigateByRole(context.read<AuthProvider>().currentUser!.role);
    }
  }

  void _navigateByRole(String role) {
    final routes = {
      'TRADER': '/trader',
      'BUYER': '/buyer',
      'TRANSPORTER': '/transporter',
      'DRIVER': '/transporter',
    };
    Navigator.pushReplacementNamed(context, routes[role] ?? '/trader');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.set_meal, size: 72, color: Color(0xFF1565C0)),
                  const SizedBox(height: 8),
                  const Text(
                    'Jonglei Fish Hub',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v != null && v.startsWith('+211') ? null : 'Enter a valid +211 number',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v != null && v.length >= 8 ? null : 'Password must be 8+ characters',
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(auth.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Login',
                    onPressed: _submit,
                    loading: auth.loading,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text("Don't have an account? Register"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Write register_screen.dart**

Create `jonglei-mobile/lib/screens/auth/register_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+211');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedRole = 'TRADER';

  static const _roles = [
    ('TRADER', 'Fish Trader'),
    ('BUYER', 'Buyer'),
    ('TRANSPORTER', 'Transporter'),
    ('DRIVER', 'Driver'),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final ok = await provider.register(
      phoneNumber: _phoneController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      location: _locationController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      final role = context.read<AuthProvider>().currentUser!.role;
      final routes = {
        'TRADER': '/trader',
        'BUYER': '/buyer',
        'TRANSPORTER': '/transporter',
        'DRIVER': '/transporter',
      };
      Navigator.pushReplacementNamed(context, routes[role] ?? '/trader');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v != null && v.startsWith('+211') ? null : 'Enter a valid +211 number',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v != null && v.trim().isNotEmpty ? null : 'Name is required',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v != null && v.length >= 8 ? null : 'Password must be 8+ characters',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(auth.errorMessage!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Create Account',
                  onPressed: _submit,
                  loading: auth.loading,
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/ lib/widgets/
git commit -m "feat: add login and register screens with form validation"
```

---

### Task 13: Flutter home screens and main.dart

**Files:**
- Create: `jonglei-mobile/lib/screens/trader/trader_home.dart`
- Create: `jonglei-mobile/lib/screens/buyer/buyer_home.dart`
- Create: `jonglei-mobile/lib/screens/transporter/transporter_home.dart`
- Modify: `jonglei-mobile/lib/main.dart`

- [ ] **Step 1: Write placeholder home screens**

Create `jonglei-mobile/lib/screens/trader/trader_home.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class TraderHomeScreen extends StatelessWidget {
  const TraderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trader Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome, ${user?.username ?? 'Trader'}!\nRole: ${user?.roleDisplay}',
            textAlign: TextAlign.center),
      ),
    );
  }
}
```

Create `jonglei-mobile/lib/screens/buyer/buyer_home.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class BuyerHomeScreen extends StatelessWidget {
  const BuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome, ${user?.username ?? 'Buyer'}!\nRole: ${user?.roleDisplay}',
            textAlign: TextAlign.center),
      ),
    );
  }
}
```

Create `jonglei-mobile/lib/screens/transporter/transporter_home.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class TransporterHomeScreen extends StatelessWidget {
  const TransporterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome, ${user?.username ?? 'Transporter'}!\nRole: ${user?.roleDisplay}',
            textAlign: TextAlign.center),
      ),
    );
  }
}
```

- [ ] **Step 2: Write main.dart**

Replace `jonglei-mobile/lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/trader/trader_home.dart';
import 'screens/buyer/buyer_home.dart';
import 'screens/transporter/transporter_home.dart';

void main() {
  final storage = StorageService();
  final api = ApiService(storage);
  final auth = AuthService(api, storage);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(auth)..checkAuthStatus(),
      child: const JongleiApp(),
    ),
  );
}

class JongleiApp extends StatelessWidget {
  const JongleiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jonglei Fish Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return _homeForRole(auth.currentUser!.role);
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/trader': (_) => const TraderHomeScreen(),
        '/buyer': (_) => const BuyerHomeScreen(),
        '/transporter': (_) => const TransporterHomeScreen(),
      },
    );
  }

  Widget _homeForRole(String role) {
    switch (role) {
      case 'BUYER':
        return const BuyerHomeScreen();
      case 'TRANSPORTER':
      case 'DRIVER':
        return const TransporterHomeScreen();
      default:
        return const TraderHomeScreen();
    }
  }
}
```

- [ ] **Step 3: Verify the app compiles**

```bash
cd jonglei-mobile
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/
git commit -m "feat: wire up main.dart with role-based routing and auth state"
```

---

## PART 3 — REACT DASHBOARD

> Run these commands from `jonglei/` root.

---

### Task 14: Scaffold React project

**Files:**
- Create: `jonglei-dashboard/` (new Vite project)

- [ ] **Step 1: Create Vite project**

```bash
cd /home/nzabanita/PycharmProjects/jonglei
npm create vite@latest jonglei-dashboard -- --template react
cd jonglei-dashboard
```

- [ ] **Step 2: Install dependencies**

```bash
npm install axios react-router-dom recharts @headlessui/react
npm install -D tailwindcss postcss autoprefixer vitest @testing-library/react @testing-library/jest-dom jsdom
npx tailwindcss init -p
```

- [ ] **Step 3: Configure Tailwind**

Replace `jonglei-dashboard/tailwind.config.js` with:

```js
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: { extend: {} },
  plugins: [],
}
```

- [ ] **Step 4: Add Tailwind to CSS**

Replace `jonglei-dashboard/src/index.css` with:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

- [ ] **Step 5: Configure Vitest**

In `jonglei-dashboard/vite.config.js`, add the test config:

```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.js'],
  },
})
```

Create `jonglei-dashboard/src/test/setup.js`:

```js
import '@testing-library/jest-dom'
```

- [ ] **Step 6: Create folder structure**

```bash
mkdir -p src/api src/context src/components src/pages src/test
```

- [ ] **Step 7: Commit**

```bash
git add jonglei-dashboard/
git commit -m "feat: scaffold React dashboard with Vite, Tailwind, Vitest"
```

---

### Task 15: React API layer and auth context

**Files:**
- Create: `jonglei-dashboard/src/api/axios.js`
- Create: `jonglei-dashboard/src/context/AuthContext.jsx`

- [ ] **Step 1: Write failing test for AuthContext**

Create `jonglei-dashboard/src/test/AuthContext.test.jsx`:

```jsx
import { render, screen, act } from '@testing-library/react'
import { AuthProvider, useAuth } from '../context/AuthContext'

function TestConsumer() {
  const { isAuthenticated, user } = useAuth()
  return (
    <div>
      <span data-testid="auth">{isAuthenticated ? 'yes' : 'no'}</span>
      <span data-testid="user">{user ? user.phoneNumber : 'none'}</span>
    </div>
  )
}

test('starts unauthenticated with no user', () => {
  render(
    <AuthProvider>
      <TestConsumer />
    </AuthProvider>
  )
  expect(screen.getByTestId('auth').textContent).toBe('no')
  expect(screen.getByTestId('user').textContent).toBe('none')
})

test('login stores user and marks authenticated', async () => {
  const fakeUser = { id: '1', phone_number: '+211912', username: 'u', role: 'ADMIN', role_display: 'Administrator' }
  localStorage.setItem('access_token', 'fake-token')
  localStorage.setItem('user', JSON.stringify(fakeUser))

  render(
    <AuthProvider>
      <TestConsumer />
    </AuthProvider>
  )
  expect(screen.getByTestId('auth').textContent).toBe('yes')
  expect(screen.getByTestId('user').textContent).toBe('+211912')
  localStorage.clear()
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd jonglei-dashboard
npx vitest run src/test/AuthContext.test.jsx
```

Expected: `FAIL` — `AuthContext` module not found.

- [ ] **Step 3: Write axios.js**

Create `jonglei-dashboard/src/api/axios.js`:

```js
import axios from 'axios'

const api = axios.create({
  baseURL: 'http://localhost:8000/api/v1',
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('access_token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
```

- [ ] **Step 4: Write AuthContext.jsx**

Create `jonglei-dashboard/src/context/AuthContext.jsx`:

```jsx
import { createContext, useContext, useState } from 'react'
import api from '../api/axios'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const raw = localStorage.getItem('user')
    return raw ? JSON.parse(raw) : null
  })

  const isAuthenticated = user !== null

  async function login(phoneNumber, password) {
    const { data } = await api.post('/auth/login/', { phone_number: phoneNumber, password })
    localStorage.setItem('access_token', data.access_token)
    localStorage.setItem('refresh_token', data.refresh_token)
    localStorage.setItem('user', JSON.stringify(data.user))
    setUser(data.user)
    return data.user
  }

  function logout() {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('user')
    setUser(null)
  }

  return (
    <AuthContext.Provider value={{ user, isAuthenticated, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
npx vitest run src/test/AuthContext.test.jsx
```

Expected: `2 tests passed`

- [ ] **Step 6: Commit**

```bash
git add src/api/ src/context/ src/test/
git commit -m "feat: add Axios client and AuthContext with JWT persistence"
```

---

### Task 16: React Login page

**Files:**
- Create: `jonglei-dashboard/src/pages/Login.jsx`
- Create: `jonglei-dashboard/src/test/Login.test.jsx`

- [ ] **Step 1: Write failing test**

Create `jonglei-dashboard/src/test/Login.test.jsx`:

```jsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi } from 'vitest'
import Login from '../pages/Login'
import { AuthContext } from '../context/AuthContext'

function renderLogin(loginFn = vi.fn()) {
  return render(
    <AuthContext.Provider value={{ login: loginFn, isAuthenticated: false }}>
      <MemoryRouter>
        <Login />
      </MemoryRouter>
    </AuthContext.Provider>
  )
}

test('renders phone and password fields', () => {
  renderLogin()
  expect(screen.getByLabelText(/phone number/i)).toBeInTheDocument()
  expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
})

test('calls login with entered credentials', async () => {
  const mockLogin = vi.fn().mockResolvedValue({ role: 'ADMIN' })
  renderLogin(mockLogin)

  fireEvent.change(screen.getByLabelText(/phone number/i), {
    target: { value: '+211911111111' },
  })
  fireEvent.change(screen.getByLabelText(/password/i), {
    target: { value: 'securepass' },
  })
  fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

  await waitFor(() => expect(mockLogin).toHaveBeenCalledWith('+211911111111', 'securepass'))
})
```

- [ ] **Step 2: Export AuthContext from context file**

Add `export const AuthContext = createContext(null)` to `AuthContext.jsx` — update the existing line:

```jsx
// Change: const AuthContext = createContext(null)
// To:
export const AuthContext = createContext(null)
```

- [ ] **Step 3: Run test to verify it fails**

```bash
npx vitest run src/test/Login.test.jsx
```

Expected: `FAIL` — `Login` module not found.

- [ ] **Step 4: Write Login.jsx**

Create `jonglei-dashboard/src/pages/Login.jsx`:

```jsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function Login() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [phoneNumber, setPhoneNumber] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await login(phoneNumber, password)
      navigate('/dashboard')
    } catch {
      setError('Invalid phone number or password.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="bg-white rounded-2xl shadow-lg p-8 w-full max-w-sm">
        <div className="text-center mb-6">
          <span className="text-4xl">🐟</span>
          <h1 className="text-2xl font-bold text-gray-900 mt-2">Jonglei Fish Hub</h1>
          <p className="text-gray-500 text-sm">Admin Dashboard</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-1">
              Phone Number
            </label>
            <input
              id="phone"
              type="tel"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              placeholder="+211911111111"
              required
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
              Password
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {error && <p className="text-red-500 text-sm">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-700 hover:bg-blue-800 disabled:bg-blue-400 text-white font-semibold py-2 rounded-lg transition"
          >
            {loading ? 'Signing in…' : 'Sign In'}
          </button>
        </form>
      </div>
    </div>
  )
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
npx vitest run src/test/Login.test.jsx
```

Expected: `2 tests passed`

- [ ] **Step 6: Commit**

```bash
git add src/pages/Login.jsx src/test/Login.test.jsx src/context/AuthContext.jsx
git commit -m "feat: add Login page with phone/password form and error handling"
```

---

### Task 17: React Dashboard, Sidebar, StatCard, and routing

**Files:**
- Create: `jonglei-dashboard/src/components/Sidebar.jsx`
- Create: `jonglei-dashboard/src/components/StatCard.jsx`
- Create: `jonglei-dashboard/src/pages/Dashboard.jsx`
- Modify: `jonglei-dashboard/src/App.jsx`

- [ ] **Step 1: Write Sidebar.jsx**

Create `jonglei-dashboard/src/components/Sidebar.jsx`:

```jsx
import { NavLink } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const links = [
  { to: '/dashboard', label: 'Dashboard', icon: '📊' },
  { to: '/users', label: 'Users', icon: '👥' },
  { to: '/orders', label: 'Orders', icon: '📦' },
  { to: '/shipments', label: 'Shipments', icon: '🚚' },
  { to: '/analytics', label: 'Analytics', icon: '📈' },
]

export default function Sidebar() {
  const { logout, user } = useAuth()

  return (
    <aside className="w-64 bg-blue-900 text-white flex flex-col min-h-screen">
      <div className="p-6 border-b border-blue-800">
        <div className="text-xl font-bold">🐟 Jonglei Fish Hub</div>
        <div className="text-xs text-blue-300 mt-1">Admin Dashboard</div>
      </div>

      <nav className="flex-1 p-4 space-y-1">
        {links.map((link) => (
          <NavLink
            key={link.to}
            to={link.to}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition ${
                isActive
                  ? 'bg-blue-700 text-white'
                  : 'text-blue-200 hover:bg-blue-800 hover:text-white'
              }`
            }
          >
            <span>{link.icon}</span>
            {link.label}
          </NavLink>
        ))}
      </nav>

      <div className="p-4 border-t border-blue-800">
        <div className="text-xs text-blue-300 mb-2">{user?.phone_number}</div>
        <button
          onClick={logout}
          className="w-full text-left text-sm text-blue-200 hover:text-white"
        >
          → Logout
        </button>
      </div>
    </aside>
  )
}
```

- [ ] **Step 2: Write StatCard.jsx**

Create `jonglei-dashboard/src/components/StatCard.jsx`:

```jsx
export default function StatCard({ title, value, icon, trend }) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500">{title}</p>
          <p className="text-3xl font-bold text-gray-900 mt-1">{value ?? '—'}</p>
          {trend && <p className="text-xs text-green-500 mt-1">{trend}</p>}
        </div>
        <div className="text-4xl opacity-80">{icon}</div>
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Write Dashboard.jsx**

Create `jonglei-dashboard/src/pages/Dashboard.jsx`:

```jsx
import { useEffect, useState } from 'react'
import Sidebar from '../components/Sidebar'
import StatCard from '../components/StatCard'
import api from '../api/axios'

export default function Dashboard() {
  const [stats, setStats] = useState(null)

  useEffect(() => {
    api.get('/auth/profile/')
      .then(() => {
        // Placeholder stats — replace with real endpoints in later milestones
        setStats({
          users: '—',
          listings: '—',
          orders: '—',
          shipments: '—',
        })
      })
      .catch(() => {})
  }, [])

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 p-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">Overview</h1>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <StatCard title="Total Users" value={stats?.users} icon="👥" />
          <StatCard title="Active Listings" value={stats?.listings} icon="🐟" />
          <StatCard title="Pending Orders" value={stats?.orders} icon="📦" />
          <StatCard title="Shipments in Transit" value={stats?.shipments} icon="🚚" />
        </div>
      </main>
    </div>
  )
}
```

- [ ] **Step 4: Write App.jsx**

Replace `jonglei-dashboard/src/App.jsx` with:

```jsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './context/AuthContext'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'

function ProtectedRoute({ children }) {
  const { isAuthenticated } = useAuth()
  return isAuthenticated ? children : <Navigate to="/login" replace />
}

function AppRoutes() {
  const { isAuthenticated } = useAuth()
  return (
    <Routes>
      <Route
        path="/login"
        element={isAuthenticated ? <Navigate to="/dashboard" replace /> : <Login />}
      />
      <Route
        path="/dashboard"
        element={<ProtectedRoute><Dashboard /></ProtectedRoute>}
      />
      <Route path="*" element={<Navigate to={isAuthenticated ? '/dashboard' : '/login'} replace />} />
    </Routes>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AuthProvider>
  )
}
```

- [ ] **Step 5: Run the full test suite**

```bash
cd jonglei-dashboard
npx vitest run
```

Expected: `4 tests passed`

- [ ] **Step 6: Start dev server and verify login flow**

```bash
npm run dev
```

Open `http://localhost:5173` — should redirect to `/login`. Login with a user created via the Django API. Should land on `/dashboard` with the 4 stat cards.

- [ ] **Step 7: Commit**

```bash
git add src/
git commit -m "feat: add Dashboard, Sidebar, StatCard and protected routing"
```

---

## Final Verification Checklist

- [ ] `python manage.py test apps.accounts` → 10 tests pass
- [ ] `curl -X POST http://localhost:8000/api/v1/auth/register/` with valid JSON → returns `access_token`
- [ ] `curl -X POST http://localhost:8000/api/v1/auth/login/` with same credentials → returns `access_token`
- [ ] Flutter app on Android emulator → login screen → login with Django user → lands on role-specific home
- [ ] React dashboard at `localhost:5173` → login → redirects to `/dashboard`
- [ ] Same token from Django login works in React dashboard
- [ ] Django admin at `localhost:8000/admin/` shows Users with phone_number, role, rating, is_verified

---

## PostGIS Upgrade (Post Day 1)

Once system packages are installed:

```bash
sudo apt install postgis postgresql-postgis libgdal-dev
psql -U jonglei_admin jonglei_fish_hub -c "CREATE EXTENSION postgis;"
```

In `core/settings.py`, change:
```python
# From:
'ENGINE': 'django.db.backends.postgresql',
# To:
'ENGINE': 'django.contrib.gis.db.backends.postgis',
```

Add to `INSTALLED_APPS`:
```python
'django.contrib.gis',
```

Then run `python manage.py migrate`.



                                                                                                                
● All created. Here's the cheat sheet:                                                                          
                                                                                                                
  ┌───────────────────┬───────────────┬────────────┐                                                            
  │       Role        │     Phone     │  Password  │        
  ├───────────────────┼───────────────┼────────────┤                                                            
  │ Admin (superuser) │ +211900000000 │ Admin@1234 │        
  ├───────────────────┼───────────────┼────────────┤
  │ Trader            │ +211911000001 │ Test@1234  │
  ├───────────────────┼───────────────┼────────────┤                                                            
  │ Buyer             │ +211911000002 │ Test@1234  │
  ├───────────────────┼───────────────┼────────────┤                                                            
  │ Transporter       │ +211911000003 │ Test@1234  │        
  ├───────────────────┼───────────────┼────────────┤                                                            
  │ Driver            │ +211911000004 │ Test@1234  │
  ├───────────────────┼───────────────┼────────────┤                                                            
  │ Border Official   │ +211911000005 │ Test@1234  │        
  ├───────────────────┼───────────────┼────────────┤
  │ Market Official   │ +211911000006 │ Test@1234  │
  └───────────────────┴───────────────┴────────────┘  
  
shp-0041


  ---                                                      
  SPRINT PLAN — START HERE                               
                                                           
  With all of that in scope, here is the full sprint map 
  from now to launch:                           
                                                
  SPRINT 1 (Week 1-2) — THE FOUNDATION          
  └── A: Backend Marketplace + Transport + Clearance models
   (Django)                                                
  └── B: Profile screen redesign (Flutter — fix design
  system violation)                                        
  └── C: Sidebar nav + listings route (Dashboard — add   
  Listings page)                                           
                                                           
  SPRINT 2 (Week 2-3) — CORE FLOWS                         
  └── A: Create Listing multi-step screen (Flutter)        
  └── B: Order Placement flow (Flutter)                    
  └── C: JWT refresh + SMS OTP (Backend)                 
                                                           
  SPRINT 3 (Week 3-4) — CLOSE THE LOOP                   
  └── A: Accept Job + Active Job screen (Flutter           
  transporter)                                           
  └── B: Clearance Action screen (Flutter border official) 
  └── C: Notification system — model + FCM + mobile screen
                                                           
  SPRINT 4 (Week 4-5) — REAL DATA EVERYWHERE             
  └── A: Wire all Flutter screens to real API              
  └── B: Wire all Dashboard pages to real API              
  └── C: Offline cache + connectivity detection (Flutter)
                                                           
  SPRINT 5 (Week 5-6) — TRUST & DELIGHT                  
  └── A: Rating/Review system (Backend + Flutter UI)       
  └── B: Dispute Resolution (Backend + Flutter + Dashboard)
  └── C: WhatsApp integration buttons, photo support,      
  sparklines                                               
                                                           
  SPRINT 6 (Week 6-7) — SCALE & SECURITY                   
  └── A: Docker + CI/CD + Redis + Celery                 
  └── B: Production security hardening                     
  └── C: Price Intelligence + Crowdsourcing                
                                                           
  POST-LAUNCH                                              
  └── Auction system, USSD interface, PWA, payments        
                                                         
  Which sprint do you want to start right now?             
                                                
  Say "start Sprint 1" and I'll begin writing all three    
  tracks immediately — the Django models for all three   
  domain apps, the Flutter profile screen redesign, and the
   Dashboard listings page — in one session.               
                                            
  ---                                                      
  Sources:                                                 
  - https://techcabal.com/2025/12/05/7-african-startups-adv
  ancing-aquaculture-analytics-and-access-to-finance/      
  - https://medium.com/@kimsalim99/the-role-of-digital-tech
  nologies-in-supporting-inclusive-trade-in-fish-fish-produ
  cts-under-the-6d8b6ffda7fb                               
  - https://www.itene.com/en/news/platform-monitoring-cold-
  chain-origin-fish/                                       
  - https://www.seafoodsource.com/features/barcode-driven-p
  roduct-tracking-leads-the-way-in-enabling-seafood-traceab
  ility                                                    
  - https://techcabal.com/2025/10/22/digital-trading-platfo
  rms-transform-financial-access-in-africa/


AIzaSyAMLmDlSMbcAq2Bz8wpMnR2clW3uS82xbY google maps android