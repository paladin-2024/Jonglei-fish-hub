from rest_framework.routers import SimpleRouter
from .views import PaymentViewSet

router = SimpleRouter()
router.register('', PaymentViewSet, basename='payments')
urlpatterns = router.urls
