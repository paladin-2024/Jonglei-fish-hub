import base64
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from .models import BorderClearance
from .serializers import BorderClearanceSerializer
from apps.notifications.utils import notify_user, notify_role


class BorderClearanceViewSet(ModelViewSet):
    serializer_class = BorderClearanceSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['status', 'checkpoint', 'shipment']

    def get_queryset(self):
        user = self.request.user
        qs   = BorderClearance.objects.select_related(
            'shipment__order__buyer',
            'shipment__order__listing__seller',
            'officer',
        )
        role = getattr(user, 'role', '')
        status_filter = self.request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter.upper())
        if role == 'BORDER_OFFICIAL':
            return qs.filter(checkpoint=user.location) if user.location else qs
        return qs

    def perform_create(self, serializer):
        serializer.save(officer=self.request.user)
        clearance = serializer.instance
        # Notify border officials at the checkpoint
        notify_role('BORDER_OFFICIAL', 'Clearance Request',
                    f'New clearance request at {clearance.checkpoint or "checkpoint"}.')

    @action(detail=True, methods=['post'], url_path='scan-clear')
    def scan_clear(self, request, pk=None):
        clearance = self.get_object()
        if clearance.status == 'CLEARED':
            return Response({'detail': 'Already cleared.'}, status=status.HTTP_400_BAD_REQUEST)
        clearance.status = 'CLEARED'
        clearance.officer = request.user
        clearance.cleared_at = timezone.now()
        clearance.save(update_fields=['status', 'officer', 'cleared_at', 'updated_at'])

        try:
            order = clearance.shipment.order
            notify_user(order.buyer, 'Border Cleared',
                        'Your shipment has cleared the border checkpoint.',
                        {'clearance_id': str(clearance.id), 'type': 'clearance'})
            notify_user(order.listing.seller, 'Border Cleared',
                        f'Shipment cleared at {clearance.checkpoint or "checkpoint"} by {request.user.username}.',
                        {'clearance_id': str(clearance.id), 'type': 'clearance'})
        except AttributeError:
            pass

        return Response(BorderClearanceSerializer(clearance).data)

    @action(detail=True, methods=['post'])
    def hold(self, request, pk=None):
        clearance = self.get_object()
        clearance.status = 'HELD'
        clearance.notes = request.data.get('notes', clearance.notes)
        clearance.save(update_fields=['status', 'notes', 'updated_at'])

        try:
            order = clearance.shipment.order
            notes_text = clearance.notes or 'No additional notes.'
            notify_user(order.buyer, 'Shipment On Hold',
                        f'Your shipment is on hold at the border checkpoint. {notes_text}',
                        {'clearance_id': str(clearance.id), 'type': 'clearance'})
            notify_user(order.listing.seller, 'Shipment On Hold',
                        f'Shipment placed on hold at {clearance.checkpoint or "checkpoint"}. {notes_text}',
                        {'clearance_id': str(clearance.id), 'type': 'clearance'})
        except AttributeError:
            pass

        return Response(BorderClearanceSerializer(clearance).data)

    @action(detail=True, methods=['get'], url_path='qr')
    def qr_image(self, request, pk=None):
        clearance = self.get_object()
        if not clearance.qr_code:
            clearance.generate_qr()
            clearance.save(update_fields=['qr_code'])
        png_bytes = base64.b64decode(clearance.qr_code)
        from django.http import HttpResponse
        return HttpResponse(png_bytes, content_type='image/png')
