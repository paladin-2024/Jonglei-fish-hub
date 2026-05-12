import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

const _kMtnYellow = Color(0xFFFFCC00);
const _kMtnYellowDark = Color(0xFFE6B800);
const _kMtnBg = Color(0xFFFFFDE7);

enum _PayState { idle, requesting, polling, success, failed, timeout }

class PaymentSheet extends StatefulWidget {
  final String orderId;
  final double amount;
  final String species;
  final String userPhone;

  const PaymentSheet({
    super.key,
    required this.orderId,
    required this.amount,
    required this.species,
    required this.userPhone,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet>
    with TickerProviderStateMixin {
  late final TextEditingController _phoneCtrl;
  _PayState _state = _PayState.idle;
  String _paymentId = '';
  String _error = '';
  int _seconds = 0;
  Timer? _pollTimer;
  Timer? _tickTimer;

  late final AnimationController _successAnim;
  late final AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.userPhone);
    _successAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim   = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    _phoneCtrl.dispose();
    _successAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() { _state = _PayState.requesting; _error = ''; });

    try {
      final api = context.read<AuthProvider>().api;
      final result = await api.post('/payments/initiate/', {
        'order_id':     widget.orderId,
        'phone_number': phone,
      }, requiresAuth: true) as Map<String, dynamic>;

      _paymentId = result['id']?.toString() ?? '';
      if (_paymentId.isEmpty) throw Exception('No payment ID returned');

      setState(() { _state = _PayState.polling; _seconds = 0; });
      _startPolling();
    } catch (e) {
      final msg = e.toString().replaceAll(RegExp(r'ApiException\(\d+\):\s*'), '');
      setState(() { _state = _PayState.failed; _error = msg.isNotEmpty ? msg : 'Payment request failed.'; });
    }
  }

  void _startPolling() {
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= 90) {
        _pollTimer?.cancel();
        _tickTimer?.cancel();
        if (mounted) setState(() => _state = _PayState.timeout);
      }
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _paymentId.isEmpty) return;
      try {
        final api = context.read<AuthProvider>().api;
        final data = await api.get('/payments/$_paymentId/status/') as Map<String, dynamic>;
        final s = data['status']?.toString() ?? 'PENDING';
        if (s == 'SUCCESSFUL') {
          _pollTimer?.cancel();
          _tickTimer?.cancel();
          if (mounted) {
            setState(() => _state = _PayState.success);
            _successAnim.forward();
          }
        } else if (s == 'FAILED') {
          _pollTimer?.cancel();
          _tickTimer?.cancel();
          if (mounted) setState(() { _state = _PayState.failed; _error = 'Payment was declined by MTN.'; });
        }
      } catch (_) {}
    });
  }

  void _retry() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    _successAnim.reset();
    setState(() { _state = _PayState.idle; _error = ''; _seconds = 0; _paymentId = ''; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _kMtnBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kMtnYellow, width: 1.5),
                ),
                child: const Center(
                  child: Text('MTN', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w900,
                    color: _kMtnYellowDark, letterSpacing: 0.5,
                  )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MTN MoMo Payment',
                        style: AppTextStyles.ui(16, weight: FontWeight.w800)),
                    Text(widget.species,
                        style: AppTextStyles.ui(12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('SSP ${widget.amount.toStringAsFixed(0)}',
                      style: AppTextStyles.data(18, weight: FontWeight.w800, color: AppColors.primary)),
                  Text('TOTAL', style: AppTextStyles.label(9, color: AppColors.onSurfaceFaint)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_state == _PayState.idle || _state == _PayState.requesting) ...[
            _buildPhoneField(),
            const SizedBox(height: 16),
            _buildMoMoInfo(),
            const SizedBox(height: 20),
            _buildPayButton(),
          ] else if (_state == _PayState.polling) ...[
            _buildPollingView(),
          ] else if (_state == _PayState.success) ...[
            _buildSuccessView(),
          ] else if (_state == _PayState.failed || _state == _PayState.timeout) ...[
            _buildFailedView(),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MTN MoMo Phone Number',
            style: AppTextStyles.label(10, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+\d]'))],
          style: AppTextStyles.data(15, weight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_android_outlined, size: 18, color: AppColors.onSurfaceVariant),
            hintText: '+256 7XX XXX XXX',
            hintStyle: AppTextStyles.ui(14, color: AppColors.onSurfaceFaint),
          ),
        ),
      ],
    );
  }

  Widget _buildMoMoInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kMtnBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _kMtnYellow.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: _kMtnYellowDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You will receive a prompt on your MTN MoMo phone to approve this payment.',
              style: AppTextStyles.ui(12, color: _kMtnYellowDark, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    final busy = _state == _PayState.requesting;
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: busy ? null : _pay,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kMtnYellow,
          foregroundColor: const Color(0xFF1A1200),
          disabledBackgroundColor: _kMtnYellow.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        child: busy
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1A1200)))
            : Text('Pay with MTN MoMo',
                style: AppTextStyles.ui(15, weight: FontWeight.w800,
                    color: const Color(0xFF1A1200), letterSpacing: 0.3)),
      ),
    );
  }

  Widget _buildPollingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kMtnYellow.withValues(alpha: 0.15 + _pulseAnim.value * 0.2),
                border: Border.all(color: _kMtnYellow, width: 2),
              ),
              child: const Center(
                child: Text('MTN', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w900,
                  color: _kMtnYellowDark,
                )),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Waiting for MoMo confirmation…',
              style: AppTextStyles.ui(14, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Check your phone and approve the payment',
              style: AppTextStyles.ui(12, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('$_seconds s', style: AppTextStyles.data(13, color: AppColors.onSurfaceFaint)),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut),
            child: Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successLight,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          Text('Payment Confirmed!',
              style: AppTextStyles.ui(18, weight: FontWeight.w800, color: AppColors.success)),
          const SizedBox(height: 6),
          Text('SSP ${widget.amount.toStringAsFixed(0)} received via MTN MoMo',
              style: AppTextStyles.ui(13, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: Text('Done', style: AppTextStyles.ui(14, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedView() {
    final isTimeout = _state == _PayState.timeout;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.dangerLight,
            ),
            child: Icon(
              isTimeout ? Icons.timer_off_outlined : Icons.close_rounded,
              color: AppColors.danger, size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(isTimeout ? 'Payment Timed Out' : 'Payment Failed',
              style: AppTextStyles.ui(17, weight: FontWeight.w800, color: AppColors.danger)),
          const SizedBox(height: 6),
          Text(
            isTimeout
                ? 'No response in 90 seconds. Please try again.'
                : (_error.isNotEmpty ? _error : 'Something went wrong.'),
            style: AppTextStyles.ui(12, color: AppColors.onSurfaceVariant, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text('Cancel', style: AppTextStyles.ui(13, weight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kMtnYellow,
                    foregroundColor: const Color(0xFF1A1200),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text('Try Again', style: AppTextStyles.ui(13, weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<bool?> showPaymentSheet(
  BuildContext context, {
  required String orderId,
  required double amount,
  required String species,
  required String userPhone,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => PaymentSheet(
      orderId: orderId,
      amount: amount,
      species: species,
      userPhone: userPhone,
    ),
  );
}
