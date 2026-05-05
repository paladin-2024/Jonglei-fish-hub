import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_box.dart';
import '../shared/profile_screen.dart';
import '../shared/notification_screen.dart';
import '../shared/fish_encyclopedia_screen.dart';
import 'create_listing_screen.dart';
import 'marketplace_screen.dart';
import 'prices_screen.dart';
import 'shipments_screen.dart';

class TraderHomeScreen extends StatefulWidget {
  const TraderHomeScreen({super.key});

  @override
  State<TraderHomeScreen> createState() => _TraderHomeScreenState();
}

class _TraderHomeScreenState extends State<TraderHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _TraderDashboard(),
      const MarketplaceScreen(),
      const TraderShipmentsScreen(),
      const PricesScreen(),
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
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'MARKET'),
          NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping_rounded),
              label: 'SHIPMENTS'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'PRICES'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'PROFILE'),
        ],
      ),
    );
  }
}

// ─── Dashboard stats holder ───────────────────────────────────────────────────
class _DashboardStats {
  final String activeListings;
  final String pendingOrders;
  final String activeShipments;

  const _DashboardStats({
    required this.activeListings,
    required this.pendingOrders,
    required this.activeShipments,
  });

  factory _DashboardStats.fromMap(Map<String, dynamic> map) => _DashboardStats(
        activeListings: map['active_listings']?.toString() ?? '—',
        pendingOrders: map['pending_orders']?.toString() ?? '—',
        activeShipments: map['active_shipments']?.toString() ?? '—',
      );

  static const fallback = _DashboardStats(
    activeListings: '14',
    pendingOrders: '08',
    activeShipments: '03',
  );
}

// ─── Dashboard tab ────────────────────────────────────────────────────────────
class _TraderDashboard extends StatefulWidget {
  const _TraderDashboard();

  @override
  State<_TraderDashboard> createState() => _TraderDashboardState();
}

class _TraderDashboardState extends State<_TraderDashboard> {
  static const _prices = [
    _Price('BOR', 'SSP 450', 'Nile Perch'),
    _Price('JUBA', 'SSP 620', 'Nile Perch'),
    _Price('WAU', 'SSP 480', 'Nile Perch'),
  ];

  _DashboardStats? _stats;
  bool _statsLoading = true;
  List<_TradeLog> _tradeLogs = [];
  bool _logsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedStats().then((_) => _fetchStats());
    _fetchTradeLogs();
  }

  Future<void> _loadCachedStats() async {
    try {
      final box = await Hive.openBox('jonglei_cache');
      final raw = box.get('dashboard_stats');
      if (raw != null) {
        final map = jsonDecode(raw as String) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _stats = _DashboardStats.fromMap(map);
            _statsLoading = false;
          });
        }
      }
    } catch (_) {
      // Cache miss — continue to fetch
    }
  }

  Future<void> _fetchStats() async {
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.get('/dashboard/my-stats/');
      final map = data as Map<String, dynamic>;
      final box = await Hive.openBox('jonglei_cache');
      await box.put('dashboard_stats', jsonEncode(map));
      if (mounted) {
        setState(() {
          _stats = _DashboardStats.fromMap(map);
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted && _stats == null) {
        setState(() {
          _stats = _DashboardStats.fallback;
          _statsLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTradeLogs() async {
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.get('/marketplace/orders/');
      final list = data is List ? data : (data['results'] as List? ?? []);
      final logs = list.take(3).map<_TradeLog>((item) {
        return _TradeLog(
          item['fish_species'] as String? ?? item['species'] as String? ?? '',
          item['quantity'] as String? ?? '',
          item['party'] as String? ?? item['counterpart'] as String? ?? '',
          ((item['status'] as String? ?? 'PENDING')).toUpperCase(),
        );
      }).toList();
      if (mounted) {
        setState(() {
          _tradeLogs = logs;
          _logsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tradeLogs = const [
            _TradeLog('Nile Perch', '45 KG', 'B. Chol', 'PENDING'),
            _TradeLog('Tilapia', '120 KG', 'Nile Logistics', 'CONFIRMED'),
            _TradeLog('Catfish', '80 KG', 'Juba Market', 'IN TRANSIT'),
          ];
          _logsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 16, 20, 16),
              child: Row(
                children: [
                  // Avatar
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
                        Text(user?.username ?? 'Trader',
                            style: AppTextStyles.ui(18,
                                weight: FontWeight.w800,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: AppColors.onSurfaceVariant,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationScreen()),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.danger, shape: BoxShape.circle),
                        ),
                      ),
                    ],
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
                  // Stat cards
                  LedgerStatCard(
                    label: 'Active Listings',
                    value: _statsLoading ? '…' : (_stats?.activeListings ?? '—'),
                    accentColor: AppColors.primary,
                    icon: Icons.inventory_2_outlined,
                    wide: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _statsLoading
                            ? _statSkeletonCard()
                            : LedgerStatCard(
                                label: 'Pending',
                                value: _stats?.pendingOrders ?? '—',
                                accentColor: AppColors.secondary,
                                icon: Icons.pending_actions_outlined,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statsLoading
                            ? _statSkeletonCard()
                            : LedgerStatCard(
                                label: 'In Transit',
                                value: _stats?.activeShipments ?? '—',
                                accentColor: AppColors.info,
                                icon: Icons.local_shipping_outlined,
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Market Price Ledger
                  Row(
                    children: [
                      Expanded(
                        child: Text('Market Price Ledger',
                            style: AppTextStyles.ui(15, weight: FontWeight.w700)),
                      ),
                      Text('LIVE UPDATES',
                          style: AppTextStyles.label(10,
                              color: AppColors.success,
                              weight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _prices.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => _PriceCard(price: _prices[i]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // POST NEW LISTING CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateListingScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text('POST NEW LISTING',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: Colors.white,
                              )),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Encyclopedia quick-link
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FishEncyclopediaScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                                    style: AppTextStyles.ui(14, weight: FontWeight.w700)),
                                Text('Species guide, nutrition & prices',
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

                  const SizedBox(height: 28),

                  Text('Recent Trade Logs',
                      style: AppTextStyles.ui(15, weight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  // Trade log list
                  if (_logsLoading)
                    Column(
                      children: List.generate(
                        3,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: ShimmerCard(),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Column(
                        children: _tradeLogs.asMap().entries.map((e) {
                          final isLast = e.key == _tradeLogs.length - 1;
                          return _TradeLogTile(log: e.value, isLast: isLast);
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

  Widget _statSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 80, height: 10),
                const SizedBox(height: 8),
                ShimmerBox(width: 48, height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeLog {
  final String fish;
  final String quantity;
  final String party;
  final String status;
  const _TradeLog(this.fish, this.quantity, this.party, this.status);
}

class _Price {
  final String city;
  final String price;
  final String fish;
  const _Price(this.city, this.price, this.fish);
}

class _PriceCard extends StatelessWidget {
  final _Price price;
  const _PriceCard({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(price.city,
              style: AppTextStyles.label(10,
                  color: AppColors.primary, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.set_meal_rounded,
                  size: 12, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 3),
              Expanded(
                child: Text(price.price,
                    style: AppTextStyles.data(14,
                        weight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('/ KG',
              style: AppTextStyles.label(9, color: AppColors.onSurfaceFaint)),
        ],
      ),
    );
  }
}

class _TradeLogTile extends StatelessWidget {
  final _TradeLog log;
  final bool isLast;
  const _TradeLogTile({required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surfaceLow, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.set_meal_rounded,
                size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.fish,
                    style: AppTextStyles.ui(14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${log.quantity} • ${log.party}',
                    style: AppTextStyles.ui(12,
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          StatusBadge.fromString(log.status),
        ],
      ),
    );
  }
}
