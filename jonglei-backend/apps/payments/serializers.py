from rest_framework import serializers
from .models import Payment


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = ['id', 'order', 'payer_phone', 'amount', 'currency',
                  'momo_reference', 'status', 'provider_msg', 'created_at']
        read_only_fields = ['id', 'momo_reference', 'status', 'provider_msg', 'created_at']
