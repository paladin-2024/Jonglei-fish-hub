from django.contrib.auth import authenticate
from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    avg_rating   = serializers.FloatField(read_only=True)
    rating_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'phone_number', 'username', 'role', 'role_display',
            'location', 'is_verified', 'rating', 'total_transactions',
            'preferred_language', 'created_at', 'avg_rating', 'rating_count',
            'fcm_token',
        ]
        read_only_fields = ['id', 'is_verified', 'rating', 'total_transactions', 'created_at',
                            'avg_rating', 'rating_count']
        extra_kwargs = {'fcm_token': {'write_only': True}}


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
