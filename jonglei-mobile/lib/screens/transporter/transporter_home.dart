import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/fish_encyclopedia_screen.dart';
import '../shared/market_map_screen.dart';
import '../shared/notification_screen.dart';
import '../shared/profile_screen.dart';
import 'available_jobs_screen.dart';

class TransporterHomeScreen extends StatefulWidget {
  const TransporterHomeScreen({super.key});

  @override
  State<TransporterHomeScreen> createState() => _TransporterHomeScreenState();
}

class _TransporterHomeScreenState extends State<TransporterHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _TransporterDashboard(),
      const MarketMapScreen(showRoutes: true),
      const AvailableJobsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.bgDeep,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'HOME'),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'ROUTES'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'JOBS'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'PROFILE'),
        ],
      ),
    );
  }
}

// ─── Dashboard tab ────────────────────────────────────────────────────────────
class _TransporterDashboard extends StatefulWidget {
  const _TransporterDashboard();

  @override
  State<_TransporterDashboard> createState() => _TransporterDashboardState();
}

class _TransporterDashboardState extends State<_TransporterDashboard> {
  int _activeJobs = 0;
  int _completedJobs = 0;
  bool _statsLoading = true;

  List<_Route> _routes = const [];
  bool _routesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchRoutes();
  }

  Future<void> _fetchStats() async {
    try {
      final api = context.read<AuthProvider>().api;
      final data =
          await api.get('/dashboard/transporter-stats/') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _activeJobs = (data['active_jobs'] as num?)?.toInt() ?? 0;
          _completedJobs = (data['completed_jobs'] as num?)?.toInt() ?? 0;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _fetchRoutes() async {
    try {
      final api = context.read<AuthProvider>().api;
      final raw = await api.get('/transport/jobs/?status=OPEN');
      final list = raw is List
          ? raw
          : (raw as Map<String, dynamic>)['results'] as List? ?? [];
      final routes = list.map((j) {
        final map = j as Map<String, dynamic>;
        final amount = map['payment_amount'];
        final pay = amount != null ? 'SSP $amount' : 'SSP —';
        final distRaw = map['distance_km'];
        final dist = distRaw != null ? '${distRaw}km' : '—';
        return _Route(
          map['origin_location']?.toString() ?? '—',
          map['destination_location']?.toString() ?? '—',
          dist,
          pay,
          map['status']?.toString() ?? 'OPEN',
        );
      }).toList();
      if (mounted) {
        setState(() {
          _routes = routes;
          _routesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _routesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: AmbientBackground(
        child: CustomScrollView(
          slivers: [
            // ── Cinema header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.bgDeep, AppColors.bgBase],
                  ),
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGlow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          user?.username.isNotEmpty == true
                              ? user!.username[0].toUpperCase()
                              : 'T',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('JONGLEI HUB',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 20,
                                color: AppColors.primary,
                                letterSpacing: -0.4,
                              )),
                          Text('Transport Network',
                              style: AppTextStyles.ui(12,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('WELCOME BACK,',
                            style: AppTextStyles.label(10,
                                color: AppColors.textMuted)),
                        const SizedBox(width: 6),
                        Text(user?.username ?? 'Transporter',
                            style: AppTextStyles.label(10,
                                color: AppColors.secondary,
                                weight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Stat chips row ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            label: 'ACTIVE JOBS',
                            value: _statsLoading ? '—' : '$_activeJobs',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatChip(
                            label: 'COMPLETED',
                            value: _statsLoading ? '—' : '$_completedJobs',
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatChip(
                            label: 'EARNINGS',
                            value: 'SSP 0',
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Available Routes ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text('Available Routes',
                              style: AppTextStyles.ui(15,
                                  weight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${_routes.length} OPEN',
                              style: AppTextStyles.label(9,
                                  color: AppColors.primary,
                                  weight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_routesLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      )
                    else if (_routes.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              const Icon(Icons.route_outlined,
                                  size: 40, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No routes available',
                                style: AppTextStyles.ui(13,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._routes.map((r) => _RouteTile(route: r)),

                    const SizedBox(height: 14),

                    // ── Encyclopedia card ───────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FishEncyclopediaScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryGlow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.menu_book_rounded,
                                  size: 20, color: AppColors.secondary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fish Encyclopedia',
                                      style: AppTextStyles.ui(14,
                                          weight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  Text('Know what you\'re transporting',
                                      style: AppTextStyles.ui(12,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 18, color: AppColors.textMuted),
                          ],
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
      ),
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.label(8,
                  color: AppColors.textMuted, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.0,
              )),
        ],
      ),
    );
  }
}

// ─── Route data model ─────────────────────────────────────────────────────────
class _Route {
  final String from;
  final String to;
  final String distance;
  final String pay;
  final String status;
  const _Route(this.from, this.to, this.distance, this.pay, this.status);
}

// ─── Route tile — animated arrow, gradient left border ───────────────────────
class _RouteTile extends StatelessWidget {
  final _Route route;
  const _RouteTile({required this.route});

  @override
  Widget build(BuildContext context) {
    final isAvailable = route.status == 'AVAILABLE' || route.status == 'OPEN';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Gradient left accent border
          Container(
            width: 4,
            height: 82,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isAvailable
                    ? [AppColors.primary, AppColors.secondary]
                    : [AppColors.textMuted, AppColors.textMuted],
              ),
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  // Fish icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.set_meal_rounded,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  // Origin → Destination with animated arrow
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(route.from,
                                style: AppTextStyles.ui(13,
                                    weight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: AppColors.primary),
                            ),
                            Flexible(
                              child: Text(route.to,
                                  style: AppTextStyles.ui(13,
                                      weight: FontWeight.w700,
                                      color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(route.distance,
                            style: AppTextStyles.ui(11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Pay + status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(route.pay,
                          style: AppTextStyles.data(13,
                              weight: FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? AppColors.successLight
                              : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isAvailable ? 'OPEN' : route.status,
                          style: AppTextStyles.label(8,
                              color: isAvailable
                                  ? AppColors.success
                                  : AppColors.warning,
                              weight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
