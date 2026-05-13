import logging
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import GenericViewSet

from apps.marketplace.models import Order
from apps.notifications.utils import notify_user
from .models import Payment
from .momo import request_to_pay, get_payment_status
from .serializers import PaymentSerializer

logger = logging.getLogger(__name__)


class PaymentViewSet(GenericViewSet):
    serializer_class = PaymentSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['post'], url_path='initiate')
    def initiate(self, request):
        order_id     = request.data.get('order_id')
        payer_phone  = request.data.get('phone_number', '').strip()
        if not order_id or not payer_phone:
            return Response({'detail': 'order_id and phone_number are required.'},
                            status=status.HTTP_400_BAD_REQUEST)

        try:
            import uuid as _uuid
            _uuid.UUID(str(order_id))
        except ValueError:
            return Response({'detail': 'Invalid order ID.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            order = Order.objects.get(pk=order_id, buyer=request.user)
        except Order.DoesNotExist:
            return Response({'detail': 'Order not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Prevent duplicate payment
        if hasattr(order, 'payment') and order.payment.status == 'SUCCESSFUL':
            return Response({'detail': 'Order already paid.'}, status=status.HTTP_400_BAD_REQUEST)

        # Use EUR for sandbox, UGX for production
        from django.conf import settings as dj_settings
        currency = 'EUR' if getattr(dj_settings, 'MOMO_ENVIRONMENT', 'sandbox') == 'sandbox' else 'UGX'

        payment = Payment.objects.create(
            order=order,
            payer_phone=payer_phone,
            amount=order.total_price,
            currency=currency,
        )

        accepted = request_to_pay(
            payer_phone=payer_phone,
            amount=str(payment.amount),
            currency=currency,
            reference_id=str(payment.momo_reference),
            note=f'Fish order {str(order.id)[:8].upper()}',
        )

        if not accepted:
            payment.status = 'FAILED'
            payment.provider_msg = 'MTN MoMo did not accept the request.'
            payment.save(update_fields=['status', 'provider_msg', 'updated_at'])
            return Response({'detail': 'MoMo request failed.'}, status=status.HTTP_502_BAD_GATEWAY)

        return Response(PaymentSerializer(payment).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'], url_path='status')
    def check_status(self, request, pk=None):
        try:
            payment = Payment.objects.select_related('order__buyer').get(pk=pk)
        except Payment.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        if payment.order.buyer != request.user:
            return Response({'detail': 'Forbidden.'}, status=status.HTTP_403_FORBIDDEN)

        if payment.status == 'PENDING':
            provider_status = get_payment_status(str(payment.momo_reference))
            if provider_status in ('SUCCESSFUL', 'FAILED'):
                payment.status = provider_status
                payment.save(update_fields=['status', 'updated_at'])

                if provider_status == 'SUCCESSFUL':
                    # Advance order to CONFIRMED
                    order = payment.order
                    order.status = 'CONFIRMED'
                    order.save(update_fields=['status', 'updated_at'])
                    # Notify buyer (DB record + FCM push)
                    notify_user(
                        order.buyer,
                        'Payment Confirmed ✓',
                        f'MTN MoMo payment received. Your order for {order.listing.species} is confirmed!',
                        {'order_id': str(order.id), 'type': 'payment_confirmed'},
                    )
                    # Notify trader that payment came in
                    notify_user(
                        order.listing.seller,
                        'Payment Received',
                        f'MoMo payment for order #{str(order.id)[:8].upper()} ({order.listing.species}) confirmed.',
                        {'order_id': str(order.id), 'type': 'payment_confirmed'},
                    )

        return Response(PaymentSerializer(payment).data)
