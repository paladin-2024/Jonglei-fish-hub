import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    _CityPrices('RENK', 'UPPER NILE STATE', [
      _FishPrice('Nile Perch', 3100, 60),
      _FishPrice('Tilapia', 1600, 20),
      _FishPrice('Catfish', 980, -15),
    ]),
    _CityPrices('AWEIL', 'NORTHERN BAR EL GHAZAL', [
      _FishPrice('Nile Perch', 2600, 0),
      _FishPrice('Tilapia', 1400, -30),
      _FishPrice('Catfish', 1050, 10),
    ]),
  ];

  List<_CityPrices> _cities = [];
  bool _loading = true;

  // Group by species: each species card expands to show per-city prices
  Map<String, List<_SpeciesCity>> get _bySpecies {
    final map = <String, List<_SpeciesCity>>{};
    for (final city in _cities) {
      for (final fp in city.prices) {
        map.putIfAbsent(fp.fish, () => []);
        map[fp.fish]!.add(_SpeciesCity(city.city, city.region, fp.price, fp.delta));
      }
    }
    return map;
  }

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
    } catch (_) {}
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
    final speciesMap = _bySpecies;
    final speciesList = speciesMap.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: AmbientBackground(
        child: CustomScrollView(
          slivers: [
            // ── LIVE MARKET PRICES banner ───────────────────────────────────
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
                    18, MediaQuery.of(context).padding.top + 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE MARKET PRICES',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 26,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text('REAL-TIME CITY LEDGER — JONGLEI STATE',
                              style: AppTextStyles.label(9,
                                  color: AppColors.textMuted)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                              Text('LIVE · 09:12 CAT',
                                  style: AppTextStyles.label(8,
                                      color: AppColors.success,
                                      weight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Market health footer ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _HealthStat('MARKET', 'Stable →', AppColors.success),
                      Container(
                          width: 1, height: 32, color: AppColors.border),
                      _HealthStat('AVG. DEVIATION', '+12.4%', AppColors.secondary),
                      Container(
                          width: 1, height: 32, color: AppColors.border),
                      _HealthStat('ACTIVE NODES', '248', AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Species-grouped expandable cards ────────────────────────────
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ShimmerCard(),
                    ),
                    childCount: 3,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SpeciesCard(
                        species: speciesList[i],
                        cities: speciesMap[speciesList[i]]!,
                      ),
                    ),
                    childCount: speciesList.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─── Species expandable card ──────────────────────────────────────────────────
class _SpeciesCard extends StatefulWidget {
  final String species;
  final List<_SpeciesCity> cities;
  const _SpeciesCard({required this.species, required this.cities});

  @override
  State<_SpeciesCard> createState() => _SpeciesCardState();
}

class _SpeciesCardState extends State<_SpeciesCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _chevron;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _chevron = Tween<double>(begin: 0, end: 0.5).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  // Compute max price city for header display
  _SpeciesCity get _topCity =>
      widget.cities.reduce((a, b) => a.price > b.price ? a : b);

  Color _priceColor(int price, int maxPrice) {
    if (price >= maxPrice * 0.85) return AppColors.primary;
    if (price >= maxPrice * 0.6) return AppColors.secondary;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final maxPrice = widget.cities
        .map((c) => c.price)
        .reduce((a, b) => a > b ? a : b);

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // Accent top bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.card)),
              ),
            ),

            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
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
                        Text(widget.species,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 18,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            )),
                        const SizedBox(height: 2),
                        Text('${widget.cities.length} MARKETS',
                            style: AppTextStyles.label(9,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  // High price preview
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('SSP ${_topCity.price}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          )),
                      Text(_topCity.city,
                          style: AppTextStyles.label(9,
                              color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns: _chevron,
                    child: const Icon(Icons.expand_more_rounded,
                        color: AppColors.textSecondary, size: 22),
                  ),
                ],
              ),
            ),

            // Expanded city rows
            if (_expanded) ...[
              Container(
                height: 1,
                color: AppColors.border,
              ),
              ...widget.cities.map((c) {
                final col = _priceColor(c.price, maxPrice);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: widget.cities.last != c
                        ? const Border(
                            bottom:
                                BorderSide(color: AppColors.border))
                        : null,
                  ),
                  child: Row(
                    children: [
                      // City chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.bgGlass,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(c.city,
                            style: AppTextStyles.label(9,
                                color: AppColors.textSecondary,
                                weight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c.region,
                            style: AppTextStyles.ui(10,
                                color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis),
                      ),
                      // Price
                      Text('SSP ${c.price}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: col,
                          )),
                      const SizedBox(width: 8),
                      // Delta
                      if (c.delta != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.delta > 0
                                ? AppColors.successLight
                                : AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            c.delta > 0
                                ? '+${c.delta}'
                                : '${c.delta}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: c.delta > 0
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 34),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Health stat widget ───────────────────────────────────────────────────────
class _HealthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HealthStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: AppTextStyles.label(8, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.data(13,
                  weight: FontWeight.w700, color: color)),
        ],
      );
}

// ─── Data models ──────────────────────────────────────────────────────────────
class _CityPrices {
  final String city;
  final String region;
  final List<_FishPrice> prices;
  const _CityPrices(this.city, this.region, this.prices);
}

class _FishPrice {
  final String fish;
  final int price;
  final int delta;
  const _FishPrice(this.fish, this.price, this.delta);
}

class _SpeciesCity {
  final String city;
  final String region;
  final int price;
  final int delta;
  const _SpeciesCity(this.city, this.region, this.price, this.delta);
}
