from rest_framework import serializers
from .models import BorderClearance
from apps.accounts.serializers import UserSerializer


class BorderClearanceSerializer(serializers.ModelSerializer):
    officer_detail = UserSerializer(source='officer', read_only=True)

    class Meta:
        model = BorderClearance
        fields = [
            'id', 'shipment', 'checkpoint', 'officer', 'officer_detail',
            'status', 'notes', 'qr_code', 'cleared_at', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'officer', 'qr_code', 'cleared_at', 'created_at', 'updated_at']
