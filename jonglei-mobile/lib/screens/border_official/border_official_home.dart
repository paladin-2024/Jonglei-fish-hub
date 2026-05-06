import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
      const _ClearanceQueueTab(),
      const _ScanTab(),
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
            label: 'HOME',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'QUEUE',
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
class _BorderOfficialDashboard extends StatefulWidget {
  const _BorderOfficialDashboard();

  @override
  State<_BorderOfficialDashboard> createState() =>
      _BorderOfficialDashboardState();
}

class _BorderOfficialDashboardState extends State<_BorderOfficialDashboard> {
  int _pending = 0;
  int _clearedToday = 0;
  int _flagged = 0;
  bool _loading = true;
  List<_ClearanceLogData> _logs = const [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final api = context.read<AuthProvider>().api;
      final data =
          await api.get('/dashboard/border-stats/') as Map<String, dynamic>;
      if (mounted) {
        final rawRecent = data['recent'] as List<dynamic>? ?? [];
        final logs = rawRecent.map((j) {
          final m = j as Map<String, dynamic>;
          return _ClearanceLogData(
            m['shipment']?.toString() ?? m['id']?.toString() ?? '—',
            m['cargo_description']?.toString() ??
                m['notes']?.toString() ??
                'Shipment',
            m['checkpoint']?.toString() ?? '—',
            m['status']?.toString().toUpperCase() ?? 'PENDING',
          );
        }).toList();
        setState(() {
          _pending = (data['pending_clearances'] as num?)?.toInt() ?? 0;
          _clearedToday = (data['cleared_today'] as num?)?.toInt() ?? 0;
          _flagged = (data['flagged'] as num?)?.toInt() ?? 0;
          _logs = logs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final top = MediaQuery.of(context).padding.top;

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
                  border: Border(
                      bottom: BorderSide(color: AppColors.border)),
                ),
                padding: EdgeInsets.fromLTRB(20, top + 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          user?.username.isNotEmpty == true
                              ? user!.username[0].toUpperCase()
                              : 'B',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
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
                          Text('Border Clearance Station',
                              style: AppTextStyles.ui(12,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          color: AppColors.textSecondary,
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

            // ── Stat cards + activity ───────────────────────────────────────
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
                        Text(user?.username ?? 'Officer',
                            style: AppTextStyles.label(10,
                                color: AppColors.danger,
                                weight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Three stat cards: Pending=amber, Cleared=teal, Flagged=red
                    Row(
                      children: [
                        Expanded(
                          child: _BorderStatCard(
                            label: 'PENDING',
                            value: _loading ? '—' : '$_pending',
                            color: AppColors.warning,
                            icon: Icons.pending_actions_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BorderStatCard(
                            label: 'CLEARED',
                            value: _loading ? '—' : '$_clearedToday',
                            color: AppColors.primary,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BorderStatCard(
                            label: 'FLAGGED',
                            value: _loading ? '—' : '$_flagged',
                            color: AppColors.danger,
                            icon: Icons.flag_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Recent Activity',
                      style: AppTextStyles.ui(15,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),

                    if (!_loading && _logs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            const Icon(Icons.inbox_rounded,
                                size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No recent activity',
                              style: AppTextStyles.ui(13,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: _logs.asMap().entries.map((e) {
                            final isLast = e.key == _logs.length - 1;
                            return _ClearanceLogTile(
                                log: e.value, isLast: isLast);
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
      ),
    );
  }
}

// ─── Border stat card ─────────────────────────────────────────────────────────
class _BorderStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _BorderStatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.0,
              )),
          const SizedBox(height: 4),
          Text(label,
              style:
                  AppTextStyles.label(8, color: AppColors.textMuted)),
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

  Color get _statusColor {
    switch (log.status) {
      case 'CLEARED':
        return AppColors.success;
      case 'FLAGGED':
      case 'HELD':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGlow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.set_meal_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.shipmentId,
                  style: AppTextStyles.data(13,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  log.description,
                  style: AppTextStyles.ui(12,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      log.route,
                      style: AppTextStyles.ui(11,
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: _statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              log.status,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _statusColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clearance Queue tab ──────────────────────────────────────────────────────
class _Clearance {
  final String id;
  final String shipmentId;
  final String description;
  final String route;
  final String status;
  final String timestamp;

  const _Clearance({
    required this.id,
    required this.shipmentId,
    required this.description,
    required this.route,
    required this.status,
    required this.timestamp,
  });

  factory _Clearance.fromJson(Map<String, dynamic> j) {
    return _Clearance(
      id: j['id']?.toString() ?? '—',
      shipmentId: j['shipment_id']?.toString() ??
          j['shipment']?.toString() ??
          j['id']?.toString() ??
          '—',
      description: j['cargo_description']?.toString() ??
          j['description']?.toString() ??
          '—',
      route:
          '${j['origin'] ?? j['from'] ?? '—'} → ${j['destination'] ?? j['to'] ?? '—'}',
      status: (j['status'] ?? 'PENDING').toString().toUpperCase(),
      timestamp: j['created_at']?.toString() ??
          j['timestamp']?.toString() ??
          '',
    );
  }
}

const _sampleClearances = [
  _Clearance(
    id: 'CLR-0041',
    shipmentId: 'SHP-0041',
    description: 'Nile Perch • 120 kg',
    route: 'Bor → Juba',
    status: 'PENDING',
    timestamp: '2026-05-03 09:14',
  ),
  _Clearance(
    id: 'CLR-0040',
    shipmentId: 'SHP-0040',
    description: 'Tilapia • 45 kg',
    route: 'Panyagoor → Bor',
    status: 'PENDING',
    timestamp: '2026-05-03 08:52',
  ),
  _Clearance(
    id: 'CLR-0039',
    shipmentId: 'SHP-0039',
    description: 'Catfish • 200 kg',
    route: 'Twic East → Juba',
    status: 'PENDING',
    timestamp: '2026-05-03 08:30',
  ),
];

class _ClearanceQueueTab extends StatefulWidget {
  const _ClearanceQueueTab();

  @override
  State<_ClearanceQueueTab> createState() => _ClearanceQueueTabState();
}

class _ClearanceQueueTabState extends State<_ClearanceQueueTab> {
  List<_Clearance> _clearances = _sampleClearances;
  bool _loading = true;
  String? _actingId;

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
      final raw = await api.get('/clearance/?status=PENDING') as List;
      if (mounted) {
        setState(() {
          _clearances = raw
              .map((j) => _Clearance.fromJson(j as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
      // Use sample data already set
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _act(String clearanceId, String action) async {
    setState(() => _actingId = clearanceId);
    try {
      final api = context.read<AuthProvider>().api;
      await api.post('/clearance/$clearanceId/$action/', {});
      if (mounted) {
        final label = action == 'scan_clear' ? 'Cleared' : 'Held';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shipment $label successfully'),
            backgroundColor: action == 'scan_clear'
                ? AppColors.success
                : AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.bgDeep, AppColors.bgBase],
                ),
                border: Border(
                    bottom: BorderSide(color: AppColors.border)),
              ),
              padding: EdgeInsets.fromLTRB(
                  18, MediaQuery.of(context).padding.top + 16, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Clearance Queue',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 22,
                              color: AppColors.primary,
                              letterSpacing: -0.4,
                            )),
                        Text('PENDING SHIPMENTS',
                            style: AppTextStyles.label(10,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Text('${_clearances.length} PENDING',
                        style: AppTextStyles.label(10,
                            color: AppColors.warning,
                            weight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        size: 20, color: AppColors.textSecondary),
                    onPressed: _load,
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ClearanceSkeleton(),
                  childCount: 3,
                ),
              ),
            )
          else if (_clearances.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.inbox_rounded,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('Queue is clear',
                        style: AppTextStyles.ui(15,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text('No pending clearances at this time',
                        style: AppTextStyles.ui(12,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ClearanceCard(
                    clearance: _clearances[i],
                    isActing: _actingId == _clearances[i].id,
                    onClear: () => _act(_clearances[i].id, 'scan_clear'),
                    onHold: () => _act(_clearances[i].id, 'hold'),
                  ),
                  childCount: _clearances.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _ClearanceCard extends StatelessWidget {
  final _Clearance clearance;
  final bool isActing;
  final VoidCallback onClear;
  final VoidCallback onHold;

  const _ClearanceCard({
    required this.clearance,
    required this.isActing,
    required this.onClear,
    required this.onHold,
  });

  Color get _accentColor {
    switch (clearance.status) {
      case 'PENDING':
        return AppColors.warning;
      case 'CLEARED':
        return AppColors.primary;
      case 'HELD':
      case 'FLAGGED':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_accentColor, _accentColor.withValues(alpha: 0.3)]),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clearance.shipmentId,
                              style: AppTextStyles.data(13,
                                  weight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(clearance.description,
                              style: AppTextStyles.ui(12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    StatusBadge.fromString(clearance.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(clearance.route,
                        style: AppTextStyles.ui(11,
                            color: AppColors.textMuted)),
                    const Spacer(),
                    if (clearance.timestamp.isNotEmpty)
                      Text(clearance.timestamp,
                          style: AppTextStyles.data(10,
                              color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: isActing ? null : onClear,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            disabledBackgroundColor: AppColors.surfaceHighest,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: isActing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text('CLEAR',
                                  style: AppTextStyles.label(12,
                                      color: Colors.white,
                                      weight: FontWeight.w800)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: isActing ? null : onHold,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            disabledBackgroundColor: AppColors.surfaceHighest,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: isActing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text('HOLD',
                                  style: AppTextStyles.label(12,
                                      color: Colors.white,
                                      weight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearanceSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighest,
              borderRadius: BorderRadius.vertical(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 14,
                            width: 100,
                            color: AppColors.surfaceHighest),
                        const SizedBox(height: 4),
                        Container(
                            height: 11,
                            width: 140,
                            color: AppColors.surfaceHighest),
                      ],
                    ),
                    const Spacer(),
                    Container(
                        height: 20,
                        width: 60,
                        color: AppColors.surfaceHighest),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                    height: 11,
                    width: 180,
                    color: AppColors.surfaceHighest),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColors.surfaceHighest,
                                borderRadius:
                                    BorderRadius.circular(8)))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColors.surfaceHighest,
                                borderRadius:
                                    BorderRadius.circular(8)))),
                  ],
                ),
              ],
            ),
          ),
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
  late final MobileScannerController _scannerCtrl;
  bool _cameraActive = false;
  bool _scanning = false;

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
    _scannerCtrl = MobileScannerController();
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  void _toggleCamera() {
    setState(() => _cameraActive = !_cameraActive);
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final raw = barcode.rawValue ?? '';
    String? clearanceId;
    if (raw.startsWith('JONGLEI:CLEARANCE:')) {
      clearanceId = raw.substring('JONGLEI:CLEARANCE:'.length).trim();
    } else {
      clearanceId = raw.trim();
    }
    if (clearanceId.isEmpty) return;
    setState(() => _scanning = true);
    await _handleClearanceId(clearanceId);
    setState(() => _scanning = false);
  }

  Future<void> _handleClearanceId(String clearanceId) async {
    Map<String, dynamic>? details;
    try {
      final api = context.read<AuthProvider>().api;
      details = await api.get('/clearance/$clearanceId/')
          as Map<String, dynamic>;
    } catch (_) {}
    if (!mounted) return;
    _showClearanceSheet(clearanceId, details);
  }

  void _showClearanceSheet(
      String clearanceId, Map<String, dynamic>? details) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Clearance Confirmation',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 20,
                  color: AppColors.primary,
                  letterSpacing: -0.4,
                )),
            const SizedBox(height: 4),
            Text('Review details before clearing',
                style: AppTextStyles.ui(12,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgBase,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _SheetRow(label: 'Clearance ID', value: clearanceId),
                  if (details != null) ...[
                    const SizedBox(height: 8),
                    _SheetRow(
                      label: 'Shipment',
                      value: details['shipment_id']?.toString() ??
                          details['shipment']?.toString() ??
                          '—',
                    ),
                    const SizedBox(height: 8),
                    _SheetRow(
                      label: 'Cargo',
                      value: details['cargo_description']?.toString() ??
                          details['description']?.toString() ??
                          '—',
                    ),
                    const SizedBox(height: 8),
                    _SheetRow(
                      label: 'Route',
                      value:
                          '${details['origin'] ?? details['from'] ?? '—'} → ${details['destination'] ?? details['to'] ?? '—'}',
                    ),
                    const SizedBox(height: 8),
                    _SheetRow(
                      label: 'Status',
                      value: (details['status'] ?? 'PENDING')
                          .toString()
                          .toUpperCase(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)),
                      ),
                      child: Text('CANCEL',
                          style: AppTextStyles.ui(13,
                              weight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        try {
                          final api = context.read<AuthProvider>().api;
                          await api.post(
                              '/clearance/$clearanceId/scan_clear/', {});
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Shipment cleared successfully!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Clearance failed: $e'),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded,
                          size: 18, color: Colors.white),
                      label: Text('CONFIRM CLEAR',
                          style: AppTextStyles.ui(13,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Enter Clearance ID',
          style: GoogleFonts.dmSerifDisplay(
              fontSize: 18, color: AppColors.primary),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: AppTextStyles.data(14),
            decoration: const InputDecoration(
              hintText: 'e.g. CLR-0041',
              prefixIcon: Icon(
                Icons.tag_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a clearance ID' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: AppTextStyles.ui(13,
                  weight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final id = controller.text.trim();
                Navigator.of(ctx).pop();
                _handleClearanceId(id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.bgDeep,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(
              'LOOKUP',
              style: AppTextStyles.ui(13,
                  weight: FontWeight.w800,
                  color: AppColors.bgDeep,
                  letterSpacing: 0.5),
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
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera background when active
            if (_cameraActive)
              Positioned.fill(
                child: MobileScanner(
                  controller: _scannerCtrl,
                  onDetect: _onDetect,
                ),
              ),

            Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'SCAN QR CODE',
                        style: AppTextStyles.label(
                          12,
                          color: AppColors.primary,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.flash_on_outlined,
                            color: AppColors.textSecondary),
                        onPressed: () => _scannerCtrl.toggleTorch(),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── QR viewfinder ──────────────────────────────────────────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_cameraActive)
                      SizedBox(
                        width: viewfinderSize + 80,
                        height: viewfinderSize + 80,
                        child: CustomPaint(
                          painter: _DimOverlayPainter(viewfinderSize),
                        ),
                      ),

                    // Amber viewfinder border
                    Container(
                      width: viewfinderSize,
                      height: viewfinderSize,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    // Amber corner brackets
                    SizedBox(
                      width: viewfinderSize,
                      height: viewfinderSize,
                      child: CustomPaint(
                        painter: _CornerBracketsPainter(
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    // Animated amber scan line
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
                                        AppColors.primary
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

                    if (_scanning)
                      Container(
                        width: viewfinderSize,
                        height: viewfinderSize,
                        color: Colors.black38,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      ),
                  ],
                ),

                const Spacer(),

                // ── Buttons ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                  child: Column(
                    children: [
                      Text(
                        'SCAN SHIPMENT QR',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22,
                          color: AppColors.primary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _cameraActive
                            ? 'Point camera at QR code'
                            : 'Align code within the frame',
                        style: AppTextStyles.ui(13,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 28),

                      // Manual entry
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _showManualEntry,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(
                                color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(
                            'ENTER CODE MANUALLY',
                            style: AppTextStyles.ui(13,
                                weight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Scan Now / Stop — amber
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _toggleCamera,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cameraActive
                                ? AppColors.danger
                                : AppColors.primary,
                            foregroundColor: AppColors.bgDeep,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(
                            _cameraActive ? 'STOP SCANNING' : 'SCAN NOW',
                            style: AppTextStyles.ui(14,
                                weight: FontWeight.w800,
                                color: AppColors.bgDeep,
                                letterSpacing: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
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

// ─── Helper widget ────────────────────────────────────────────────────────────
class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  const _SheetRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text('$label:',
              style:
                  AppTextStyles.ui(12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: AppTextStyles.data(12,
                  weight: FontWeight.w600,
                  color: AppColors.primary),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ─── Corner brackets painter ──────────────────────────────────────────────────
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

// ─── Dim overlay painter ──────────────────────────────────────────────────────
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
    canvas.drawPath(combined,
        Paint()..color = Colors.black.withValues(alpha: 0.65));
  }

  @override
  bool shouldRepaint(_DimOverlayPainter old) => old.clearSize != clearSize;
}
