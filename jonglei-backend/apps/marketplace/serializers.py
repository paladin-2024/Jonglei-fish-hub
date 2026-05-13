from rest_framework import serializers
from .models import FishListing, Order, SellerRating
from apps.accounts.serializers import UserSerializer


class FishListingSerializer(serializers.ModelSerializer):
    seller_detail = UserSerializer(source='seller', read_only=True)
    photo_url = serializers.SerializerMethodField()

    def get_photo_url(self, obj):
        if obj.photo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.photo.url)
        return None

    class Meta:
        model = FishListing
        fields = [
            'id', 'seller', 'seller_detail', 'species', 'description',
            'quantity_kg', 'price_ssp', 'unit', 'location', 'photo', 'photo_url',
            'status', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'seller', 'created_at', 'updated_at']


class OrderSerializer(serializers.ModelSerializer):
    buyer_detail   = UserSerializer(source='buyer', read_only=True)
    listing_detail = FishListingSerializer(source='listing', read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'listing', 'listing_detail', 'buyer', 'buyer_detail',
            'quantity_kg', 'total_price', 'status', 'note',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'buyer', 'total_price', 'created_at', 'updated_at']

    def create(self, validated_data):
        listing = validated_data['listing']
        quantity = validated_data['quantity_kg']
        validated_data['total_price'] = listing.price_ssp * quantity
        validated_data['buyer'] = self.context['request'].user
        return super().create(validated_data)


class SellerRatingSerializer(serializers.ModelSerializer):
    buyer_name = serializers.CharField(source='buyer.username', read_only=True)

    class Meta:
        model  = SellerRating
        fields = ['id', 'stars', 'comment', 'buyer_name', 'created_at', 'order']
        read_only_fields = ['buyer_name', 'created_at']

    def validate_stars(self, value):
        if not (1 <= value <= 5):
            raise serializers.ValidationError('Stars must be between 1 and 5.')
        return value
