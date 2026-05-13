from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AuthViewSet

router = DefaultRouter()
router.register('', AuthViewSet, basename='auth')

urlpatterns = [
    path('', include(router.urls)),
    path('users/<uuid:pk>/', AuthViewSet.as_view({'patch': 'patch_user'}), name='auth-user-detail'),
]
