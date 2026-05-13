from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import TokenRefreshView
from apps.marketplace.stats_views import dashboard_stats, my_stats, transporter_stats, border_stats


def health_check(request):
    return JsonResponse({'status': 'ok'})


urlpatterns = [
    path('admin/',                         admin.site.urls),
    path('api/v1/health/',                 health_check, name='health-check'),
    path('api/v1/auth/',                   include('apps.accounts.urls')),
    path('api/v1/auth/token/refresh/',     TokenRefreshView.as_view(), name='token_refresh'),
    path('api/v1/marketplace/',            include('apps.marketplace.urls')),
    path('api/v1/transport/',              include('apps.transport.urls')),
    path('api/v1/clearance/',              include('apps.clearance.urls')),
    path('api/v1/notifications/',          include('apps.notifications.urls')),
    path('api/v1/payments/',               include('apps.payments.urls')),
    path('api/v1/messaging/',              include('apps.messaging.urls')),
    path('api/v1/dashboard/stats/',        dashboard_stats, name='dashboard-stats'),
    path('api/v1/dashboard/my-stats/',         my_stats,           name='my-stats'),
    path('api/v1/dashboard/transporter-stats/', transporter_stats,  name='transporter-stats'),
    path('api/v1/dashboard/border-stats/',      border_stats,       name='border-stats'),
]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
