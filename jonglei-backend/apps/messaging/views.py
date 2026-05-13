from django.db.models import Q
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.mixins import ListModelMixin, RetrieveModelMixin, CreateModelMixin
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import GenericViewSet

from .models import Thread, Message
from .serializers import ThreadSerializer, MessageSerializer
from apps.notifications.utils import notify_user


class ThreadViewSet(ListModelMixin, RetrieveModelMixin, CreateModelMixin, GenericViewSet):
    serializer_class = ThreadSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return (
            Thread.objects.filter(Q(buyer=user) | Q(seller=user))
            .select_related('buyer', 'seller', 'listing')
            .prefetch_related('messages__sender')
            .order_by('-updated_at')
        )

    def create(self, request, *args, **kwargs):
        listing_id = request.data.get('listing')
        if not listing_id:
            return Response(
                {'detail': 'listing is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        from apps.marketplace.models import FishListing
        try:
            listing = FishListing.objects.select_related('seller').get(id=listing_id)
        except FishListing.DoesNotExist:
            return Response(
                {'detail': 'Listing not found'},
                status=status.HTTP_404_NOT_FOUND,
            )
        if listing.seller == request.user:
            return Response(
                {'detail': 'You cannot open a thread on your own listing.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        thread, created = Thread.objects.get_or_create(
            listing=listing,
            buyer=request.user,
            defaults={'seller': listing.seller},
        )
        code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(
            ThreadSerializer(thread, context={'request': request}).data, status=code,
        )

    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        thread = self.get_object()
        # Mark incoming messages as read
        thread.messages.filter(is_read=False).exclude(sender=request.user).update(is_read=True)
        msgs = thread.messages.select_related('sender').all()
        return Response(MessageSerializer(msgs, many=True).data)

    @action(detail=True, methods=['post'])
    def send(self, request, pk=None):
        thread = self.get_object()
        body = (request.data.get('body') or '').strip()
        if not body:
            return Response(
                {'detail': 'Message body is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        msg = Message.objects.create(thread=thread, sender=request.user, body=body)
        thread.save(update_fields=['updated_at'])

        other = thread.seller if request.user == thread.buyer else thread.buyer
        notify_user(
            other,
            f'Message from {request.user.username}',
            body[:120],
            {'thread_id': str(thread.id), 'type': 'message'},
        )
        return Response(MessageSerializer(msg).data, status=status.HTTP_201_CREATED)
