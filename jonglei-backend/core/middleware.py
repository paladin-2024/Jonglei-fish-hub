import logging
import time

logger = logging.getLogger('jonglei.activity')


class UserActivityMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start = time.monotonic()
        response = self.get_response(request)
        duration_ms = round((time.monotonic() - start) * 1000)

        if request.path.startswith('/api/') and request.method in ('POST', 'PATCH', 'DELETE'):
            user = getattr(request, 'user', None)
            username = user.username if user and user.is_authenticated else 'anon'
            logger.info(
                '%s %s %s %dms user=%s',
                request.method, request.path, response.status_code, duration_ms, username,
            )
        return response
