import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_box.dart';

class PricesScreen extends StatefulWidget {
  const PricesScreen({super.key});

  @override
  State<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<PricesScreen> {
  static const _staticCities = [
    _CityPrices('BOR', 'JONGLEI STATE', [
      _FishPrice('Nile Perch', 2450, 80),
      _FishPrice('Tilapia', 1800, -20),
      _FishPrice('Catfish', 1200, 0),
    ]),
    _CityPrices('JUBA', 'CENTRAL EQUATORIA', [
      _FishPrice('Nile Perch', 3200, 150),
      _FishPrice('Tilapia', 2000, -50),
      _FishPrice('Catfish', 1900, 100),
    ]),
    _CityPrices('WAU', 'WESTERN BAR EL GHAZAL', [
      _FishPrice('Nile Perch', 2800, -30),
      _FishPrice('Tilapia', 1500, 0),
      _FishPrice('Catfish', 1100, 60),
    ]),
    _CityPrices('MALAKAL', 'UPPER NILE STATE', [
      _FishPrice('Nile Perch', 3500, 200),
      _FishPrice('Tilapia', 1700, -40),
      _FishPrice('Catfish', 1050, 0),
    ]),
  ];

  List<_CityPrices> _cities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCached().then((_) => _fetchPrices());
  }

  Future<void> _loadCached() async {
    try {
      final box = await Hive.openBox('jonglei_cache');
      final raw = box.get('prices');
      if (raw != null) {
        final cached = jsonDecode(raw as String) as List;
        if (mounted) {
          setState(() {
            _cities = _parseCities(cached);
            _loading = false;
          });
        }
      }
    } catch (_) {
      // Cache miss — continue to fetch
    }
  }

  Future<void> _fetchPrices() async {
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.get('/marketplace/prices/');
      final list = data is List ? data : (data['results'] as List? ?? []);
      final parsed = _parseCities(list);
      final box = await Hive.openBox('jonglei_cache');
      await box.put('prices', jsonEncode(list));
      if (mounted) {
        setState(() {
          _cities = parsed;
          _loading = false;
        });
      }
    } catch (_) {
      // Fall back to static data if API fails and no cached data
      if (mounted && _cities.isEmpty) {
        setState(() {
          _cities = _staticCities;
          _loading = false;
        });
      }
    }
  }

  List<_CityPrices> _parseCities(List<dynamic> data) {
    return data.map((item) {
      final city = (item['city'] as String? ?? '').toUpperCase();
      final region = (item['region'] as String? ?? '').toUpperCase();
      final pricesList = (item['prices'] as List? ?? []).map((p) {
        return _FishPrice(
          p['species'] as String? ?? '',
          (p['price_ssp'] as num? ?? 0).toInt(),
          (p['delta'] as num? ?? 0).toInt(),
        );
      }).toList();
      return _CityPrices(city, region, pricesList);
    }).toList();
  }

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
                  18, MediaQuery.of(context).padding.top + 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Market Price Ledger',
                                style: AppTextStyles.ui(18,
                                    weight: FontWeight.w800)),
                            Text('REAL-TIME CITY LEDGER',
                                style: AppTextStyles.label(10,
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('UPDATE PRICES',
                            style: AppTextStyles.label(10,
                                color: Colors.white, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.circle,
                          size: 8, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text('Last Global Sync: 09:12 CAT',
                          style: AppTextStyles.ui(11,
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, _) => const ShimmerCard(),
                  childCount: 4,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _CityCard(city: _cities[i]),
                  childCount: _cities.length,
                ),
              ),
            ),

          // Market health footer
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _HealthStat('MARKET HEALTH', 'Stable →', AppColors.success),
                  Container(width: 1, height: 32, color: AppColors.surfaceHigh),
                  _HealthStat('AVG. DEVIATION', '+12.4%', AppColors.secondary),
                  Container(width: 1, height: 32, color: AppColors.surfaceHigh),
                  _HealthStat('ACTIVE NODES', '248', AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityPrices {
  final String city;
  final String region;
  final List<_FishPrice> prices;
  const _CityPrices(this.city, this.region, this.prices);
}

class _FishPrice {
  final String fish;
  final int price;
  final int delta; // SSP change
  const _FishPrice(this.fish, this.price, this.delta);
}

class _CityCard extends StatelessWidget {
  final _CityPrices city;
  const _CityCard({required this.city});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city.city,
                    style: AppTextStyles.label(11,
                        color: AppColors.primary, weight: FontWeight.w800)),
                Text(city.region,
                    style: AppTextStyles.label(8,
                        color: AppColors.onSurfaceFaint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                ...city.prices.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(p.fish,
                                style: AppTextStyles.ui(11,
                                    color: AppColors.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('SSP ${p.price}',
                                  style: AppTextStyles.data(12,
                                      weight: FontWeight.w600,
                                      color: AppColors.onSurface)),
                              if (p.delta != 0)
                                Text(
                                  p.delta > 0 ? '+${p.delta}' : '${p.delta}',
                                  style: AppTextStyles.data(9,
                                      color: p.delta > 0
                                          ? AppColors.success
                                          : AppColors.danger),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 4),
                Text('UPDATED 1H AGO',
                    style: AppTextStyles.label(8,
                        color: AppColors.onSurfaceFaint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HealthStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: AppTextStyles.label(8, color: AppColors.onSurfaceFaint)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.data(13,
                  weight: FontWeight.w700, color: color)),
        ],
      );
}
