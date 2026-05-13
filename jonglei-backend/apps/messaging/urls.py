from django.urls import path, include
from rest_framework.routers import SimpleRouter
from .views import ThreadViewSet

router = SimpleRouter()
router.register('threads', ThreadViewSet, basename='thread')

urlpatterns = [
    path('', include(router.urls)),
]
