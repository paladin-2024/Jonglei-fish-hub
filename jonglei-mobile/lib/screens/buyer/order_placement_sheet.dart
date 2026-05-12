import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'payment_sheet.dart';

class OrderPlacementSheet extends StatefulWidget {
  final String listingId;
  final String species;
  final double maxQty;
  final double pricePerUnit;
  final String unit;
  final String seller;
  final String location;

  const OrderPlacementSheet({
    super.key,
    required this.listingId,
    required this.species,
    required this.maxQty,
    required this.pricePerUnit,
    required this.unit,
    required this.seller,
    required this.location,
  });

  @override
  State<OrderPlacementSheet> createState() => _OrderPlacementSheetState();
}

class _OrderPlacementSheetState extends State<OrderPlacementSheet> {
  late double _qty;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;
  String _error = '';
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _qty = (widget.maxQty * 0.1).clamp(1, widget.maxQty);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _total => _qty * widget.pricePerUnit;

  Future<void> _placeOrder() async {
    setState(() { _submitting = true; _error = ''; });
    try {
      final result = await context.read<AuthProvider>().api.post(
        '/marketplace/orders/',
        {
          'listing':     widget.listingId,
          'quantity_kg': _qty,
          'note':        _noteCtrl.text.trim(),
        },
        requiresAuth: true,
      ) as Map<String, dynamic>;

      final orderId = result['id']?.toString() ?? '';
      if (!mounted) return;
      setState(() { _success = true; _submitting = false; });
      // Brief success flash, then open payment sheet
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pop(context, true);
      // Show payment sheet
      await showPaymentSheet(
        context,
        orderId: orderId,
        amount: _total,
        species: widget.species,
        userPhone: context.read<AuthProvider>().currentUser?.phoneNumber ?? '',
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('ApiException', '').replaceFirst(RegExp(r'^\(\d+\):\s*'), '');
      setState(() { _error = msg.isNotEmpty ? msg : 'Failed to place order. Please try again.'; _submitting = false; });
    }
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLACE ORDER',
                        style: AppTextStyles.label(10, color: AppColors.onSurfaceVariant)),
                    Text(widget.species, style: AppTextStyles.display(20)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(widget.seller,
                      style: AppTextStyles.ui(12, color: AppColors.onSurfaceVariant, weight: FontWeight.w600)),
                  Text(widget.location,
                      style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Text('QUANTITY', style: AppTextStyles.label(10, color: AppColors.onSurfaceVariant)),
              const Spacer(),
              Text(
                '${_qty.toStringAsFixed(0)} ${widget.unit}',
                style: AppTextStyles.data(16, weight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceHigh,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: _qty,
              min: 1,
              max: widget.maxQty,
              divisions: widget.maxQty.toInt().clamp(1, 100),
              onChanged: _success ? null : (v) => setState(() => _qty = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 ${widget.unit}', style: AppTextStyles.label(9, color: AppColors.onSurfaceFaint)),
              Text('${widget.maxQty.toStringAsFixed(0)} ${widget.unit} available',
                  style: AppTextStyles.label(9, color: AppColors.onSurfaceFaint)),
            ],
          ),

          const SizedBox(height: 20),

          Text('NOTE (optional)', style: AppTextStyles.label(10, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            style: AppTextStyles.ui(13),
            maxLines: 2,
            enabled: !_success,
            decoration: InputDecoration(
              hintText: 'Delivery preference, special requests…',
              hintStyle: AppTextStyles.ui(13, color: AppColors.onSurfaceFaint),
            ),
          ),

          const SizedBox(height: 20),

          // Total preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _success ? AppColors.successLight : AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL COST',
                        style: AppTextStyles.label(9,
                            color: _success ? AppColors.success : AppColors.secondary)),
                    Text(
                      _success ? 'Order placed!' : 'SSP ${_total.toStringAsFixed(0)}',
                      style: AppTextStyles.data(22,
                          weight: FontWeight.w700,
                          color: _success ? AppColors.success : AppColors.secondary),
                    ),
                  ],
                ),
                const Spacer(),
                if (_success)
                  const Icon(Icons.check_circle_rounded,
                      size: 28, color: AppColors.success)
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${_qty.toStringAsFixed(0)} ${widget.unit}',
                          style: AppTextStyles.data(13,
                              color: AppColors.secondary, weight: FontWeight.w700)),
                      Text('@ SSP ${widget.pricePerUnit.toStringAsFixed(0)}',
                          style: AppTextStyles.label(10, color: AppColors.secondary)),
                    ],
                  ),
              ],
            ),
          ),

          // Inline error
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 15, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error,
                        style: AppTextStyles.ui(12, color: AppColors.danger, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (_submitting || _success) ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _success ? AppColors.success : AppColors.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_success ? Icons.check_rounded : Icons.shopping_bag_outlined, size: 18),
              label: Text(
                _success ? 'ORDER PLACED' : 'CONFIRM ORDER',
                style: AppTextStyles.ui(14, weight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
