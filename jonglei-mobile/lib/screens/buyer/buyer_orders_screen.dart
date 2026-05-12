import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dispute_sheet.dart';
import '../../widgets/rating_sheet.dart';
import 'buyer_tracking_screen.dart';
import 'payment_sheet.dart';

class _Order {
  final String id;
  final String species;
  final double qty;
  final String unit;
  final double total;
  final String status;
  final String date;
  final String seller;

  const _Order(this.id, this.species, this.qty, this.unit, this.total,
      this.status, this.date, this.seller);
}

const _sampleOrders = [
  _Order('ORD-0091', 'Nile Perch',         120, 'KG', 294000, 'CONFIRMED',  '02 May 2026', 'B. Deng'),
  _Order('ORD-0090', 'Tilapia (Fresh)',      45, 'KG', 81000,  'IN_TRANSIT', '02 May 2026', 'P. Chol'),
  _Order('ORD-0089', 'Catfish',             200, 'KG', 420000, 'PENDING',    '01 May 2026', 'T. East Traders'),
  _Order('ORD-0083', 'Tilapia (Fresh)',      30, 'KG', 54000,  'CLEARED',    '25 Apr 2026', 'Panyagoor Co-op'),
];

const _statusStyles = {
  'PENDING':    _S(Color(0xFFFFDCBB), Color(0xFFB45309), 'PENDING'),
  'CONFIRMED':  _S(Color(0xFFD6EFE1), Color(0xFF1A6B3C), 'CONFIRMED'),
  'IN_TRANSIT': _S(Color(0xFFD6EAF8), Color(0xFF1E5C8A), 'IN TRANSIT'),
  'CLEARED':    _S(Color(0xFFD6EFE1), Color(0xFF005440), 'CLEARED'),
  'CANCELLED':  _S(Color(0xFFFFE4E4), Color(0xFFB91C1C), 'CANCELLED'),
};

class _S {
  final Color bg;
  final Color fg;
  final String label;
  const _S(this.bg, this.fg, this.label);
}

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  String _filter = 'ALL';
  List<_Order> _orders = [];
  bool _loading = true;

  static const _filters = ['ALL', 'PENDING', 'CONFIRMED', 'IN TRANSIT', 'CLEARED'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthProvider>().api;
      final raw = await api.getList('/marketplace/orders/my-orders/');
      if (raw.isNotEmpty && mounted) {
        setState(() {
          _orders = raw.map((j) {
            final listing = (j['listing_detail'] as Map?) ?? {};
            final seller  = (listing['seller_detail'] as Map?) ?? {};
            return _Order(
              j['id']?.toString().toUpperCase() ?? '',
              listing['species'] ?? '—',
              double.tryParse(j['quantity_kg']?.toString() ?? '') ?? 0,
              listing['unit'] ?? 'KG',
              double.tryParse(j['total_price']?.toString() ?? '') ?? 0,
              j['status'] ?? 'PENDING',
              j['created_at'] != null
                  ? DateTime.parse(j['created_at'] as String)
                      .toLocal()
                      .toString()
                      .substring(0, 10)
                  : '—',
              seller['username'] ?? '—',
            );
          }).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<_Order> get _filtered {
    if (_filter == 'ALL') return _orders;
    final key = _filter.replaceAll(' ', '_');
    return _orders
        .where((o) => o.status == key || o.status == _filter)
        .toList();
  }

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
                  Text('My Orders',
                      style: AppTextStyles.ui(18, weight: FontWeight.w800)),
                  Text('PURCHASE HISTORY',
                      style: AppTextStyles.label(10,
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final active = f == _filter;
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

          if (_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
              ),
            )
          else if (_filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: AppColors.onSurfaceFaint),
                    const SizedBox(height: 12),
                    Text('No orders found',
                        style: AppTextStyles.ui(15,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _OrderCard(order: _filtered[i], onRefresh: _load),
                  childCount: _filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final _Order order;
  final VoidCallback onRefresh;
  const _OrderCard({required this.order, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final style = _statusStyles[order.status] ??
        const _S(Color(0xFFE9E8E4), Color(0xFF3F4944), '—');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: style.fg,
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
                          Text(order.species,
                              style: AppTextStyles.ui(15,
                                  weight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(order.seller,
                              style: AppTextStyles.ui(12,
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: style.bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(style.label,
                          style: AppTextStyles.label(10,
                              color: style.fg,
                              weight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(Icons.scale_outlined,
                        '${order.qty.toStringAsFixed(0)} ${order.unit}'),
                    const SizedBox(width: 14),
                    _InfoChip(Icons.calendar_today_outlined, order.date),
                    const Spacer(),
                    Text(
                      'SSP ${order.total.toStringAsFixed(0)}',
                      style: AppTextStyles.data(14,
                          weight: FontWeight.w700,
                          color: AppColors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(order.id,
                    style: AppTextStyles.data(10,
                        color: AppColors.onSurfaceFaint)),

                // Action buttons
                if (order.status == 'PENDING') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final paid = await showPaymentSheet(
                          context,
                          orderId: order.id,
                          amount: order.total,
                          species: order.species,
                          userPhone: context.read<AuthProvider>().currentUser?.phoneNumber ?? '',
                        );
                        if (paid == true && context.mounted) onRefresh();
                      },
                      icon: const Icon(Icons.payment_outlined, size: 16),
                      label: Text('Pay with MTN MoMo',
                          style: AppTextStyles.ui(13, weight: FontWeight.w700, color: const Color(0xFF1A1200))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        foregroundColor: const Color(0xFF1A1200),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),
                ] else if (order.status == 'CONFIRMED' || order.status == 'IN_TRANSIT') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BuyerTrackingScreen(
                                orderId: order.id,
                                species: order.species,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.location_on_outlined, size: 14),
                          label: Text('Track',
                              style: AppTextStyles.ui(12,
                                  weight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => showDisputeSheet(
                            context,
                            orderId: order.id,
                            orderRef: order.id,
                          ),
                          icon: const Icon(Icons.flag_outlined, size: 14),
                          label: Text('Dispute',
                              style: AppTextStyles.ui(12,
                                  weight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: BorderSide(
                                color: AppColors.danger.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (order.status == 'CLEARED') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => showRatingSheet(
                        context,
                        orderId: order.id,
                        counterpartName: order.seller,
                      ),
                      icon: const Icon(Icons.star_outline_rounded, size: 14),
                      label: Text('Rate ${order.seller}',
                          style: AppTextStyles.ui(12,
                              weight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: BorderSide(
                            color: AppColors.secondary.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
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
              style: AppTextStyles.ui(12,
                  color: AppColors.onSurfaceVariant)),
        ],
      );
}
