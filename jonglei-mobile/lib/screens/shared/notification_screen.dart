import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class _Notification {
  final String id;
  final String title;
  final String body;
  final String timestamp;
  final String type; // 'order', 'shipment', 'clearance', 'system'
  final bool isRead;

  const _Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.isRead,
  });

  factory _Notification.fromJson(Map<String, dynamic> j) {
    return _Notification(
      id: j['id']?.toString() ?? '—',
      title: j['title']?.toString() ?? j['verb']?.toString() ?? 'Notification',
      body: j['description']?.toString() ??
          j['body']?.toString() ??
          j['data']?.toString() ??
          '',
      timestamp: j['timestamp']?.toString() ??
          j['created_at']?.toString() ??
          '',
      type: j['notification_type']?.toString() ??
          j['type']?.toString() ??
          'system',
      isRead: j['unread'] == false || j['is_read'] == true,
    );
  }
}

const _sampleNotifications = [
  _Notification(
    id: 'n-1',
    title: 'Order Confirmed',
    body: 'Your order for 50 kg Nile Perch from B. Deng has been confirmed.',
    timestamp: '2026-05-03 09:14',
    type: 'order',
    isRead: false,
  ),
  _Notification(
    id: 'n-2',
    title: 'Shipment Dispatched',
    body: 'SHP-0041 has departed Bor and is en route to Juba.',
    timestamp: '2026-05-03 08:30',
    type: 'shipment',
    isRead: false,
  ),
  _Notification(
    id: 'n-3',
    title: 'Clearance Required',
    body: 'Shipment SHP-0040 requires border clearance at Juba checkpoint.',
    timestamp: '2026-05-02 17:45',
    type: 'clearance',
    isRead: true,
  ),
  _Notification(
    id: 'n-4',
    title: 'Price Update',
    body: 'Tilapia prices have increased 12% in the Malakal market.',
    timestamp: '2026-05-02 14:20',
    type: 'system',
    isRead: true,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<_Notification> _notifications = _sampleNotifications;
  bool _loading = true;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final raw = await api.get('/notifications/') as List;
      if (mounted && raw.isNotEmpty) {
        setState(() {
          _notifications = raw
              .map((j) => _Notification.fromJson(j as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
      // 404 or network error — keep sample data
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    try {
      final api = context.read<AuthProvider>().api;
      await api.post('/notifications/mark_all_read/', {});
    } catch (_) {}
    if (mounted) {
      setState(() {
        _notifications = _notifications
            .map((n) => _Notification(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  timestamp: n.timestamp,
                  type: n.type,
                  isRead: true,
                ))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(
                  18, MediaQuery.of(context).padding.top + 16, 18, 14),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      color: AppColors.onSurface,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (Navigator.of(context).canPop()) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications',
                            style: AppTextStyles.ui(18,
                                weight: FontWeight.w800)),
                        if (_unreadCount > 0)
                          Text('UNREAD: $_unreadCount',
                              style: AppTextStyles.label(10,
                                  color: AppColors.info,
                                  weight: FontWeight.w700))
                        else
                          Text('ALL READ',
                              style: AppTextStyles.label(10,
                                  color: AppColors.success,
                                  weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: Text('Mark all read',
                          style: AppTextStyles.ui(12,
                              color: AppColors.primary,
                              weight: FontWeight.w600)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        size: 20, color: AppColors.onSurfaceVariant),
                    onPressed: _load,
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => const _NotificationSkeleton(),
                  childCount: 4,
                ),
              ),
            )
          else if (_notifications.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 56, color: AppColors.onSurfaceFaint),
                    const SizedBox(height: 16),
                    Text('All caught up',
                        style: AppTextStyles.ui(16,
                            weight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text('No notifications at this time',
                        style: AppTextStyles.ui(12,
                            color: AppColors.onSurfaceFaint)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _NotificationTile(
                    notification: _notifications[i],
                  ),
                  childCount: _notifications.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final _Notification notification;
  const _NotificationTile({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case 'order':
        return Icons.receipt_long_rounded;
      case 'shipment':
        return Icons.local_shipping_rounded;
      case 'clearance':
        return Icons.where_to_vote_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'order':
        return AppColors.secondary;
      case 'shipment':
        return AppColors.primary;
      case 'clearance':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.surface
            : AppColors.infoLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, size: 20, color: _iconColor),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: AppTextStyles.ui(13,
                                weight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700)),
                      ),
                      // Unread blue dot
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(notification.body,
                        style: AppTextStyles.ui(12,
                            color: AppColors.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (notification.timestamp.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(notification.timestamp,
                        style: AppTextStyles.data(10,
                            color: AppColors.onSurfaceFaint)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────
class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14,
                    width: 140,
                    color: AppColors.surfaceHigh),
                const SizedBox(height: 6),
                Container(
                    height: 11,
                    width: double.infinity,
                    color: AppColors.surfaceHighest),
                const SizedBox(height: 4),
                Container(
                    height: 11, width: 180, color: AppColors.surfaceHighest),
                const SizedBox(height: 6),
                Container(
                    height: 10, width: 90, color: AppColors.surfaceHighest),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
