from rest_framework import status
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
from rest_framework.viewsets import ViewSet
from rest_framework_simplejwt.tokens import RefreshToken

from .models import OTP, User
from .serializers import LoginSerializer, RegistrationSerializer, UserSerializer
from .sms import send_otp_sms


class LoginRateThrottle(AnonRateThrottle):
    scope = 'login'


class RegisterRateThrottle(AnonRateThrottle):
    scope = 'register'


class OTPRateThrottle(AnonRateThrottle):
    scope = 'otp'


def _token_response(user):
    refresh = RefreshToken.for_user(user)
    return {
        'access_token':  str(refresh.access_token),
        'refresh_token': str(refresh),
        'user':          UserSerializer(user).data,
    }


class AuthViewSet(ViewSet):
    @action(detail=False, methods=['post'], permission_classes=[AllowAny],
            throttle_classes=[RegisterRateThrottle])
    def register(self, request):
        serializer = RegistrationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        user = serializer.save()
        return Response(_token_response(user), status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], permission_classes=[AllowAny],
            throttle_classes=[LoginRateThrottle])
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

    @action(detail=False, methods=['get'], permission_classes=[IsAdminUser])
    def users(self, request):
        qs = User.objects.all().order_by('-date_joined')
        role = request.query_params.get('role')
        if role:
            qs = qs.filter(role=role.upper())
        return Response(UserSerializer(qs, many=True).data)

    @action(detail=True, methods=['patch'], url_path='', permission_classes=[IsAdminUser])
    def patch_user(self, request, pk=None):
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        allowed = {'is_verified', 'is_active', 'role', 'location'}
        data = {k: v for k, v in request.data.items() if k in allowed}
        for field, value in data.items():
            setattr(user, field, value)
        user.save(update_fields=list(data.keys()))
        return Response(UserSerializer(user).data)

    # ── OTP ──────────────────────────────────────────────────────────────────

    @action(detail=False, methods=['post'], url_path='send-otp',
            permission_classes=[AllowAny], throttle_classes=[OTPRateThrottle])
    def send_otp(self, request):
        phone = request.data.get('phone_number', '').strip()
        if not phone:
            return Response({'detail': 'phone_number is required.'}, status=status.HTTP_400_BAD_REQUEST)
        otp = OTP.generate(phone)
        send_otp_sms(phone, otp.code)
        return Response({'detail': 'OTP sent.'})

    @action(detail=False, methods=['post'], url_path='verify-otp',
            permission_classes=[AllowAny])
    def verify_otp(self, request):
        phone = request.data.get('phone_number', '').strip()
        code  = request.data.get('code', '').strip()
        if not phone or not code:
            return Response({'detail': 'phone_number and code are required.'},
                            status=status.HTTP_400_BAD_REQUEST)

        otp = OTP.objects.filter(phone_number=phone, is_used=False).order_by('-created_at').first()
        if not otp or not otp.is_valid(code):
            return Response({'detail': 'Invalid or expired OTP.'},
                            status=status.HTTP_400_BAD_REQUEST)

        otp.is_used = True
        otp.save(update_fields=['is_used'])

        # Mark user as verified if they exist
        User.objects.filter(phone_number=phone).update(is_verified=True)

        # Return tokens if user exists, otherwise just confirm verification
        user = User.objects.filter(phone_number=phone).first()
        if user:
            return Response({'verified': True, **_token_response(user)})
        return Response({'verified': True})

    # ── FCM token ─────────────────────────────────────────────────────────────

    @action(detail=False, methods=['post'], url_path='fcm-token',
            permission_classes=[IsAuthenticated])
    def update_fcm_token(self, request):
        token = request.data.get('fcm_token', '').strip()
        if not token:
            return Response({'detail': 'fcm_token is required.'}, status=status.HTTP_400_BAD_REQUEST)
        request.user.fcm_token = token
        request.user.save(update_fields=['fcm_token'])
        return Response({'detail': 'FCM token updated.'})
