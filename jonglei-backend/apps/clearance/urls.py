from django.urls import path, include
from rest_framework.routers import SimpleRouter
from .views import BorderClearanceViewSet

router = SimpleRouter()
router.register('clearances', BorderClearanceViewSet, basename='clearance')

urlpatterns = [path('', include(router.urls))]
