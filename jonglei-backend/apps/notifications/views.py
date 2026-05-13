from django.db.models import Q
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.mixins import ListModelMixin, RetrieveModelMixin
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework.viewsets import GenericViewSet

from apps.accounts.models import User
from .models import Notification
from .serializers import NotificationSerializer, BroadcastSerializer


class NotificationViewSet(ListModelMixin, RetrieveModelMixin, GenericViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Notification.objects.filter(
            Q(recipient=user) | Q(target_role='ALL') | Q(target_role=user.role)
        ).distinct().order_by('-created_at')

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        notif = self.get_object()
        notif.is_read = True
        notif.save(update_fields=['is_read'])
        return Response({'status': 'ok'})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        Notification.objects.filter(
            recipient=request.user, is_read=False
        ).update(is_read=True)
        return Response({'status': 'ok'})

    @action(detail=False, methods=['post'], permission_classes=[IsAdminUser])
    def broadcast(self, request):
        serializer = BroadcastSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        Notification.objects.create(
            title=data['title'],
            body=data['body'],
            target_role=data['target_role'],
            sent_by=request.user,
        )
        return Response({'status': 'broadcast sent'}, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'], permission_classes=[IsAdminUser])
    def sent(self, request):
        qs = Notification.objects.filter(
            sent_by=request.user, recipient__isnull=True
        ).order_by('-created_at')[:50]
        return Response(NotificationSerializer(qs, many=True).data)
