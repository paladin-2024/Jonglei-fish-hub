from rest_framework import serializers
from .models import Shipment, TrackingEvent, TransportJob
from apps.accounts.serializers import UserSerializer


class TrackingEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrackingEvent
        fields = ['id', 'shipment', 'stage', 'note', 'recorded_by', 'timestamp']
        read_only_fields = ['id', 'shipment', 'recorded_by', 'timestamp']


class ShipmentSerializer(serializers.ModelSerializer):
    transporter_detail = UserSerializer(source='transporter', read_only=True)
    events             = TrackingEventSerializer(many=True, read_only=True)
    order_species      = serializers.CharField(
        source='order.listing.species', read_only=True, default='')
    order_quantity_kg  = serializers.DecimalField(
        source='order.quantity_kg', read_only=True,
        max_digits=10, decimal_places=2, default=0)
    order_seller_name  = serializers.CharField(
        source='order.listing.seller.username', read_only=True, default='')
    order_buyer_name   = serializers.CharField(
        source='order.buyer.username', read_only=True, default='')
    order_price_ssp    = serializers.DecimalField(
        source='order.listing.price_ssp', read_only=True,
        max_digits=12, decimal_places=2, default=0)
    order_total_price  = serializers.DecimalField(
        source='order.total_price', read_only=True,
        max_digits=14, decimal_places=2, default=0)

    class Meta:
        model = Shipment
        fields = [
            'id', 'order', 'order_species', 'order_quantity_kg',
            'order_seller_name', 'order_buyer_name',
            'order_price_ssp', 'order_total_price',
            'carrier_name', 'transporter', 'transporter_detail',
            'origin', 'destination', 'status', 'progress', 'estimated_date',
            'events', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class TransportJobSerializer(serializers.ModelSerializer):
    transporter_detail = UserSerializer(source='transporter', read_only=True)

    class Meta:
        model = TransportJob
        fields = [
            'id', 'shipment', 'pay_ssp', 'transporter', 'transporter_detail',
            'status', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'transporter', 'created_at', 'updated_at']
