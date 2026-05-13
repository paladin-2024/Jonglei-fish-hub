from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['phone_number', 'username', 'role', 'rating', 'is_verified', 'created_at']
    list_filter = ['role', 'is_verified', 'preferred_language']
    search_fields = ['phone_number', 'username']
    ordering = ['-created_at']
    fieldsets = (
        (None, {'fields': ('phone_number', 'password')}),
        ('Personal', {'fields': ('username', 'location', 'preferred_language')}),
        ('Role & Status', {'fields': ('role', 'is_verified', 'rating', 'total_transactions')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('phone_number', 'username', 'password1', 'password2', 'role'),
        }),
    )
