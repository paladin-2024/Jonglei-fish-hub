from django.urls import path, include
from rest_framework.routers import SimpleRouter
from .views import ShipmentViewSet, TransportJobViewSet

router = SimpleRouter()
router.register('shipments', ShipmentViewSet,    basename='shipment')
router.register('jobs',      TransportJobViewSet, basename='transport-job')

urlpatterns = [path('', include(router.urls))]
