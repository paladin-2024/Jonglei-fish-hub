from rest_framework.permissions import BasePermission


class IsTrader(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'TRADER'


class IsBuyer(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'BUYER'


class IsTransporter(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'TRANSPORTER'


class IsDriver(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'DRIVER'


class IsBorderOfficial(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'BORDER_OFFICIAL'


class IsTransportStaff(BasePermission):
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated
            and request.user.role in ('TRANSPORTER', 'DRIVER')
        )
