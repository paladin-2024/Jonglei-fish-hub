import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/market_map_screen.dart';
import '../shared/profile_screen.dart';

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
      const _BuyerBrowse(),
      const MarketMapScreen(),
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
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'BROWSE'),
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

class _BuyerDashboard extends StatelessWidget {
  const _BuyerDashboard();

  static const _featured = [
    _Market('Juba Central', 'Nile Perch', 'SSP 800', 2800),
    _Market('Bor Market', 'Tilapia', 'SSP 450', 1800),
    _Market('Malakal Landing', 'Catfish', 'SSP 350', 1200),
  ];

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
                            : 'B',
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
                        Text(user?.username ?? 'Buyer',
                            style: AppTextStyles.ui(18,
                                weight: FontWeight.w800,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () {},
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
                    label: 'My Orders',
                    value: '0',
                    accentColor: AppColors.primary,
                    icon: Icons.receipt_long_outlined,
                    wide: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LedgerStatCard(
                          label: 'Saved',
                          value: '0',
                          accentColor: AppColors.danger,
                          icon: Icons.favorite_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LedgerStatCard(
                          label: 'Markets',
                          value: '6',
                          accentColor: AppColors.secondary,
                          icon: Icons.storefront_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: Text('Featured Markets',
                            style: AppTextStyles.ui(15, weight: FontWeight.w700)),
                      ),
                      Text('LIVE PRICES',
                          style: AppTextStyles.label(10,
                              color: AppColors.success, weight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ..._featured.map((m) => _MarketTile(market: m)),

                  const SizedBox(height: 20),

                  // Price alert CTA
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.trending_up_rounded,
                              color: AppColors.secondary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Price Alerts',
                                  style: AppTextStyles.ui(14,
                                      weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('Get notified when prices drop',
                                  style: AppTextStyles.ui(12,
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: AppColors.onSurfaceFaint),
                      ],
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

class _Market {
  final String name;
  final String fish;
  final String price;
  final int priceRaw;
  const _Market(this.name, this.fish, this.price, this.priceRaw);
}

class _MarketTile extends StatelessWidget {
  final _Market market;
  const _MarketTile({required this.market});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(market.name,
                    style:
                        AppTextStyles.ui(14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(market.fish,
                    style: AppTextStyles.ui(12,
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${market.price}/kg',
                  style: AppTextStyles.data(13,
                      weight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 2),
              Text('TODAY',
                  style: AppTextStyles.label(9,
                      color: AppColors.onSurfaceFaint)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Browse tab ───────────────────────────────────────────────────────────────
class _BuyerBrowse extends StatefulWidget {
  const _BuyerBrowse();

  @override
  State<_BuyerBrowse> createState() => _BuyerBrowseState();
}

class _BuyerBrowseState extends State<_BuyerBrowse> {
  String _selected = 'All';
  final _types = [
    'All',
    'Nile Perch',
    'Tilapia',
    'Catfish',
    'Lungfish',
    'Elephant Snout',
  ];

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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Browse Fish',
                                style: AppTextStyles.ui(18,
                                    weight: FontWeight.w800)),
                            Text('AVAILABLE LISTINGS',
                                style: AppTextStyles.label(10,
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _types.map((t) {
                        final active = t == _selected;
                        return GestureDetector(
                          onTap: () => setState(() => _selected = t),
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
                            child: Text(t,
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
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.set_meal_outlined,
                          size: 32, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('No listings yet',
                        style: AppTextStyles.ui(15, weight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Fish listings from traders\nwill appear here.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.ui(13,
                          color: AppColors.onSurfaceVariant, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
