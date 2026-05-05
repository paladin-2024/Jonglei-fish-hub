import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

// ─── Stage definitions ────────────────────────────────────────────────────────
enum _Stage {
  loaded('LOADED', 'Cargo Loaded', Icons.inventory_2_rounded),
  departed('DEPARTED', 'Departed Origin', Icons.departure_board_rounded),
  enRoute('EN_ROUTE', 'En Route', Icons.local_shipping_rounded),
  atCheckpoint('AT_CHECKPOINT', 'At Checkpoint', Icons.where_to_vote_rounded),
  delivered('DELIVERED', 'Delivered', Icons.check_circle_rounded);

  final String key;
  final String label;
  final IconData icon;
  const _Stage(this.key, this.label, this.icon);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ActiveJobScreen extends StatefulWidget {
  final String jobId;
  final String shipmentId;
  final String fromLocation;
  final String toLocation;
  final String cargoType;

  const ActiveJobScreen({
    super.key,
    required this.jobId,
    required this.shipmentId,
    required this.fromLocation,
    required this.toLocation,
    required this.cargoType,
  });

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  String _currentStage = 'LOADED';
  Map<String, dynamic>? _shipmentData;
  bool _loading = true;
  bool _posting = false;

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
      final data = await api.get('/transport/shipments/${widget.shipmentId}/') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _shipmentData = data;
          _currentStage = (data['current_stage'] ??
                  data['stage'] ??
                  data['status'] ??
                  'LOADED')
              .toString()
              .toUpperCase();
        });
      }
    } catch (_) {
      // Use defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _postEvent(String stage, {String note = ''}) async {
    setState(() => _posting = true);
    try {
      final api = context.read<AuthProvider>().api;
      await api.post(
        '/transport/shipments/${widget.shipmentId}/add_event/',
        {'stage': stage, 'note': note},
      );
      if (mounted) {
        setState(() => _currentStage = stage);
        if (stage == 'DELIVERED') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shipment marked as delivered!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated to $stage'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  int get _currentStageIndex {
    final idx = _Stage.values.indexWhere((s) => s.key == _currentStage);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + 8, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        color: AppColors.onSurface,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.fromLocation} → ${widget.toLocation}',
                              style: AppTextStyles.ui(16,
                                  weight: FontWeight.w800),
                            ),
                            Text(widget.cargoType,
                                style: AppTextStyles.ui(12,
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: AppTextStyles.label(10,
                              color: AppColors.primary,
                              weight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Shipment info card ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadius.card)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SHIPMENT DETAILS',
                              style: AppTextStyles.label(10,
                                  color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.tag_rounded,
                            label: 'Job ID',
                            value: widget.jobId,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.receipt_long_rounded,
                            label: 'Shipment ID',
                            value: widget.shipmentId,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.set_meal_rounded,
                            label: 'Cargo',
                            value: widget.cargoType,
                          ),
                          if (_shipmentData != null) ...[
                            if (_shipmentData!['weight_kg'] != null) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.scale_outlined,
                                label: 'Weight',
                                value:
                                    '${_shipmentData!['weight_kg']} kg',
                              ),
                            ],
                            if (_shipmentData!['order_id'] != null ||
                                _shipmentData!['order'] != null) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.shopping_bag_outlined,
                                label: 'Order ID',
                                value: (_shipmentData!['order_id'] ??
                                        _shipmentData!['order'])
                                    .toString(),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Progress tracker ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadius.card)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('JOURNEY PROGRESS',
                              style: AppTextStyles.label(10,
                                  color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 16),
                          if (_loading)
                            const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            )
                          else
                            _ProgressTracker(
                              stages: _Stage.values,
                              currentIndex: _currentStageIndex,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Action buttons ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Update Location button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _posting
                          ? null
                          : () => _postEvent('EN_ROUTE',
                              note: 'Location updated'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)),
                      ),
                      icon: _posting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary))
                          : const Icon(Icons.location_on_rounded, size: 18),
                      label: Text(
                        'UPDATE LOCATION',
                        style: AppTextStyles.ui(13,
                            weight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mark Delivered button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _posting
                          ? null
                          : () => _confirmDelivery(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        disabledBackgroundColor: AppColors.surfaceHighest,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)),
                        elevation: 0,
                      ),
                      icon: _posting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_rounded,
                              size: 20, color: Colors.white),
                      label: Text(
                        'MARK DELIVERED',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelivery() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Confirm Delivery',
            style: AppTextStyles.ui(16, weight: FontWeight.w700)),
        content: Text(
          'Mark this shipment as delivered to ${widget.toLocation}?',
          style: AppTextStyles.ui(13, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL',
                style: AppTextStyles.ui(13,
                    weight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _postEvent('DELIVERED');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text('CONFIRM',
                style: AppTextStyles.ui(13,
                    weight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Progress tracker widget ──────────────────────────────────────────────────
class _ProgressTracker extends StatelessWidget {
  final List<_Stage> stages;
  final int currentIndex;

  const _ProgressTracker({
    required this.stages,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: stages.asMap().entries.map((entry) {
        final i = entry.key;
        final stage = entry.value;
        final isDone = i < currentIndex;
        final isActive = i == currentIndex;
        final isFuture = i > currentIndex;
        final isLast = i == stages.length - 1;

        Color lineColor;
        Color iconColor;
        Color bgColor;

        if (isDone) {
          bgColor = AppColors.successLight;
          iconColor = AppColors.success;
          lineColor = AppColors.success;
        } else if (isActive) {
          bgColor = AppColors.primary.withValues(alpha: 0.1);
          iconColor = AppColors.primary;
          lineColor = AppColors.surfaceHighest;
        } else {
          bgColor = AppColors.surfaceHigh;
          iconColor = AppColors.onSurfaceFaint;
          lineColor = AppColors.surfaceHighest;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline column
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(stage.icon, size: 16, color: iconColor),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: lineColor,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(bottom: isLast ? 0 : 24, top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.label,
                      style: AppTextStyles.ui(
                        13,
                        weight: isActive
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isActive
                            ? AppColors.primary
                            : isFuture
                                ? AppColors.onSurfaceFaint
                                : AppColors.success,
                      ),
                    ),
                    if (isActive)
                      Text(
                        'Current stage',
                        style: AppTextStyles.label(10,
                            color: AppColors.primary),
                      )
                    else if (isDone)
                      Text(
                        'Completed',
                        style: AppTextStyles.label(10,
                            color: AppColors.success),
                      ),
                  ],
                ),
              ),
            ),
            if (isDone)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: const Icon(Icons.check_rounded,
                    size: 16, color: AppColors.success),
              ),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('NOW',
                      style: AppTextStyles.label(9,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceFaint),
        const SizedBox(width: 8),
        Text('$label:',
            style:
                AppTextStyles.ui(12, color: AppColors.onSurfaceVariant)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.data(12, weight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
