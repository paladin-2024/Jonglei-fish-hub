import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TraderShipmentsScreen extends StatefulWidget {
  const TraderShipmentsScreen({super.key});

  @override
  State<TraderShipmentsScreen> createState() => _TraderShipmentsScreenState();
}

class _TraderShipmentsScreenState extends State<TraderShipmentsScreen> {
  String _filter = 'ALL';

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
                (_, i) => _ShipmentCard(shipment: _filtered[i]),
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
