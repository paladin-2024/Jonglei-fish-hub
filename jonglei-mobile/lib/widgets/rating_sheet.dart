import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Shows a bottom sheet for rating a counterpart after a trade.
/// [orderId] — the order to rate
/// [counterpartName] — display name of the person being rated
Future<void> showRatingSheet(
  BuildContext context, {
  required String orderId,
  required String counterpartName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RatingSheet(
      orderId: orderId,
      counterpartName: counterpartName,
    ),
  );
}

class _RatingSheet extends StatefulWidget {
  final String orderId;
  final String counterpartName;
  const _RatingSheet({required this.orderId, required this.counterpartName});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  String _error = '';

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      setState(() => _error = 'Please select a star rating.');
      return;
    }
    setState(() { _submitting = true; _error = ''; });
    try {
      final api = context.read<AuthProvider>().api;
      await api.post('/marketplace/orders/${widget.orderId}/rate/', {
        'rating': _stars,
        'comment': _commentCtrl.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to submit rating. Please try again.';
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Top accent
          Container(
            height: 3,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text('RATE YOUR TRADE',
              style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
          const SizedBox(height: 4),
          Text(widget.counterpartName,
              style: AppTextStyles.display(22)),
          const SizedBox(height: 20),

          // Star row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return GestureDetector(
                onTap: () => setState(() { _stars = i + 1; _error = ''; }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: filled ? AppColors.secondary : AppColors.surfaceHighest,
                  ),
                ),
              );
            }),
          ),

          if (_stars > 0) ...[
            const SizedBox(height: 6),
            Text(
              ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_stars],
              style: AppTextStyles.ui(13,
                  color: AppColors.secondary, weight: FontWeight.w700),
            ),
          ],

          const SizedBox(height: 20),

          // Comment field
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Add a comment (optional)…',
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

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('SUBMIT RATING',
                      style: AppTextStyles.ui(14,
                          weight: FontWeight.w800,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
