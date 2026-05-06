import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/fish_encyclopedia_screen.dart';
import '../shared/market_map_screen.dart';
import '../shared/notification_screen.dart';
import '../shared/profile_screen.dart';
import 'browse_listings_screen.dart';
import 'buyer_orders_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _BuyerDashboard(),
      const BrowseListingsScreen(),
      const BuyerOrdersScreen(),
      const MarketMapScreen(),
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
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'BROWSE'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'ORDERS'),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'MARKETS'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'PROFILE'),
        ],
      ),
    );
  }
}

class _BuyerDashboard extends StatefulWidget {
  const _BuyerDashboard();

  @override
  State<_BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<_BuyerDashboard> {
  List<_Market> _featured = [];
  bool _featuredLoading = true;

  int _orderCount = 0;
  bool _loadingOrders = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderCount();
    _fetchFeatured();
  }

  Future<void> _fetchFeatured() async {
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.get('/marketplace/prices/?limit=4');
      final list = data is List ? data : (data['results'] as List? ?? []);
      final markets = list.map<_Market>((item) {
        final city  = item['city'] as String? ?? '—';
        final sp    = item['species'] as String? ?? '—';
        final price = item['price_per_kg'] ?? item['price'] ?? 0;
        return _Market(city, sp, 'SSP $price', (price as num).toInt());
      }).toList();
      if (mounted) {
        setState(() {
          _featured = markets;
          _featuredLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _featuredLoading = false);
    }
  }

  Future<void> _fetchOrderCount() async {
    try {
      final api = context.read<AuthProvider>().api;
      final raw = await api.get('/marketplace/orders/my-orders/');
      final list = raw is List ? raw : (raw['results'] as List? ?? []);
      if (mounted) {
        setState(() {
          _orderCount = list.length;
          _loadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOrders = false);
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
                              : 'B',
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
                          Text('Fish Marketplace',
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
                        Text(user?.username ?? 'Buyer',
                            style: AppTextStyles.label(10,
                                color: AppColors.secondary,
                                weight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Orders count — large JetBrains Mono card ────────────
                    Container(
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
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.secondary]),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.card)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('MY ORDERS',
                                          style: AppTextStyles.label(10,
                                              color: AppColors.textSecondary)),
                                      const SizedBox(height: 6),
                                      Text(
                                        _loadingOrders ? '—' : '$_orderCount',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGlow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 26,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── 2×2 quick action grid ───────────────────────────────
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                      children: [
                        _QuickAction(
                          icon: Icons.search_rounded,
                          label: 'Browse',
                          color: AppColors.secondary,
                          onTap: () {},
                        ),
                        _QuickAction(
                          icon: Icons.receipt_long_rounded,
                          label: 'Orders',
                          color: AppColors.primary,
                          onTap: () {},
                        ),
                        _QuickAction(
                          icon: Icons.storefront_rounded,
                          label: 'Markets',
                          color: AppColors.secondary,
                          onTap: () {},
                        ),
                        _QuickAction(
                          icon: Icons.notifications_active_outlined,
                          label: 'Alerts',
                          color: AppColors.warning,
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Featured Markets ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text('Featured Markets',
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
                              Text('LIVE PRICES',
                                  style: AppTextStyles.label(9,
                                      color: AppColors.success,
                                      weight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_featuredLoading)
                      ...[1, 2, 3].map((_) => Container(
                        height: 68,
                        margin: const EdgeInsets.only(bottom: 10),
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
                      ))
                    else if (_featured.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text('No market data yet',
                              style: AppTextStyles.ui(13,
                                  color: AppColors.textMuted)),
                        ),
                      )
                    else
                      ..._featured.map((m) => _MarketTile(market: m)),

                    const SizedBox(height: 14),

                    // ── Encyclopedia featured card ───────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FishEncyclopediaScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.bgElevated, AppColors.bgBase],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryGlow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.menu_book_rounded,
                                  size: 24, color: AppColors.secondary),
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
                                  Text('Species guide & nutritional facts',
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

// ─── Quick action card ────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: AppTextStyles.ui(13,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────
class _Market {
  final String name;
  final String fish;
  final String price;
  final int priceRaw;
  const _Market(this.name, this.fish, this.price, this.priceRaw);
}

// ─── Market tile with gradient left border ────────────────────────────────────
class _MarketTile extends StatelessWidget {
  final _Market market;
  const _MarketTile({required this.market});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Gradient left border strip: amber → teal
          Container(
            width: 4,
            height: 70,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryGlow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(market.name,
                      style: AppTextStyles.ui(14,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(market.fish,
                      style: AppTextStyles.ui(12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${market.price}/kg',
                    style: AppTextStyles.data(13,
                        weight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('TODAY',
                    style: AppTextStyles.label(9,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
