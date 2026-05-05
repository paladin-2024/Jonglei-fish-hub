import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_theme.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  bool _offline = false;
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.every((r) => r == ConnectivityResult.none);
      if (isOffline != _offline) {
        setState(() => _offline = isOffline);
        isOffline ? _anim.forward() : _anim.reverse();
      }
    });
    // Check immediately
    Connectivity().checkConnectivity().then((results) {
      final isOffline = results.every((r) => r == ConnectivityResult.none);
      if (isOffline) {
        setState(() => _offline = true);
        _anim.forward();
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizeTransition(
          sizeFactor: _anim,
          axisAlignment: -1,
          child: Container(
            width: double.infinity,
            color: AppColors.warning,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'NO CONNECTION — SHOWING CACHED DATA',
                  style: AppTextStyles.label(11,
                      color: Colors.white, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
