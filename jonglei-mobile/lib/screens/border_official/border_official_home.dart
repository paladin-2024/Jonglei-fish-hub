import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/profile_screen.dart';

// ─── BorderOfficialHomeScreen ─────────────────────────────────────────────────
class BorderOfficialHomeScreen extends StatefulWidget {
  const BorderOfficialHomeScreen({super.key});

  @override
  State<BorderOfficialHomeScreen> createState() =>
      _BorderOfficialHomeScreenState();
}

class _BorderOfficialHomeScreenState extends State<BorderOfficialHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _BorderOfficialDashboard(),
      const _ScanTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'HOME',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'SCAN',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard tab ────────────────────────────────────────────────────────────
class _BorderOfficialDashboard extends StatelessWidget {
  const _BorderOfficialDashboard();

  static const _logs = [
    _ClearanceLogData('SHP-0041', 'Nile Perch • 120kg', 'Bor → Juba', 'CLEARED'),
    _ClearanceLogData('SHP-0040', 'Tilapia • 45kg', 'Panyagoor → Bor', 'PENDING'),
    _ClearanceLogData('SHP-0039', 'Catfish • 200kg', 'Twic East → Juba', 'FLAGGED'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          // ── Surface header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(20, top + 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        user?.username.isNotEmpty == true
                            ? user!.username[0].toUpperCase()
                            : 'B',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CLEARANCE STATION',
                          style: AppTextStyles.label(
                            10,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          user?.username ?? 'Officer',
                          style: AppTextStyles.ui(
                            18,
                            weight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: AppColors.onSurfaceVariant,
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Stat cards + activity ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full-width primary stat
                  const LedgerStatCard(
                    label: 'Pending Clearances',
                    value: '12',
                    accentColor: AppColors.secondary,
                    icon: Icons.pending_actions_outlined,
                    wide: true,
                  ),
                  const SizedBox(height: 10),

                  // Two-column row
                  const Row(
                    children: [
                      Expanded(
                        child: LedgerStatCard(
                          label: 'Cleared Today',
                          value: '08',
                          accentColor: AppColors.success,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: LedgerStatCard(
                          label: 'Flagged',
                          value: '02',
                          accentColor: AppColors.danger,
                          icon: Icons.flag_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Section header
                  Text(
                    'Recent Activity',
                    style: AppTextStyles.ui(15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  // Clearance log list
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Column(
                      children: _logs.asMap().entries.map((e) {
                        final isLast = e.key == _logs.length - 1;
                        return _ClearanceLogTile(log: e.value, isLast: isLast);
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────
class _ClearanceLogData {
  final String shipmentId;
  final String description;
  final String route;
  final String status;
  const _ClearanceLogData(
      this.shipmentId, this.description, this.route, this.status);
}

// ─── Clearance log tile ───────────────────────────────────────────────────────
class _ClearanceLogTile extends StatelessWidget {
  final _ClearanceLogData log;
  final bool isLast;
  const _ClearanceLogTile({required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surfaceLow, width: 1),
              ),
      ),
      child: Row(
        children: [
          // Fish icon box
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.set_meal_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shipment ID in JetBrains Mono
                Text(
                  log.shipmentId,
                  style: AppTextStyles.data(
                    13,
                    weight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log.description,
                  style: AppTextStyles.ui(
                    12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      size: 13,
                      color: AppColors.onSurfaceFaint,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      log.route,
                      style: AppTextStyles.ui(
                        11,
                        color: AppColors.onSurfaceFaint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge.fromString(log.status),
        ],
      ),
    );
  }
}

// ─── Scan tab ─────────────────────────────────────────────────────────────────
class _ScanTab extends StatefulWidget {
  const _ScanTab();

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lineCtrl;
  late final Animation<double> _lineAnim;

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _lineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    super.dispose();
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Enter Shipment ID',
          style: AppTextStyles.ui(16, weight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: AppTextStyles.data(14),
            decoration: const InputDecoration(
              hintText: 'e.g. SHP-0041',
              prefixIcon: Icon(
                Icons.tag_rounded,
                color: AppColors.onSurfaceFaint,
                size: 18,
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a shipment ID' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: AppTextStyles.ui(
                13,
                weight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Looking up ${controller.text.trim()}...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(
              'CONFIRM',
              style: AppTextStyles.ui(
                13,
                weight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const viewfinderSize = 260.0;

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'SCAN QR CODE',
                    style: AppTextStyles.label(
                      12,
                      color: Colors.white70,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.flash_on_outlined,
                        color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── QR viewfinder ─────────────────────────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                // Dimming overlay with transparent center cutout
                SizedBox(
                  width: viewfinderSize + 80,
                  height: viewfinderSize + 80,
                  child: CustomPaint(
                    painter: _DimOverlayPainter(viewfinderSize),
                  ),
                ),

                // White-border square
                Container(
                  width: viewfinderSize,
                  height: viewfinderSize,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // Animated corner brackets
                SizedBox(
                  width: viewfinderSize,
                  height: viewfinderSize,
                  child: CustomPaint(
                    painter: _CornerBracketsPainter(
                      color: AppColors.secondary,
                    ),
                  ),
                ),

                // Animated scan line
                AnimatedBuilder(
                  animation: _lineAnim,
                  builder: (context, child) {
                    final topOffset =
                        _lineAnim.value * (viewfinderSize - 4);
                    return SizedBox(
                      width: viewfinderSize,
                      height: viewfinderSize,
                      child: Stack(
                        children: [
                          Positioned(
                            top: topOffset,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.secondary
                                        .withValues(alpha: 0.9),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const Spacer(),

            // ── Labels and buttons ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
              child: Column(
                children: [
                  Text(
                    'SCAN SHIPMENT QR',
                    style: AppTextStyles.ui(
                      18,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Align code within the frame',
                    style: AppTextStyles.ui(
                      13,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Manual entry button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _showManualEntry,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                            color: Colors.white54, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'ENTER CODE MANUALLY',
                        style: AppTextStyles.ui(
                          13,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Scan Now button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Camera scanning — coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'SCAN NOW',
                        style: AppTextStyles.ui(
                          14,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Corner brackets painter ─────────────────────────────────────────────────
class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  const _CornerBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const len = 28.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, 0)
        ..lineTo(len, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, len),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height)
        ..lineTo(len, size.height),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter old) => old.color != color;
}

// ─── Dim overlay painter ─────────────────────────────────────────────────────
class _DimOverlayPainter extends CustomPainter {
  final double clearSize;
  const _DimOverlayPainter(this.clearSize);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: center, width: clearSize, height: clearSize),
          const Radius.circular(4),
        ),
      );

    final combined =
        Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(
        combined, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_DimOverlayPainter old) => old.clearSize != clearSize;
}
