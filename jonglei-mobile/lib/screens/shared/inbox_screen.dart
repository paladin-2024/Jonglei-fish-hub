import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> _threads = [];
  bool _loading = true;

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
      final data = await api.getList('/messaging/threads/');
      if (mounted) {
        setState(() {
          _threads = data.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
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
                        Text('Messages',
                            style: AppTextStyles.ui(18,
                                weight: FontWeight.w800)),
                        Text('INBOX',
                            style: AppTextStyles.label(10,
                                color: AppColors.onSurfaceVariant)),
                      ],
                    ),
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

          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ThreadSkeleton(),
                  childCount: 4,
                ),
              ),
            )
          else if (_threads.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Column(
                  children: [
                    Icon(Icons.forum_outlined,
                        size: 56, color: AppColors.onSurfaceFaint),
                    const SizedBox(height: 16),
                    Text('No messages yet',
                        style: AppTextStyles.ui(16,
                            weight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text('Start a conversation from a listing',
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
                  (_, i) {
                    final t = _threads[i];
                    final myId = me?.id ?? '';
                    final buyerId  = t['buyer']?.toString()  ?? '';
                    final other    = (myId == buyerId)
                        ? (t['seller_detail'] as Map?)
                        : (t['buyer_detail']  as Map?);
                    final otherName = other?['username']?.toString() ?? '—';
                    final species   = t['listing_species']?.toString() ?? '';
                    final last      = t['last_message'] as Map?;
                    final lastBody  = last?['body']?.toString() ?? 'No messages yet';
                    final lastTime  = last?['created_at']?.toString() ?? '';
                    final unread    = (t['unread_count'] as int? ?? 0);

                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              threadId:    t['id']?.toString() ?? '',
                              otherName:   otherName,
                              species:     species,
                            ),
                          ),
                        );
                        _load();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: unread > 0
                              ? AppColors.infoLight.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  otherName.isNotEmpty
                                      ? otherName[0].toUpperCase()
                                      : '?',
                                  style: AppTextStyles.ui(18,
                                      weight: FontWeight.w800,
                                      color: AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          otherName,
                                          style: AppTextStyles.ui(14,
                                              weight: unread > 0
                                                  ? FontWeight.w800
                                                  : FontWeight.w600),
                                        ),
                                      ),
                                      if (lastTime.length >= 10)
                                        Text(lastTime.substring(0, 10),
                                            style: AppTextStyles.data(10,
                                                color: AppColors.onSurfaceFaint)),
                                    ],
                                  ),
                                  if (species.isNotEmpty) ...[
                                    const SizedBox(height: 1),
                                    Text(species,
                                        style: AppTextStyles.label(10,
                                            color: AppColors.primary,
                                            weight: FontWeight.w700)),
                                  ],
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lastBody,
                                          style: AppTextStyles.ui(12,
                                              color: unread > 0
                                                  ? AppColors.onSurface
                                                  : AppColors.onSurfaceVariant),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (unread > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.info,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text('$unread',
                                              style: AppTextStyles.label(10,
                                                  color: Colors.white,
                                                  weight: FontWeight.w800)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _threads.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _ThreadSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 13, width: 120, color: AppColors.surfaceHigh),
                  const SizedBox(height: 6),
                  Container(height: 11, width: double.infinity, color: AppColors.surfaceHighest),
                  const SizedBox(height: 4),
                  Container(height: 11, width: 160, color: AppColors.surfaceHighest),
                ],
              ),
            ),
          ],
        ),
      );
}
