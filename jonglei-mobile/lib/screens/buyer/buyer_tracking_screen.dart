import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class BuyerTrackingScreen extends StatefulWidget {
  final String orderId;
  final String species;

  const BuyerTrackingScreen({
    super.key,
    required this.orderId,
    required this.species,
  });

  @override
  State<BuyerTrackingScreen> createState() => _BuyerTrackingScreenState();
}

class _BuyerTrackingScreenState extends State<BuyerTrackingScreen> {
  Map<String, dynamic>? _shipment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.getList('/transport/shipments/?order=${widget.orderId}');
      if (mounted) {
        if (data.isNotEmpty) {
          setState(() => _shipment = data.first as Map<String, dynamic>);
        } else {
          setState(() => _error = 'No shipment yet');
        }
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load tracking data');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.onSurface, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Track Shipment',
                style: AppTextStyles.label(13,
                    color: AppColors.onSurface, weight: FontWeight.w700)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.onSurfaceVariant, size: 20),
                onPressed: _load,
              ),
            ],
          ),

          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 56, color: AppColors.onSurfaceFaint),
                    const SizedBox(height: 16),
                    Text(widget.species,
                        style: AppTextStyles.ui(16, weight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Shipment not dispatched yet',
                        style: AppTextStyles.ui(14,
                            color: AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(
                        'The seller will dispatch your order soon.\nCheck back here for live updates.',
                        style: AppTextStyles.ui(12,
                            color: AppColors.onSurfaceFaint),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ..._buildContent(),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    final s = _shipment!;
    final origin      = s['origin']      as String? ?? '—';
    final destination = s['destination'] as String? ?? '—';
    final statusRaw   = (s['status']     as String? ?? 'PENDING').toUpperCase();
    final progress    = (s['progress']   as num? ?? 0).toDouble();
    final transporter = (s['transporter_detail'] as Map?)?['username'] as String?;
    final species     = s['order_species']    as String? ?? widget.species;
    final qty         = s['order_quantity_kg']?.toString() ?? '';
    final estimated   = s['estimated_date']   as String? ?? '';
    final events      = (s['events']          as List? ?? []);

    return [
      // ── Route + progress card ────────────────────────────────────────────────
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(species,
                              style: AppTextStyles.ui(17,
                                  weight: FontWeight.w800)),
                          if (qty.isNotEmpty)
                            Text('$qty KG',
                                style: AppTextStyles.ui(12,
                                    color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    StatusBadge.fromString(statusRaw),
                  ],
                ),

                const SizedBox(height: 16),

                // Route line
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                        ),
                        Container(
                            width: 2, height: 30, color: AppColors.surfaceHigh),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(origin,
                              style: AppTextStyles.ui(14,
                                  weight: FontWeight.w700)),
                          const SizedBox(height: 20),
                          Text(destination,
                              style: AppTextStyles.ui(14,
                                  weight: FontWeight.w700,
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% of route completed',
                  style: AppTextStyles.ui(11,
                      color: AppColors.onSurfaceVariant),
                ),

                if (transporter != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('Driver: $transporter',
                          style: AppTextStyles.ui(12,
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],

                if (estimated.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('Est. arrival: $estimated',
                          style: AppTextStyles.ui(12,
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      // ── Tracking events header ───────────────────────────────────────────────
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            children: [
              Text('Tracking Events',
                  style: AppTextStyles.ui(15,
                      weight: FontWeight.w700,
                      color: AppColors.onSurface)),
              const Spacer(),
              if (events.isNotEmpty)
                Text('${events.length} EVENTS',
                    style: AppTextStyles.label(10,
                        color: AppColors.onSurfaceFaint,
                        weight: FontWeight.w700)),
            ],
          ),
        ),
      ),

      if (events.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Center(
                child: Text('No tracking events recorded yet',
                    style: AppTextStyles.ui(13,
                        color: AppColors.onSurfaceVariant)),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final ev    = events[i] as Map<String, dynamic>;
                final isLast = i == events.length - 1;
                return _TrackingEventTile(event: ev, isLast: isLast);
              },
              childCount: events.length,
            ),
          ),
        ),

      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }
}

// ─── Tracking event tile ──────────────────────────────────────────────────────
class _TrackingEventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isLast;
  const _TrackingEventTile({required this.event, required this.isLast});

  static const _stageLabels = {
    'LOADED':        'Fish Loaded',
    'DEPARTED':      'Departed Origin',
    'EN_ROUTE':      'En Route',
    'AT_CHECKPOINT': 'At Checkpoint',
    'ARRIVED':       'Arrived Destination',
    'DELIVERED':     'Delivered',
  };

  @override
  Widget build(BuildContext context) {
    final stage     = event['stage']     as String? ?? '';
    final note      = event['note']      as String? ?? '';
    final timestamp = event['timestamp'] as String? ?? '';
    final label     = _stageLabels[stage] ?? stage.replaceAll('_', ' ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline spine
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: isLast ? AppColors.success : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                        width: 2,
                        color: AppColors.surfaceHigh,
                        margin: const EdgeInsets.symmetric(vertical: 4)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.ui(13,
                          weight: FontWeight.w700,
                          color: AppColors.onSurface)),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(note,
                        style: AppTextStyles.ui(12,
                            color: AppColors.onSurfaceVariant)),
                  ],
                  if (timestamp.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      timestamp.length > 16
                          ? timestamp.substring(0, 16)
                          : timestamp,
                      style: AppTextStyles.data(10,
                          color: AppColors.onSurfaceFaint),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
