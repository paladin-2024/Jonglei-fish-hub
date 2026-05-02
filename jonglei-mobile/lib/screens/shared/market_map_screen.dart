import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FishMarket {
  final String name;
  final String city;
  final LatLng position;
  final String type;
  final String description;
  final String fish;

  const FishMarket({
    required this.name,
    required this.city,
    required this.position,
    required this.type,
    required this.description,
    required this.fish,
  });
}

const _markets = [
  FishMarket(
    name: 'Juba Central Fish Market',
    city: 'Juba',
    position: LatLng(4.859, 31.571),
    type: 'major',
    description: 'Largest fish trading hub in South Sudan. Open daily.',
    fish: 'Nile Perch, Tilapia, Catfish',
  ),
  FishMarket(
    name: 'Bor Fish Market',
    city: 'Bor',
    position: LatLng(6.207, 31.560),
    type: 'major',
    description: 'Main market in Jonglei state capital. White Nile access.',
    fish: 'Nile Perch, Lungfish, Tilapia',
  ),
  FishMarket(
    name: 'Malakal Fish Landing',
    city: 'Malakal',
    position: LatLng(9.533, 31.650),
    type: 'landing',
    description: 'Key landing site on the White Nile. Major transit point.',
    fish: 'Nile Perch, Elephant Snout, Tilapia',
  ),
  FishMarket(
    name: 'Renk Trading Post',
    city: 'Renk',
    position: LatLng(11.750, 32.790),
    type: 'trading',
    description: 'Northern corridor trading post linking to Sudan.',
    fish: 'Catfish, Nile Perch',
  ),
  FishMarket(
    name: 'Fangak Landing',
    city: 'Fangak',
    position: LatLng(8.520, 30.850),
    type: 'landing',
    description: 'Sudd wetlands fishing site. Rich seasonal fishery.',
    fish: 'Tilapia, Lungfish, Catfish',
  ),
  FishMarket(
    name: 'Pibor Market',
    city: 'Pibor',
    position: LatLng(6.793, 33.127),
    type: 'local',
    description: 'Eastern Jonglei local trading point.',
    fish: 'Catfish, Tilapia',
  ),
];

const _typeColors = {
  'major':   Color(0xFF0F766E),
  'landing': Color(0xFF0369A1),
  'trading': Color(0xFFF59E0B),
  'local':   Color(0xFF7C3AED),
};

class MarketMapScreen extends StatefulWidget {
  final bool showRoutes;
  const MarketMapScreen({super.key, this.showRoutes = false});

  @override
  State<MarketMapScreen> createState() => _MarketMapScreenState();
}

class _MarketMapScreenState extends State<MarketMapScreen> {
  FishMarket? _selected;
  final MapController _mapController = MapController();

  // Transport routes (polylines)
  static const _routes = [
    [LatLng(4.859, 31.571), LatLng(6.207, 31.560)],  // Juba → Bor
    [LatLng(6.207, 31.560), LatLng(9.533, 31.650)],  // Bor → Malakal
    [LatLng(9.533, 31.650), LatLng(11.750, 32.790)], // Malakal → Renk
    [LatLng(6.207, 31.560), LatLng(6.793, 33.127)],  // Bor → Pibor
    [LatLng(8.520, 30.850), LatLng(9.533, 31.650)],  // Fangak → Malakal
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(7.5, 31.8),
              initialZoom: 6.2,
              minZoom: 4,
              maxZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jonglei.fish_hub',
                tileBuilder: (context, child, tile) => child,
              ),

              // Route polylines (for transporter view)
              if (widget.showRoutes)
                PolylineLayer(
                  polylines: _routes.map((pts) => Polyline(
                    points: pts,
                    color: const Color(0xFF0F766E),
                    strokeWidth: 2.5,
                    pattern: StrokePattern.dashed(segments: const [10, 6]),
                  )).toList(),
                ),

              // Market markers
              MarkerLayer(
                markers: _markets.map((m) {
                  final color = _typeColors[m.type] ?? const Color(0xFF0F766E);
                  final isSelected = _selected == m;
                  return Marker(
                    point: m.position,
                    width: isSelected ? 52 : 44,
                    height: isSelected ? 52 : 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selected = _selected == m ? null : m);
                        _mapController.move(m.position, 9.0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: isSelected ? 12 : 6,
                              spreadRadius: isSelected ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.set_meal_rounded,
                          size: isSelected ? 24 : 20,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Legend top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Fish Markets', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0D1A19))),
                  SizedBox(height: 6),
                  _LegendRow(color: Color(0xFF0F766E), label: 'Major'),
                  _LegendRow(color: Color(0xFF0369A1), label: 'Landing'),
                  _LegendRow(color: Color(0xFFF59E0B), label: 'Trading'),
                  _LegendRow(color: Color(0xFF7C3AED), label: 'Local'),
                ],
              ),
            ),
          ),

          // Zoom controls top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: Column(
              children: [
                _MapButton(icon: Icons.add, onTap: () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                }),
                const SizedBox(height: 4),
                _MapButton(icon: Icons.remove, onTap: () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                }),
                const SizedBox(height: 4),
                _MapButton(icon: Icons.center_focus_strong_rounded, onTap: () {
                  _mapController.move(const LatLng(7.5, 31.8), 6.2);
                  setState(() => _selected = null);
                }),
              ],
            ),
          ),

          // Market detail bottom sheet
          if (_selected != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _MarketCard(
                market: _selected!,
                onClose: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF374151)),
        ),
      );
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
          ],
        ),
      );
}

class _MarketCard extends StatelessWidget {
  final FishMarket market;
  final VoidCallback onClose;
  const _MarketCard({required this.market, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[market.type] ?? const Color(0xFF0F766E);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.set_meal_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(market.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D1A19))),
                    Text(market.city,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7A9B98))),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(market.description,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.set_meal_outlined, size: 13, color: Color(0xFF7A9B98)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(market.fish,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4D6B69), fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
