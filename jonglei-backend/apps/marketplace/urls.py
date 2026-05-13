from django.urls import path, include
from rest_framework.routers import SimpleRouter
from .views import FishListingViewSet, OrderViewSet, SellerRatingViewSet, price_list

router = SimpleRouter()
router.register('listings', FishListingViewSet,   basename='listing')
router.register('orders',   OrderViewSet,         basename='order')
router.register('ratings',  SellerRatingViewSet,  basename='rating')

urlpatterns = [path('', include(router.urls))]
urlpatterns += [
    path('prices/', price_list, name='price-list'),
]
