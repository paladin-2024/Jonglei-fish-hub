import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rating_stars.dart';
import '../shared/chat_screen.dart';
import 'order_placement_sheet.dart';

class _Listing {
  final String id;
  final String species;
  final double qty;
  final String unit;
  final double price;
  final String location;
  final String seller;
  final String sellerId;
  final String status;
  final double sellerRating;
  final int sellerRatingCount;
  final String photoUrl;

  const _Listing(this.id, this.species, this.qty, this.unit, this.price,
      this.location, this.seller, this.sellerId, this.status,
      {this.sellerRating = 0.0, this.sellerRatingCount = 0, this.photoUrl = ''});
}

const _sampleListings = <_Listing>[];

const _speciesColors = {
  'Nile Perch':         Color(0xFF005440),
  'Tilapia':            Color(0xFF1E5C8A),
  'Catfish':            Color(0xFF6B4226),
  'Lungfish':           Color(0xFF4A7C59),
  'Nile Perch (Smoked)': Color(0xFF92400E),
  'Tilapia (Smoked)':   Color(0xFF1A4A6B),
};

class BrowseListingsScreen extends StatefulWidget {
  const BrowseListingsScreen({super.key});

  @override
  State<BrowseListingsScreen> createState() => _BrowseListingsScreenState();
}

class _BrowseListingsScreenState extends State<BrowseListingsScreen> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<_Listing> _listings = [];
  bool _loading = true;

  static const _types = [
    'All', 'Nile Perch', 'Tilapia', 'Catfish', 'Lungfish',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthProvider>().api;
      final raw = await api.getList('/marketplace/listings/?status=ACTIVE');
      if (raw.isNotEmpty && mounted) {
        setState(() {
          _listings = raw.map((j) {
            final sellerDetail = (j['seller_detail'] as Map?) ?? {};
            return _Listing(
              j['id']?.toString() ?? '',
              j['species'] ?? '—',
              double.tryParse(j['quantity_kg']?.toString() ?? '') ?? 0,
              j['unit'] ?? 'KG',
              double.tryParse(j['price_ssp']?.toString() ?? '') ?? 0,
              j['location'] ?? '—',
              sellerDetail['username'] ?? '—',
              sellerDetail['id']?.toString() ?? '',
              j['status'] ?? 'ACTIVE',
              sellerRating: double.tryParse(
                      sellerDetail['avg_rating']?.toString() ?? '') ??
                  0.0,
              sellerRatingCount:
                  (sellerDetail['rating_count'] as int?) ?? 0,
              photoUrl: j['photo_url']?.toString() ?? '',
            );
          }).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<_Listing> get _filtered {
    var list = _listings.where((l) => l.status == 'ACTIVE').toList();
    if (_filter != 'All') {
      list = list.where((l) => l.species.contains(_filter)).toList();
    }
    if (_query.isNotEmpty) {
      list = list.where((l) =>
        l.species.toLowerCase().contains(_query) ||
        l.location.toLowerCase().contains(_query) ||
        l.seller.toLowerCase().contains(_query)).toList();
    }
    return list;
  }

  Future<void> _openPlacement(_Listing listing) async {
    final placed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderPlacementSheet(
        listingId: listing.id,
        species:   listing.species,
        maxQty:    listing.qty,
        pricePerUnit: listing.price,
        unit:      listing.unit,
        seller:    listing.seller,
        location:  listing.location,
      ),
    );
    if (placed == true) _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _colorFor(String species) {
    for (final key in _speciesColors.keys) {
      if (species.contains(key)) return _speciesColors[key]!;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
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
                            Text('Browse Fish',
                                style: AppTextStyles.ui(18,
                                    weight: FontWeight.w800)),
                            Text('AVAILABLE LISTINGS',
                                style: AppTextStyles.label(10,
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${_filtered.length} LIVE',
                            style: AppTextStyles.label(10,
                                color: AppColors.success,
                                weight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: AppTextStyles.ui(14),
                      decoration: InputDecoration(
                        hintText: 'Search species, location, seller…',
                        hintStyle: AppTextStyles.ui(14,
                            color: AppColors.onSurfaceFaint),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 18, color: AppColors.onSurfaceFaint),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _types.map((t) {
                        final active = t == _filter;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = t),
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

          // ── Listing cards ────────────────────────────────────────────────
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _SkeletonCard(),
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
                    Icon(Icons.set_meal_outlined,
                        size: 48, color: AppColors.onSurfaceFaint),
                    const SizedBox(height: 12),
                    Text('No listings found',
                        style: AppTextStyles.ui(15,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final l = _filtered[i];
                    final color = _colorFor(l.species);
                    return GestureDetector(
                      onTap: () => _openPlacement(l),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top accent bar
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppRadius.card)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Species photo or avatar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: l.photoUrl.isNotEmpty
                                            ? Image.network(
                                                l.photoUrl,
                                                width: 44,
                                                height: 44,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _SpeciesAvatar(
                                                        species: l.species,
                                                        color: color),
                                              )
                                            : _SpeciesAvatar(
                                                species: l.species,
                                                color: color),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(l.species,
                                                style: AppTextStyles.ui(
                                                    15,
                                                    weight:
                                                        FontWeight.w800)),
                                            const SizedBox(height: 2),
                                            Text(l.seller,
                                                style: AppTextStyles.ui(
                                                    12,
                                                    color: AppColors
                                                        .onSurfaceVariant)),
                                            const SizedBox(height: 3),
                                            RatingStars(
                                              rating: l.sellerRating,
                                              count: l.sellerRatingCount,
                                              size: 12,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Price chip
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'SSP ${l.price.toStringAsFixed(0)}/${l.unit}',
                                          style: AppTextStyles.data(12,
                                              weight: FontWeight.w700,
                                              color: color),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _Chip(Icons.scale_outlined,
                                          '${l.qty.toStringAsFixed(0)} ${l.unit}'),
                                      const SizedBox(width: 10),
                                      _Chip(Icons.location_on_outlined,
                                          l.location),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            try {
                                              final api = context
                                                  .read<AuthProvider>()
                                                  .api;
                                              final thread = await api.post(
                                                '/messaging/threads/',
                                                {'listing': l.id},
                                              ) as Map<String, dynamic>;
                                              if (context.mounted) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ChatScreen(
                                                      threadId: thread['id']
                                                              ?.toString() ??
                                                          '',
                                                      otherName: l.seller,
                                                      species: l.species,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (_) {}
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.4)),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.chat_bubble_outline_rounded,
                                                    size: 13,
                                                    color: AppColors.primary),
                                                const SizedBox(width: 5),
                                                Text('MESSAGE',
                                                    style: AppTextStyles.label(
                                                        10,
                                                        color: AppColors.primary,
                                                        weight:
                                                            FontWeight.w800)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text('ORDER',
                                                style: AppTextStyles.label(10,
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
                      ),
                    );
                  },
                  childCount: _filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _SpeciesAvatar extends StatelessWidget {
  final String species;
  final Color color;
  const _SpeciesAvatar({required this.species, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Text(species.isNotEmpty ? species[0] : '?',
              style: AppTextStyles.display(18, color: color)),
        ),
      );
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.ui(12,
                  color: AppColors.onSurfaceVariant)),
        ],
      );
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.card)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 14,
                            width: 120,
                            color: AppColors.surfaceHigh),
                        const SizedBox(height: 6),
                        Container(
                            height: 10,
                            width: 80,
                            color: AppColors.surfaceHighest),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
