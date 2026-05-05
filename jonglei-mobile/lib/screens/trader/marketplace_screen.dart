import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../buyer/order_placement_sheet.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _stateFilter = 'ALL STATES';
  String _fishFilter = 'ALL FISH';
  final _searchCtrl = TextEditingController();

  List<_Listing> _listings = const [];
  bool _loading = true;

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
      final raw = await api.get('/marketplace/listings/?status=ACTIVE') as List;
      if (mounted) {
        setState(() {
          _listings = raw
              .map((j) => _Listing.fromJson(j as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<_Listing> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    return _listings.where((l) {
      if (q.isNotEmpty &&
          !l.fish.toLowerCase().contains(q) &&
          !l.seller.toLowerCase().contains(q) &&
          !l.location.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + 12, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Jonglei Fish Hub',
                          style: AppTextStyles.ui(16, weight: FontWeight.w800,
                              color: AppColors.primary)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        color: AppColors.onSurfaceVariant,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _load,
                        tooltip: 'Refresh listings',
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.notifications_outlined,
                          color: AppColors.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search species or region...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.onSurfaceFaint, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    style: AppTextStyles.ui(14),
                  ),
                  const SizedBox(height: 10),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          'ALL STATES',
                          active: _stateFilter == 'ALL STATES',
                          onTap: () =>
                              setState(() => _stateFilter = 'ALL STATES'),
                        ),
                        _FilterChip(
                          'FISH TYPE',
                          active: _fishFilter == 'FISH TYPE',
                          onTap: () =>
                              setState(() => _fishFilter = 'FISH TYPE'),
                        ),
                        _FilterChip('PRICE RANGE', active: false, onTap: () {}),
                        _FilterChip('QUANTITY', active: false, onTap: () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Listings
          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: _loading
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Container(
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                        ),
                      ),
                      childCount: 3,
                    ),
                  )
                : _filtered.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Center(
                            child: Text(
                              'No listings found',
                              style: AppTextStyles.ui(14,
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _ListingCard(listing: _filtered[i]),
                          childCount: _filtered.length,
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _Listing {
  final String id;
  final String fish;
  final double rating;
  final int trades;
  final String seller;
  final String location;
  final double quantityKg;
  final double pricePerKg;

  const _Listing({
    required this.id,
    required this.fish,
    required this.rating,
    required this.trades,
    required this.seller,
    required this.location,
    required this.quantityKg,
    required this.pricePerKg,
  });

  factory _Listing.fromJson(Map<String, dynamic> j) {
    final sellerDetail = (j['seller_detail'] as Map?) ?? {};
    return _Listing(
      id: j['id']?.toString() ?? '',
      fish: j['species']?.toString() ?? '—',
      rating:
          double.tryParse(sellerDetail['rating']?.toString() ?? '') ?? 0.0,
      trades: (sellerDetail['total_transactions'] as int?) ?? 0,
      seller: sellerDetail['username']?.toString() ?? '—',
      location: j['location']?.toString() ?? '—',
      quantityKg:
          double.tryParse(j['quantity_kg']?.toString() ?? '') ?? 0,
      pricePerKg:
          double.tryParse(j['price_ssp']?.toString() ?? '') ?? 0,
    );
  }
}

class _ListingCard extends StatelessWidget {
  final _Listing listing;
  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.fish,
                          style: AppTextStyles.ui(16, weight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: AppColors.secondary),
                          const SizedBox(width: 3),
                          Text(
                              '${listing.rating} (${listing.trades} Trades)',
                              style: AppTextStyles.ui(12,
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('PRICE / KG',
                        style: AppTextStyles.label(9,
                            color: AppColors.onSurfaceFaint)),
                    Text(
                      'SSP ${listing.pricePerKg.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      style: AppTextStyles.data(18,
                          weight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${listing.seller} · ${listing.location}',
                    style: AppTextStyles.ui(12,
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Quantity: ${listing.quantityKg.toStringAsFixed(0)} KG',
                    style: AppTextStyles.ui(12,
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => OrderPlacementSheet(
                    listingId: listing.id,
                    species: listing.fish,
                    maxQty: listing.quantityKg,
                    pricePerUnit: listing.pricePerKg,
                    unit: 'KG',
                    seller: listing.seller,
                    location: listing.location,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('REQUEST PURCHASE',
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(this.label, {required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.secondaryLight : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: AppTextStyles.label(11,
                  color: active
                      ? AppColors.secondary
                      : AppColors.onSurfaceVariant,
                  weight: FontWeight.w700)),
        ),
      );
}
