from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Notification
        fields = ['id', 'title', 'body', 'is_read', 'target_role', 'created_at']
        read_only_fields = fields


class BroadcastSerializer(serializers.Serializer):
    title       = serializers.CharField(max_length=255)
    body        = serializers.CharField()
    target_role = serializers.ChoiceField(choices=Notification.ROLE_CHOICES)
