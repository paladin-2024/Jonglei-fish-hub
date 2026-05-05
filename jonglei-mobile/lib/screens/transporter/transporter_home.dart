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
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
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
      final list = raw is List ? raw : (raw as Map<String, dynamic>)['results'] as List? ?? [];
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

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 16, 20, 16),
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
                            : 'T',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WELCOME BACK,',
                            style: AppTextStyles.label(10,
                                color: AppColors.onSurfaceVariant)),
                        Text(user?.username ?? 'Transporter',
                            style: AppTextStyles.ui(18,
                                weight: FontWeight.w800,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    color: AppColors.onSurfaceVariant,
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
                  LedgerStatCard(
                    label: 'Active Jobs',
                    value: _statsLoading ? '…' : '$_activeJobs',
                    accentColor: AppColors.primary,
                    icon: Icons.route_rounded,
                    wide: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LedgerStatCard(
                          label: 'Completed',
                          value: _statsLoading ? '…' : '$_completedJobs',
                          accentColor: AppColors.success,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LedgerStatCard(
                          label: 'Earnings',
                          value: 'SSP 0',
                          accentColor: AppColors.secondary,
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: Text('Available Routes',
                            style: AppTextStyles.ui(15, weight: FontWeight.w700)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${_routes.length} ROUTES',
                            style: AppTextStyles.label(9,
                                color: AppColors.primary,
                                weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_routesLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_routes.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No routes available',
                          style: AppTextStyles.ui(13,
                              color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ..._routes.map((r) => _RouteTile(route: r)),

                  const SizedBox(height: 14),

                  // Encyclopedia quick-link
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FishEncyclopediaScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.menu_book_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fish Encyclopedia',
                                    style: AppTextStyles.ui(14,
                                        weight: FontWeight.w700)),
                                Text('Know what you\'re transporting',
                                    style: AppTextStyles.ui(12,
                                        color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.onSurfaceFaint),
                        ],
                      ),
                    ),
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

class _Route {
  final String from;
  final String to;
  final String distance;
  final String pay;
  final String status;
  const _Route(this.from, this.to, this.distance, this.pay, this.status);
}

class _RouteTile extends StatelessWidget {
  final _Route route;
  const _RouteTile({required this.route});

  @override
  Widget build(BuildContext context) {
    final isAvailable = route.status == 'AVAILABLE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                ),
                Container(
                    width: 1.5,
                    height: 28,
                    color: AppColors.surfaceHighest),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.from,
                      style:
                          AppTextStyles.ui(13, weight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(route.to,
                      style:
                          AppTextStyles.ui(13, weight: FontWeight.w700)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(route.pay,
                    style: AppTextStyles.data(13,
                        weight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    route.status,
                    style: AppTextStyles.label(9,
                        color: isAvailable
                            ? AppColors.success
                            : AppColors.warning,
                        weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dead code removed: _TransporterJobs replaced by AvailableJobsScreen
class _TransporterJobs extends StatefulWidget {
  const _TransporterJobs();

  @override
  State<_TransporterJobs> createState() => _TransporterJobsState();
}

class _TransporterJobsState extends State<_TransporterJobs> {
  String _filter = 'ALL';

  static const _jobs = [
    _Job('JOB-012', 'Juba', 'Bor', '200 km', 'SSP 5,000', 'AVAILABLE',
        '500 kg Nile Perch'),
    _Job('JOB-011', 'Bor', 'Malakal', '320 km', 'SSP 8,000', 'AVAILABLE',
        '800 kg Mixed'),
    _Job('JOB-010', 'Malakal', 'Renk', '240 km', 'SSP 6,000', 'AVAILABLE',
        '400 kg Tilapia'),
    _Job('JOB-009', 'Fangak', 'Malakal', '130 km', 'SSP 3,500', 'SCHEDULED',
        '300 kg Catfish'),
  ];

  static const _filters = ['ALL', 'AVAILABLE', 'SCHEDULED', 'MY JOBS'];

  List<_Job> get _filtered =>
      _filter == 'ALL' || _filter == 'MY JOBS'
          ? _jobs
          : _jobs.where((j) => j.status == _filter).toList();

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
                  Text('Available Jobs',
                      style:
                          AppTextStyles.ui(18, weight: FontWeight.w800)),
                  Text('TRANSPORT CONTRACTS',
                      style: AppTextStyles.label(10,
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final active = _filter == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            margin:
                                const EdgeInsets.only(right: 8, bottom: 12),
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

          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _JobCard(job: _filtered[i]),
                childCount: _filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Job {
  final String id;
  final String from;
  final String to;
  final String distance;
  final String pay;
  final String status;
  final String cargo;
  const _Job(this.id, this.from, this.to, this.distance, this.pay,
      this.status, this.cargo);
}

class _JobCard extends StatelessWidget {
  final _Job job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final isAvailable = job.status == 'AVAILABLE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.success : AppColors.secondary,
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
                      child: Text('${job.from} → ${job.to}',
                          style: AppTextStyles.ui(15,
                              weight: FontWeight.w800)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? AppColors.successLight
                            : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(job.status,
                          style: AppTextStyles.label(9,
                              color: isAvailable
                                  ? AppColors.success
                                  : AppColors.warning,
                              weight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(job.cargo,
                            style: AppTextStyles.ui(12,
                                color: AppColors.onSurfaceVariant)),
                      ),
                      Text(job.distance,
                          style: AppTextStyles.data(11,
                              color: AppColors.onSurfaceFaint)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(job.id,
                        style: AppTextStyles.data(11,
                            color: AppColors.onSurfaceFaint)),
                    Text(job.pay,
                        style: AppTextStyles.data(16,
                            weight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Job booking — coming soon'),
                          behavior: SnackBarBehavior.floating),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text('ACCEPT JOB',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
