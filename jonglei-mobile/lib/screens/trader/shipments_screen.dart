import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TraderShipmentsScreen extends StatefulWidget {
  const TraderShipmentsScreen({super.key});

  @override
  State<TraderShipmentsScreen> createState() => _TraderShipmentsScreenState();
}

class _TraderShipmentsScreenState extends State<TraderShipmentsScreen> {
  String _filter = 'ALL';

  void _showTracking(BuildContext context, _Shipment shipment) {
    final steps = _stepsForStatus(shipment.status);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrackingSheet(shipment: shipment, completedSteps: steps),
    );
  }

  static int _stepsForStatus(String status) {
    switch (status) {
      case 'PENDING':    return 0;
      case 'CONFIRMED':  return 1;
      case 'IN TRANSIT': return 3;
      case 'CLEARED':    return 5;
      default:           return 0;
    }
  }

  static const _shipments = [
    _Shipment('SHP-0041', 'Nile Perch', '120 KG', 'Bor', 'Juba',
        'IN TRANSIT', 0.6, '14 May 2026', 'Nile Logistics'),
    _Shipment('SHP-0038', 'Tilapia (Fresh)', '45 KG', 'Panyagoor', 'Bor',
        'CONFIRMED', 0.0, '13 May 2026', 'B. Chol'),
    _Shipment('SHP-0035', 'Catfish', '200 KG', 'Twic East', 'Juba',
        'PENDING', 0.0, '12 May 2026', 'Juba Market'),
    _Shipment('SHP-0031', 'Nile Perch (Smoked)', '300 KG', 'Bor', 'Renk',
        'CLEARED', 1.0, '10 May 2026', 'Upper Nile Traders'),
    _Shipment('SHP-0027', 'Lungfish', '80 KG', 'Fangak', 'Malakal',
        'CLEARED', 1.0, '08 May 2026', 'Malakal Hub'),
  ];

  static const _filters = ['ALL', 'PENDING', 'IN TRANSIT', 'CONFIRMED', 'CLEARED'];

  List<_Shipment> get _filtered =>
      _filter == 'ALL' ? _shipments : _shipments.where((s) => s.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(
                  18, MediaQuery.of(context).padding.top + 16, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Shipment Ledger',
                                style: AppTextStyles.ui(18,
                                    weight: FontWeight.w800)),
                            Text('ACTIVE & HISTORICAL RECORDS',
                                style: AppTextStyles.label(10,
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('NEW SHIPMENT',
                            style: AppTextStyles.label(10,
                                color: Colors.white, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final active = _filter == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8, bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.secondaryLight
                                  : AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(f,
                                style: AppTextStyles.label(11,
                                    color: active
                                        ? AppColors.secondary
                                        : AppColors.onSurfaceVariant,
                                    weight: FontWeight.w700)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => GestureDetector(
                  onTap: () => _showTracking(context, _filtered[i]),
                  child: _ShipmentCard(shipment: _filtered[i]),
                ),
                childCount: _filtered.length,
              ),
            ),
          ),

          if (_filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 48, color: AppColors.onSurfaceFaint),
                    const SizedBox(height: 12),
                    Text('No shipments found',
                        style: AppTextStyles.ui(15,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Shipment {
  final String id;
  final String fish;
  final String quantity;
  final String origin;
  final String destination;
  final String status;
  final double progress;
  final String date;
  final String party;
  const _Shipment(this.id, this.fish, this.quantity, this.origin,
      this.destination, this.status, this.progress, this.date, this.party);
}

class _ShipmentCard extends StatelessWidget {
  final _Shipment shipment;
  const _ShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: _accentColor(shipment.status),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shipment.fish,
                              style: AppTextStyles.ui(15,
                                  weight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(shipment.quantity,
                              style: AppTextStyles.data(12,
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    StatusBadge.fromString(shipment.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(Icons.swap_horiz_rounded,
                        '${shipment.origin} → ${shipment.destination}'),
                    const SizedBox(width: 14),
                    _InfoChip(Icons.person_outline_rounded, shipment.party),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(Icons.calendar_today_outlined, shipment.date),
                    const Spacer(),
                    Text(shipment.id,
                        style: AppTextStyles.data(11,
                            color: AppColors.onSurfaceFaint)),
                  ],
                ),
                if (shipment.status == 'IN TRANSIT') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('TRANSIT PROGRESS',
                          style: AppTextStyles.label(9,
                              color: AppColors.onSurfaceFaint)),
                      const Spacer(),
                      Text('${(shipment.progress * 100).toInt()}%',
                          style: AppTextStyles.data(10,
                              color: AppColors.info, weight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: shipment.progress,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceHigh,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.info),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentColor(String status) {
    switch (status) {
      case 'IN TRANSIT':
        return AppColors.info;
      case 'CONFIRMED':
        return AppColors.success;
      case 'CLEARED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.secondary;
      default:
        return AppColors.surfaceHigh;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style:
                  AppTextStyles.ui(12, color: AppColors.onSurfaceVariant)),
        ],
      );
}

// ─── Tracking bottom sheet ────────────────────────────────────────────────────

class _TrackingSheet extends StatelessWidget {
  final _Shipment shipment;
  final int completedSteps;
  const _TrackingSheet(
      {required this.shipment, required this.completedSteps});

  static const _steps = [
    _Step('ORDER CONFIRMED',  'Buyer and seller agreement logged',     Icons.check_circle_outline_rounded),
    _Step('FISH LOADED',      'Cargo weighed and sealed for transport', Icons.inventory_2_outlined),
    _Step('IN TRANSIT',       'Vehicle en-route to destination',        Icons.local_shipping_outlined),
    _Step('BORDER CLEARANCE', 'Documents verified at checkpoint',       Icons.badge_outlined),
    _Step('DELIVERED',        'Goods received and receipt issued',      Icons.task_alt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TRACK SHIPMENT',
                        style: AppTextStyles.label(10,
                            color: AppColors.onSurfaceVariant)),
                    Text(shipment.fish,
                        style:
                            AppTextStyles.ui(17, weight: FontWeight.w800)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(shipment.id,
                    style: AppTextStyles.data(12,
                        color: AppColors.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(_steps.length, (i) {
            final done = i < completedSteps;
            final active = i == completedSteps && completedSteps < _steps.length;
            final last = i == _steps.length - 1;
            return _StepRow(
              step: _steps[i],
              done: done,
              active: active,
              showConnector: !last,
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Step {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Step(this.title, this.subtitle, this.icon);
}

class _StepRow extends StatelessWidget {
  final _Step step;
  final bool done;
  final bool active;
  final bool showConnector;
  const _StepRow(
      {required this.step,
      required this.done,
      required this.active,
      required this.showConnector});

  @override
  Widget build(BuildContext context) {
    final Color dotColor = done
        ? AppColors.success
        : active
            ? AppColors.secondary
            : AppColors.surfaceHigh;
    final Color lineColor =
        done ? AppColors.success : AppColors.surfaceHigh;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot + connector column
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: done || active
                      ? dotColor.withValues(alpha: 0.12)
                      : AppColors.surfaceHigh,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: dotColor,
                    width: active ? 2 : 1.5,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_rounded : step.icon,
                  size: 15,
                  color: done
                      ? AppColors.success
                      : active
                          ? AppColors.secondary
                          : AppColors.onSurfaceFaint,
                ),
              ),
              if (showConnector)
                Container(
                  width: 2,
                  height: 28,
                  color: lineColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title,
                  style: AppTextStyles.label(11,
                      color: done || active
                          ? AppColors.onSurface
                          : AppColors.onSurfaceFaint,
                      weight: done || active
                          ? FontWeight.w700
                          : FontWeight.w500)),
              const SizedBox(height: 2),
              Text(step.subtitle,
                  style: AppTextStyles.ui(11,
                      color: AppColors.onSurfaceFaint)),
            ],
          ),
        ),
      ],
    );
  }
}
