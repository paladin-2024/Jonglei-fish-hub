import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class _Species {
  final String name;
  final String localName;
  final String dinkaName;
  final String arabicName;
  final String avgPrice;      // per kg
  final String season;
  final String habitat;
  final String description;
  final Color accentColor;
  final IconData icon;
  final List<_NutritionalFact> nutrition;

  const _Species({
    required this.name,
    required this.localName,
    required this.dinkaName,
    required this.arabicName,
    required this.avgPrice,
    required this.season,
    required this.habitat,
    required this.description,
    required this.accentColor,
    required this.icon,
    required this.nutrition,
  });
}

class _NutritionalFact {
  final String label;
  final String value;
  const _NutritionalFact(this.label, this.value);
}

const _speciesList = [
  _Species(
    name: 'Nile Perch',
    localName: 'Nile Perch',
    dinkaName: 'Atiep',
    arabicName: 'قاروص النيل',
    avgPrice: 'SSP 450–620',
    season: 'Year-round, peak Oct–Feb',
    habitat: 'White Nile, Sudd wetlands',
    description:
        'The dominant commercial species of the Jonglei region. Large, white-fleshed predator with firm, mild meat. Highly valued in Juba and export markets.',
    accentColor: Color(0xFF005440),
    icon: Icons.set_meal_rounded,
    nutrition: [
      _NutritionalFact('Protein', '19.4g / 100g'),
      _NutritionalFact('Fat', '0.9g / 100g'),
      _NutritionalFact('Calories', '89 kcal'),
      _NutritionalFact('Omega-3', 'Moderate'),
    ],
  ),
  _Species(
    name: 'Nile Tilapia',
    localName: 'Tilapia',
    dinkaName: 'Achuk',
    arabicName: 'بلطي نيلي',
    avgPrice: 'SSP 300–480',
    season: 'Year-round, peak Mar–Jun',
    habitat: 'Lakes, rivers, seasonal floodplains',
    description:
        'Hardy, fast-growing cichlid. The most accessible fish for subsistence fishers. Mild flavour, suitable for drying and smoking.',
    accentColor: Color(0xFF1E5C8A),
    icon: Icons.set_meal_rounded,
    nutrition: [
      _NutritionalFact('Protein', '20.1g / 100g'),
      _NutritionalFact('Fat', '1.7g / 100g'),
      _NutritionalFact('Calories', '96 kcal'),
      _NutritionalFact('Omega-3', 'Low–Moderate'),
    ],
  ),
  _Species(
    name: 'African Catfish',
    localName: 'Catfish',
    dinkaName: 'Adhieu',
    arabicName: 'سمك القرموط',
    avgPrice: 'SSP 280–400',
    season: 'May–September (rainy season)',
    habitat: 'Muddy river bottoms, swamps',
    description:
        'Bottom-dwelling omnivore. Tolerant of low-oxygen waters. Prized smoked whole along trade corridors from Bor to Malakal.',
    accentColor: Color(0xFFB45309),
    icon: Icons.set_meal_rounded,
    nutrition: [
      _NutritionalFact('Protein', '17.2g / 100g'),
      _NutritionalFact('Fat', '4.3g / 100g'),
      _NutritionalFact('Calories', '116 kcal'),
      _NutritionalFact('Omega-3', 'Moderate'),
    ],
  ),
  _Species(
    name: 'African Lungfish',
    localName: 'Lungfish',
    dinkaName: 'Acuil',
    arabicName: 'السمكة الرئوية',
    avgPrice: 'SSP 220–350',
    season: 'Dry season (Nov–Apr)',
    habitat: 'Seasonal pools, Sudd margins',
    description:
        'Ancient air-breathing fish that can survive droughts in mud cocoons. Seasonal delicacy with a strong, rich flavour. Important food security species.',
    accentColor: Color(0xFF1A6B3C),
    icon: Icons.set_meal_rounded,
    nutrition: [
      _NutritionalFact('Protein', '16.8g / 100g'),
      _NutritionalFact('Fat', '5.1g / 100g'),
      _NutritionalFact('Calories', '118 kcal'),
      _NutritionalFact('Omega-3', 'High'),
    ],
  ),
  _Species(
    name: 'Yellowfish',
    localName: 'Yellowfish',
    dinkaName: 'Aweidit',
    arabicName: 'السمكة الصفراء',
    avgPrice: 'SSP 180–280',
    season: 'March–July',
    habitat: 'Fast-flowing Nile tributaries',
    description:
        'Small to medium redfin yellowfish related to the carp family. Popular dried and as a protein supplement in rural markets along the Sobat River.',
    accentColor: Color(0xFFCA8A04),
    icon: Icons.set_meal_rounded,
    nutrition: [
      _NutritionalFact('Protein', '18.0g / 100g'),
      _NutritionalFact('Fat', '2.2g / 100g'),
      _NutritionalFact('Calories', '94 kcal'),
      _NutritionalFact('Omega-3', 'Low'),
    ],
  ),
  _Species(
    name: 'Mudfish',
    localName: 'Mudfish',
    dinkaName: 'Thok',
    arabicName: 'سمكة الطين',
    avgPrice: 'SSP 160–240',
    season: 'Wet season, June–October',
    habitat: 'Floodplain pools, rice paddies',
    description:
        'Small, dark-fleshed fish abundant during flood season. Economically important as a low-cost protein source. Commonly sun-dried and traded in bulk.',
    accentColor: Color(0xFF7A8C87),
    icon: Icons.set_meal_rounded,
    nutrition: [
      _NutritionalFact('Protein', '15.4g / 100g'),
      _NutritionalFact('Fat', '3.8g / 100g'),
      _NutritionalFact('Calories', '102 kcal'),
      _NutritionalFact('Omega-3', 'Low'),
    ],
  ),
];

class FishEncyclopediaScreen extends StatefulWidget {
  const FishEncyclopediaScreen({super.key});

  @override
  State<FishEncyclopediaScreen> createState() => _FishEncyclopediaScreenState();
}

class _FishEncyclopediaScreenState extends State<FishEncyclopediaScreen> {
  String _query = '';
  final _controller = TextEditingController();

  List<_Species> get _filtered => _query.isEmpty
      ? _speciesList
      : _speciesList
          .where((s) =>
              s.name.toLowerCase().contains(_query.toLowerCase()) ||
              s.dinkaName.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDetail(_Species sp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpeciesDetail(species: sp),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FISH ENCYCLOPEDIA',
                      style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
                  const SizedBox(height: 4),
                  Text('Jonglei Species Guide',
                      style: AppTextStyles.display(22)),
                  const SizedBox(height: 14),
                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighest,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 14),
                          child: Icon(Icons.search_rounded,
                              size: 18, color: AppColors.onSurfaceFaint),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Search species or Dinka name…',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              filled: false,
                            ),
                            style: AppTextStyles.ui(14),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 16, color: AppColors.onSurfaceFaint),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grid
          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.88,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _SpeciesCard(
                  species: _filtered[i],
                  onTap: () => _showDetail(_filtered[i]),
                ),
                childCount: _filtered.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  final _Species species;
  final VoidCallback onTap;
  const _SpeciesCard({required this.species, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent top bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: species.accentColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.card)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: species.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(species.icon, size: 24, color: species.accentColor),
                  ),
                  const SizedBox(height: 12),
                  Text(species.name,
                      style: AppTextStyles.ui(14, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(species.dinkaName,
                      style: AppTextStyles.label(11,
                          color: species.accentColor, weight: FontWeight.w600)),
                  const Spacer(),
                  const SizedBox(height: 8),
                  Text(species.avgPrice,
                      style: AppTextStyles.data(12,
                          weight: FontWeight.w600, color: AppColors.primary)),
                  Text('/ kg avg',
                      style: AppTextStyles.label(9,
                          color: AppColors.onSurfaceFaint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesDetail extends StatelessWidget {
  final _Species species;
  const _SpeciesDetail({required this.species});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.zero,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Top accent
            Container(
              height: 3,
              margin: const EdgeInsets.only(top: 8),
              color: species.accentColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: species.accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(species.icon,
                            size: 28, color: species.accentColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(species.name,
                                style: AppTextStyles.display(22)),
                            Text(
                                '${species.dinkaName}  ·  ${species.arabicName}',
                                style: AppTextStyles.label(11,
                                    color: AppColors.onSurfaceFaint)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(species.description,
                      style: AppTextStyles.ui(14,
                          color: AppColors.onSurfaceVariant, height: 1.6)),

                  const SizedBox(height: 20),

                  // Meta chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                          Icons.attach_money_rounded, species.avgPrice),
                      _MetaChip(Icons.calendar_today_rounded, species.season),
                      _MetaChip(Icons.water_rounded, species.habitat),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text('NUTRITIONAL PROFILE',
                      style: AppTextStyles.label(10,
                          color: AppColors.onSurfaceFaint)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Column(
                      children: species.nutrition.asMap().entries.map((e) {
                        final isLast = e.key == species.nutrition.length - 1;
                        return _NutriRow(
                            fact: e.value,
                            isLast: isLast,
                            accent: species.accentColor);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label,
              style:
                  AppTextStyles.ui(12, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _NutriRow extends StatelessWidget {
  final _NutritionalFact fact;
  final bool isLast;
  final Color accent;
  const _NutriRow(
      {required this.fact, required this.isLast, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surfaceHigh, width: 1)),
      ),
      child: Row(
        children: [
          Text(fact.label,
              style: AppTextStyles.ui(13,
                  color: AppColors.onSurfaceVariant)),
          const Spacer(),
          Text(fact.value,
              style: AppTextStyles.data(13,
                  weight: FontWeight.w600, color: accent)),
        ],
      ),
    );
  }
}
