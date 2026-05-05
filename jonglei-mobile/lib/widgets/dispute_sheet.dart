import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

const _reasons = [
  _Reason('Quality Issue',    'Fish does not match the description or quality stated.', Icons.warning_amber_rounded),
  _Reason('Non-Delivery',     'Order was confirmed but fish was never delivered.',       Icons.local_shipping_outlined),
  _Reason('Price Dispute',    'Charged amount differs from the agreed listing price.',  Icons.payments_outlined),
  _Reason('Fraud Concern',    'Suspected fraudulent transaction or fake listing.',       Icons.gpp_bad_outlined),
  _Reason('Wrong Species',    'Fish delivered is a different species to the listing.',  Icons.set_meal_outlined),
  _Reason('Other',            'Describe your issue in the field below.',               Icons.more_horiz_rounded),
];

class _Reason {
  final String label;
  final String hint;
  final IconData icon;
  const _Reason(this.label, this.hint, this.icon);
}

/// Show a dispute filing bottom sheet for the given order.
/// Returns `true` if submitted successfully, otherwise `null`.
Future<bool?> showDisputeSheet(
  BuildContext context, {
  required String orderId,
  required String orderRef,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DisputeSheet(orderId: orderId, orderRef: orderRef),
  );
}

class _DisputeSheet extends StatefulWidget {
  final String orderId;
  final String orderRef;
  const _DisputeSheet({required this.orderId, required this.orderRef});

  @override
  State<_DisputeSheet> createState() => _DisputeSheetState();
}

class _DisputeSheetState extends State<_DisputeSheet> {
  int _selectedReason = -1;
  final _descCtrl = TextEditingController();
  bool _submitting = false;
  String _error = '';

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason < 0) {
      setState(() => _error = 'Please select a reason.');
      return;
    }
    setState(() { _submitting = true; _error = ''; });
    try {
      final api = context.read<AuthProvider>().api;
      await api.post('/marketplace/orders/${widget.orderId}/dispute/', {
        'reason':      _reasons[_selectedReason].label,
        'description': _descCtrl.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to submit dispute. Please try again.';
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.only(bottom: bottom + 24),
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Danger accent
            Container(height: 3, color: AppColors.danger),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FILE A DISPUTE',
                      style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
                  const SizedBox(height: 4),
                  Text('Order ${widget.orderRef}',
                      style: AppTextStyles.display(22)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 15, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Disputes are reviewed by the Jonglei Fish Hub team within 48 hours.',
                            style: AppTextStyles.ui(12, color: AppColors.danger, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text('REASON FOR DISPUTE',
                      style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
                  const SizedBox(height: 10),

                  // Reason grid
                  ...List.generate(_reasons.length, (i) {
                    final r = _reasons[i];
                    final selected = _selectedReason == i;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedReason = i;
                        _error = '';
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.dangerLight
                              : AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: selected
                              ? Border.all(color: AppColors.danger, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(r.icon,
                                size: 18,
                                color: selected
                                    ? AppColors.danger
                                    : AppColors.onSurfaceVariant),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.label,
                                      style: AppTextStyles.ui(13,
                                          weight: FontWeight.w700,
                                          color: selected
                                              ? AppColors.danger
                                              : AppColors.onSurface)),
                                  Text(r.hint,
                                      style: AppTextStyles.ui(11,
                                          color: AppColors.onSurfaceFaint,
                                          height: 1.4)),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle_rounded,
                                  size: 18, color: AppColors.danger),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  Text('ADDITIONAL DETAILS (optional)',
                      style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Describe the issue in detail…',
                      alignLabelWithHint: true,
                    ),
                    style: AppTextStyles.ui(14),
                  ),

                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_error,
                        style: AppTextStyles.ui(12, color: AppColors.danger)),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg)),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('SUBMIT DISPUTE',
                              style: AppTextStyles.ui(14,
                                  weight: FontWeight.w800,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
