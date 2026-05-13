from django.contrib import admin
from .models import Payment


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ['id', 'order', 'payer_phone', 'amount', 'currency', 'status', 'created_at']
    list_filter  = ['status', 'currency']
