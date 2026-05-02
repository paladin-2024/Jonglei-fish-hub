import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.handshake_rounded,
      accentIcon: Icons.storefront_rounded,
      title: 'Connecting the\nMarket',
      body: 'Directly connect with traders and buyers across South Sudan.',
    ),
    _Slide(
      icon: Icons.route_rounded,
      accentIcon: Icons.location_on_rounded,
      title: 'Track Every\nShipment',
      body: 'Real-time visibility from origin to destination with integrated GPS tracking.',
    ),
    _Slide(
      icon: Icons.qr_code_2_rounded,
      accentIcon: Icons.shield_rounded,
      title: 'Secure\nVerification',
      body: 'Official clearance and digital receipts ensured by our secure ledger system.',
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _skip() => Navigator.pushReplacementNamed(context, '/login');

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: TextButton(
                  onPressed: _skip,
                  child: Text('SKIP',
                      style: AppTextStyles.label(12,
                          color: AppColors.onSurfaceVariant,
                          weight: FontWeight.w700)),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.secondary : AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            // CTA button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'GET STARTED' : 'NEXT',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final IconData accentIcon;
  final String title;
  final String body;
  const _Slide({
    required this.icon,
    required this.accentIcon,
    required this.title,
    required this.body,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Illustration card
          Center(
            child: SizedBox(
              width: 280,
              height: 260,
              child: Stack(
                children: [
                  // Main card
                  Positioned(
                    left: 12,
                    top: 12,
                    right: 40,
                    bottom: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(slide.icon,
                            size: 80, color: AppColors.primary),
                      ),
                    ),
                  ),
                  // Accent badge
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(slide.accentIcon,
                            size: 34, color: AppColors.secondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.display(30, color: AppColors.onSurface),
          ),

          const SizedBox(height: 14),

          // Body
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: AppTextStyles.ui(15,
                color: AppColors.onSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }
}
