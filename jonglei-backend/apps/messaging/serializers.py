from rest_framework import serializers
from .models import Thread, Message
from apps.accounts.serializers import UserSerializer


class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source='sender.username', read_only=True)

    class Meta:
        model = Message
        fields = ['id', 'thread', 'sender', 'sender_name', 'body', 'is_read', 'created_at']
        read_only_fields = ['id', 'thread', 'sender', 'sender_name', 'is_read', 'created_at']


class ThreadSerializer(serializers.ModelSerializer):
    buyer_detail    = UserSerializer(source='buyer',  read_only=True)
    seller_detail   = UserSerializer(source='seller', read_only=True)
    listing_species = serializers.CharField(
        source='listing.species', read_only=True, default='')
    last_message    = serializers.SerializerMethodField()
    unread_count    = serializers.SerializerMethodField()

    def get_last_message(self, obj):
        msg = obj.messages.last()
        if msg:
            return {
                'body': msg.body[:100],
                'sender_name': msg.sender.username,
                'created_at': msg.created_at.isoformat(),
            }
        return None

    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request is None:
            return 0
        return obj.messages.filter(is_read=False).exclude(sender=request.user).count()

    class Meta:
        model = Thread
        fields = [
            'id', 'listing', 'listing_species',
            'buyer', 'buyer_detail', 'seller', 'seller_detail',
            'last_message', 'unread_count', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'buyer', 'seller', 'created_at', 'updated_at']
