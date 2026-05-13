from rest_framework import status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from .models import Shipment, TrackingEvent, TransportJob
from .serializers import ShipmentSerializer, TrackingEventSerializer, TransportJobSerializer
from apps.notifications.utils import notify_user


class ShipmentViewSet(ModelViewSet):
    serializer_class = ShipmentSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['status', 'order', 'order__listing__species']

    def get_queryset(self):
        user = self.request.user
        qs   = Shipment.objects.select_related('order', 'transporter')
        role = getattr(user, 'role', '')
        if role == 'TRANSPORTER':
            return qs.filter(transporter=user)
        if role == 'BUYER':
            return qs.filter(order__buyer=user)
        if role == 'TRADER':
            return qs.filter(order__listing__seller=user)
        return qs

    @action(detail=True, methods=['post'])
    def add_event(self, request, pk=None):
        shipment = self.get_object()
        serializer = TrackingEventSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save(shipment=shipment, recorded_by=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'])
    def events(self, request, pk=None):
        shipment = self.get_object()
        qs = shipment.events.all()
        return Response(TrackingEventSerializer(qs, many=True).data)


class TransportJobViewSet(ModelViewSet):
    serializer_class = TransportJobSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['status']

    def get_queryset(self):
        user = self.request.user
        qs   = TransportJob.objects.select_related(
            'shipment__order__listing__seller',
            'shipment__order__buyer',
            'transporter',
        )
        status_filter = self.request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter.upper())
        role = getattr(user, 'role', '')
        if role == 'TRANSPORTER':
            return qs.filter(transporter=user) | qs.filter(status='OPEN', transporter__isnull=True)
        return qs

    @action(detail=True, methods=['post'])
    def accept_job(self, request, pk=None):
        job = self.get_object()
        if job.status != 'OPEN':
            return Response({'detail': 'Job is no longer open.'}, status=status.HTTP_400_BAD_REQUEST)
        job.transporter = request.user
        job.status = 'ACCEPTED'
        job.save(update_fields=['transporter', 'status', 'updated_at'])

        # Notify the transporter (confirmation) and the trader (their job was picked up)
        notify_user(
            request.user,
            'Job Accepted',
            f'You have accepted a transport job. Proceed to pick up the shipment.',
            {'job_id': str(job.id), 'type': 'job'},
        )
        try:
            trader = job.shipment.order.listing.seller
            notify_user(
                trader,
                'Transporter Assigned',
                f'{request.user.username} accepted the transport job for your shipment.',
                {'job_id': str(job.id), 'type': 'job'},
            )
        except AttributeError:
            pass

        return Response(TransportJobSerializer(job).data)

    @action(detail=True, methods=['post'])
    def start_transit(self, request, pk=None):
        job = self.get_object()
        if job.transporter != request.user:
            return Response({'detail': 'Not your job.'}, status=status.HTTP_403_FORBIDDEN)
        job.status = 'ACTIVE'
        job.shipment.status = 'IN_TRANSIT'
        job.save(update_fields=['status', 'updated_at'])
        job.shipment.save(update_fields=['status', 'updated_at'])

        try:
            buyer = job.shipment.order.buyer
            notify_user(
                buyer,
                'Shipment Departed',
                f'Your shipment has departed and is on its way.',
                {'job_id': str(job.id), 'type': 'shipment'},
            )
            trader = job.shipment.order.listing.seller
            notify_user(
                trader,
                'Shipment In Transit',
                f'Transporter {request.user.username} has started the delivery.',
                {'job_id': str(job.id), 'type': 'shipment'},
            )
        except AttributeError:
            pass

        return Response(TransportJobSerializer(job).data)

    @action(detail=True, methods=['post'])
    def deliver(self, request, pk=None):
        job = self.get_object()
        if job.transporter != request.user:
            return Response({'detail': 'Not your job.'}, status=status.HTTP_403_FORBIDDEN)
        job.status = 'COMPLETED'
        job.shipment.status = 'DELIVERED'
        job.shipment.progress = 1
        job.save(update_fields=['status', 'updated_at'])
        job.shipment.save(update_fields=['status', 'progress', 'updated_at'])

        try:
            order = job.shipment.order
            notify_user(
                order.buyer,
                'Delivery Complete',
                f'Your order for {order.listing.species} has been delivered successfully.',
                {'job_id': str(job.id), 'type': 'delivery'},
            )
            notify_user(
                order.listing.seller,
                'Delivery Complete',
                f'Shipment for order #{str(order.id)[:8].upper()} was delivered by {request.user.username}.',
                {'job_id': str(job.id), 'type': 'delivery'},
            )
        except AttributeError:
            pass

        return Response(TransportJobSerializer(job).data)
