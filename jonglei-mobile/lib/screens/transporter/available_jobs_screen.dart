import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'active_job_screen.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class _Job {
  final String id;
  final String from;
  final String to;
  final String distance;
  final String pay;
  final String status;
  final String cargo;
  final String? shipmentId;

  const _Job({
    required this.id,
    required this.from,
    required this.to,
    required this.distance,
    required this.pay,
    required this.status,
    required this.cargo,
    this.shipmentId,
  });

  factory _Job.fromJson(Map<String, dynamic> j) {
    final origin = (j['origin_location'] ?? j['from'] ?? '—').toString();
    final dest = (j['destination_location'] ?? j['to'] ?? '—').toString();
    final pay = j['payment_amount'] ?? j['pay'];
    final payStr = pay != null ? 'SSP ${pay.toString()}' : 'SSP —';
    final dist = j['distance_km'];
    final distStr = dist != null ? '${dist.toString()} km' : '—';
    final fish = j['fish_type'] ?? j['cargo'] ?? '—';
    final qty = j['quantity_kg'] ?? '';
    final cargoStr = qty.toString().isNotEmpty ? '$qty kg $fish' : fish.toString();
    return _Job(
      id: j['id']?.toString() ?? '—',
      from: origin,
      to: dest,
      distance: distStr,
      pay: payStr,
      status: (j['status'] ?? 'OPEN').toString().toUpperCase(),
      cargo: cargoStr,
      shipmentId: j['shipment']?.toString() ?? j['shipment_id']?.toString(),
    );
  }
}

const _sampleJobs = [
  _Job(
    id: 'JOB-012',
    from: 'Juba',
    to: 'Bor',
    distance: '200 km',
    pay: 'SSP 5,000',
    status: 'OPEN',
    cargo: '500 kg Nile Perch',
  ),
  _Job(
    id: 'JOB-011',
    from: 'Bor',
    to: 'Malakal',
    distance: '320 km',
    pay: 'SSP 8,000',
    status: 'OPEN',
    cargo: '800 kg Mixed',
  ),
  _Job(
    id: 'JOB-010',
    from: 'Malakal',
    to: 'Renk',
    distance: '240 km',
    pay: 'SSP 6,000',
    status: 'OPEN',
    cargo: '400 kg Tilapia',
  ),
  _Job(
    id: 'JOB-009',
    from: 'Fangak',
    to: 'Malakal',
    distance: '130 km',
    pay: 'SSP 3,500',
    status: 'ACCEPTED',
    cargo: '300 kg Catfish',
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class AvailableJobsScreen extends StatefulWidget {
  const AvailableJobsScreen({super.key});

  @override
  State<AvailableJobsScreen> createState() => _AvailableJobsScreenState();
}

class _AvailableJobsScreenState extends State<AvailableJobsScreen> {
  String _filter = 'ALL';
  List<_Job> _jobs = _sampleJobs;
  bool _loading = true;
  String? _acceptingId;

  static const _filters = ['ALL', 'AVAILABLE', 'ACCEPTED', 'IN TRANSIT'];

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
      final raw = await api.get('/transport/jobs/?status=OPEN') as List;
      if (mounted) {
        setState(() {
          _jobs = raw
              .map((j) => _Job.fromJson(j as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
      // Fall back to sample data already set
    }
    if (mounted) setState(() => _loading = false);
  }

  List<_Job> get _filtered {
    if (_filter == 'ALL') return _jobs;
    if (_filter == 'AVAILABLE') {
      return _jobs.where((j) => j.status == 'OPEN' || j.status == 'AVAILABLE').toList();
    }
    return _jobs.where((j) => j.status == _filter).toList();
  }

  Future<void> _acceptJob(_Job job) async {
    setState(() => _acceptingId = job.id);
    try {
      final api = context.read<AuthProvider>().api;
      await api.post('/transport/jobs/${job.id}/accept_job/', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job ${job.id} accepted!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept job: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _acceptingId = null);
    }
  }

  _Job? get _activeJob {
    try {
      return _jobs.firstWhere(
        (j) => j.status == 'ACCEPTED' || j.status == 'IN_TRANSIT' || j.status == 'IN TRANSIT',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      floatingActionButton: _activeJob != null
          ? FloatingActionButton.extended(
              onPressed: () {
                final job = _activeJob!;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ActiveJobScreen(
                    jobId: job.id,
                    shipmentId: job.shipmentId ?? job.id,
                    fromLocation: job.from,
                    toLocation: job.to,
                    cargoType: job.cargo,
                  ),
                ));
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.local_shipping_rounded, color: Colors.white),
              label: Text(
                'MY ACTIVE JOB',
                style: AppTextStyles.label(12,
                    color: Colors.white, weight: FontWeight.w700),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(
                  18, MediaQuery.of(context).padding.top + 16, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Available Jobs',
                                style: AppTextStyles.ui(18,
                                    weight: FontWeight.w800)),
                            Text('TRANSPORT CONTRACTS',
                                style: AppTextStyles.label(10,
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            size: 20, color: AppColors.onSurfaceVariant),
                        onPressed: _load,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final active = _filter == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8, bottom: 12),
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

          // ── Content ──────────────────────────────────────────────────────
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => const _JobSkeletonCard(),
                  childCount: 4,
                ),
              ),
            )
          else if (_filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.assignment_outlined,
                        size: 48, color: AppColors.onSurfaceFaint),
                    const SizedBox(height: 12),
                    Text('No jobs found',
                        style: AppTextStyles.ui(15,
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text('Check back later for new transport contracts',
                        style: AppTextStyles.ui(12,
                            color: AppColors.onSurfaceFaint)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _JobCard(
                    job: _filtered[i],
                    isAccepting: _acceptingId == _filtered[i].id,
                    onAccept: () => _acceptJob(_filtered[i]),
                    onViewActive: _filtered[i].status == 'ACCEPTED' ||
                            _filtered[i].status == 'IN_TRANSIT' ||
                            _filtered[i].status == 'IN TRANSIT'
                        ? () {
                            final job = _filtered[i];
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ActiveJobScreen(
                                jobId: job.id,
                                shipmentId: job.shipmentId ?? job.id,
                                fromLocation: job.from,
                                toLocation: job.to,
                                cargoType: job.cargo,
                              ),
                            ));
                          }
                        : null,
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─── Job card ─────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final _Job job;
  final bool isAccepting;
  final VoidCallback onAccept;
  final VoidCallback? onViewActive;

  const _JobCard({
    required this.job,
    required this.isAccepting,
    required this.onAccept,
    this.onViewActive,
  });

  Color get _accentColor {
    switch (job.status) {
      case 'OPEN':
      case 'AVAILABLE':
        return AppColors.primary;
      case 'ACCEPTED':
        return AppColors.secondary;
      case 'IN_TRANSIT':
      case 'IN TRANSIT':
        return AppColors.info;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = job.status == 'OPEN' || job.status == 'AVAILABLE';
    final isActive = job.status == 'ACCEPTED' ||
        job.status == 'IN_TRANSIT' ||
        job.status == 'IN TRANSIT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          // 3px teal top accent bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route + status
                Row(
                  children: [
                    Expanded(
                      child: Text('${job.from} → ${job.to}',
                          style: AppTextStyles.ui(15, weight: FontWeight.w800)),
                    ),
                    StatusBadge.fromString(
                        job.status == 'OPEN' ? 'CONFIRMED' : job.status),
                  ],
                ),
                const SizedBox(height: 10),

                // Cargo chip
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.set_meal_rounded,
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

                // ID + pay
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

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: isActive
                      ? ElevatedButton.icon(
                          onPressed: onViewActive,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.local_shipping_rounded,
                              size: 16, color: Colors.white),
                          label: Text('VIEW ACTIVE JOB',
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.white)),
                        )
                      : ElevatedButton(
                          onPressed: isOpen && !isAccepting ? onAccept : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.surfaceHighest,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: isAccepting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text('ACCEPT JOB',
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

// ─── Skeleton card ────────────────────────────────────────────────────────────
class _JobSkeletonCard extends StatelessWidget {
  const _JobSkeletonCard();

  @override
  Widget build(BuildContext context) {
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
            decoration: const BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                        height: 16, width: 160, color: AppColors.surfaceHigh),
                    const Spacer(),
                    Container(
                        height: 20, width: 60, color: AppColors.surfaceHigh),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 12, width: 80, color: AppColors.surfaceHigh),
                    Container(height: 16, width: 100, color: AppColors.surfaceHigh),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
