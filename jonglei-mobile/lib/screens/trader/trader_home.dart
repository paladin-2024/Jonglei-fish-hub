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
import '../shared/inbox_screen.dart';
import 'create_listing_screen.dart';
import 'marketplace_screen.dart';
import 'shipments_screen.dart';

class TraderHomeScreen extends StatefulWidget {
  const TraderHomeScreen({super.key});

  @override
  State<TraderHomeScreen> createState() => _TraderHomeScreenState();
}

class _TraderHomeScreenState extends State<TraderHomeScreen> {
  int _tab = 0;
  final _dashKey = GlobalKey<_TraderDashboardState>();

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TraderDashboard(key: _dashKey),
      const MarketplaceScreen(),
      const TraderShipmentsScreen(),
      const InboxScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.bgDeep,
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          if (i == 0 && _tab != 0) _dashKey.currentState?.refresh();
          setState(() => _tab = i);
        },
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
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded),
              label: 'MESSAGES'),
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
    activeListings: '0',
    pendingOrders: '0',
    activeShipments: '0',
  );
}

// ─── Dashboard tab ────────────────────────────────────────────────────────────
class _TraderDashboard extends StatefulWidget {
  const _TraderDashboard({super.key});

  @override
  State<_TraderDashboard> createState() => _TraderDashboardState();
}

class _TraderDashboardState extends State<_TraderDashboard> {
  List<_Price> _prices = [];
  bool _pricesLoading = true;

  _DashboardStats? _stats;
  bool _statsLoading = true;
  List<_TradeLog> _tradeLogs = [];
  bool _logsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedStats().then((_) => _fetchStats());
    _fetchTradeLogs();
    _fetchPrices();
  }

  void refresh() {
    setState(() {
      _statsLoading = true;
      _logsLoading  = true;
      _pricesLoading = true;
    });
    _fetchStats();
    _fetchTradeLogs();
    _fetchPrices();
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
        final listing = (item['listing_detail'] as Map?) ?? {};
        final buyer   = (item['buyer_detail']   as Map?) ?? {};
        return _TradeLog(
          listing['species'] as String? ?? '—',
          '${item['quantity_kg'] ?? '—'} KG',
          buyer['username'] as String? ?? '—',
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
      if (mounted) setState(() => _logsLoading = false);
    }
  }

  Future<void> _fetchPrices() async {
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.get('/marketplace/prices/');
      final list = data is List ? data : (data['results'] as List? ?? []);
      // API returns [{city, prices:[{species, price_ssp}]}] — flatten to one price per city
      final parsed = <_Price>[];
      for (final cityBlock in list) {
        final city   = (cityBlock['city'] as String? ?? '').toUpperCase();
        final prices = cityBlock['prices'] as List? ?? [];
        if (prices.isNotEmpty) {
          final first = prices.first as Map;
          final sp    = first['species'] as String? ?? '';
          final price = first['price_ssp'] ?? 0;
          parsed.add(_Price(city, 'SSP $price', sp));
        }
        if (parsed.length >= 6) break;
      }
      if (mounted) {
        setState(() {
          _prices = parsed;
          _pricesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _pricesLoading = false);
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
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
                child: Row(
                  children: [
                    // Avatar — glass circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGlow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          user?.username.isNotEmpty == true
                              ? user!.username[0].toUpperCase()
                              : 'T',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary),
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
                          Text('Fish Marketplace',
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
                                color: AppColors.danger,
                                shape: BoxShape.circle),
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
                    // Welcome row
                    Row(
                      children: [
                        Text('WELCOME BACK,',
                            style: AppTextStyles.label(10,
                                color: AppColors.textMuted)),
                        const SizedBox(width: 6),
                        Text(user?.username ?? 'Trader',
                            style: AppTextStyles.label(10,
                                color: AppColors.primary,
                                weight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Stat cards ──────────────────────────────────────────
                    _statsLoading
                        ? _statSkeletonCard(wide: true)
                        : LedgerStatCard(
                            label: 'My Listings',
                            value: _stats?.activeListings ?? '—',
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
                                  label: 'My Orders',
                                  value: _stats?.pendingOrders ?? '—',
                                  accentColor: AppColors.warning,
                                  icon: Icons.pending_actions_outlined,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statsLoading
                              ? _statSkeletonCard()
                              : LedgerStatCard(
                                  label: 'Revenue Today',
                                  value: 'SSP 0',
                                  accentColor: AppColors.secondary,
                                  icon: Icons.payments_outlined,
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Live Price Strip ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text('Live Market Prices',
                              style: AppTextStyles.ui(15,
                                  weight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text('LIVE',
                                  style: AppTextStyles.label(9,
                                      color: AppColors.success,
                                      weight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 96,
                      child: _pricesLoading
                          ? ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 4,
                              separatorBuilder: (_, idx) => const SizedBox(width: 8),
                              itemBuilder: (_, idx) => Container(
                                width: 110,
                                decoration: BoxDecoration(
                                  color: AppColors.bgElevated,
                                  borderRadius: BorderRadius.circular(AppRadius.card),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5, color: AppColors.primary),
                                  ),
                                ),
                              ),
                            )
                          : _prices.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Text('No price data yet',
                                      style: AppTextStyles.ui(12,
                                          color: AppColors.textMuted)),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _prices.length,
                                  separatorBuilder: (_, idx) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) =>
                                      _PriceCard(price: _prices[i]),
                                ),
                    ),

                    const SizedBox(height: 20),

                    // ── POST NEW LISTING CTA ────────────────────────────────
                    _PressButton(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateListingScreen()),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF07A090)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded,
                                size: 20, color: AppColors.bgDeep),
                            const SizedBox(width: 10),
                            Text('POST NEW LISTING',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: AppColors.bgDeep,
                                )),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Encyclopedia card ───────────────────────────────────
                    _PressButton(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FishEncyclopediaScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [AppColors.bgElevated, Color(0xFF162440)],
                          ),
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
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fish Encyclopedia',
                                      style: AppTextStyles.ui(14,
                                          weight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text('Species guide, nutrition & prices',
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

                    const SizedBox(height: 28),

                    // ── Recent Trade Logs ───────────────────────────────────
                    Text('Recent Trade Logs',
                        style: AppTextStyles.ui(15,
                            weight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),

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
                    else if (_tradeLogs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text('No trade logs yet',
                              style: AppTextStyles.ui(13,
                                  color: AppColors.textMuted)),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: _tradeLogs.asMap().entries.map((e) {
                            final isLast = e.key == _tradeLogs.length - 1;
                            return _TradeLogTile(
                                log: e.value, isLast: isLast);
                          }).toList(),
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

  Widget _statSkeletonCard({bool wide = false}) {
    return Container(
      height: wide ? 88 : 80,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

// ─── Press animation wrapper ──────────────────────────────────────────────────
class _PressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressButton({required this.child, required this.onTap});

  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────
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

// ─── Price card widget ────────────────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  final _Price price;
  const _PriceCard({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(price.city,
              style: AppTextStyles.label(10,
                  color: AppColors.primary, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(price.fish,
              style: AppTextStyles.ui(10, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(price.price,
              style: AppTextStyles.data(15,
                  weight: FontWeight.w700, color: AppColors.primary)),
          Text('/ KG',
              style: AppTextStyles.label(9, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Trade log tile ───────────────────────────────────────────────────────────
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
                bottom: BorderSide(color: AppColors.border, width: 1)),
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
            child: const Icon(Icons.set_meal_rounded,
                size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.fish,
                    style: AppTextStyles.ui(14,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${log.quantity} • ${log.party}',
                    style: AppTextStyles.ui(12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge.fromString(log.status),
        ],
      ),
    );
  }
}
