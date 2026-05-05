import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_theme.dart';

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
  FishMarket(name: 'Juba Central Fish Market', city: 'Juba',     position: LatLng(4.859, 31.571),  type: 'major',   description: 'Largest fish trading hub in South Sudan. Open daily.',    fish: 'Nile Perch, Tilapia, Catfish'),
  FishMarket(name: 'Bor Fish Market',           city: 'Bor',      position: LatLng(6.207, 31.560),  type: 'major',   description: 'Main market in Jonglei state capital. White Nile access.', fish: 'Nile Perch, Lungfish, Tilapia'),
  FishMarket(name: 'Malakal Fish Landing',      city: 'Malakal',  position: LatLng(9.533, 31.650),  type: 'landing', description: 'Key landing site on the White Nile. Major transit point.',  fish: 'Nile Perch, Elephant Snout, Tilapia'),
  FishMarket(name: 'Renk Trading Post',         city: 'Renk',     position: LatLng(11.750, 32.790), type: 'trading', description: 'Northern corridor trading post linking to Sudan.',           fish: 'Catfish, Nile Perch'),
  FishMarket(name: 'Fangak Landing',            city: 'Fangak',   position: LatLng(8.520, 30.850),  type: 'landing', description: 'Sudd wetlands fishing site. Rich seasonal fishery.',         fish: 'Tilapia, Lungfish, Catfish'),
  FishMarket(name: 'Pibor Market',              city: 'Pibor',    position: LatLng(6.793, 33.127),  type: 'local',   description: 'Eastern Jonglei local trading point.',                      fish: 'Catfish, Tilapia'),
];

const _typeColors = {
  'major':   Color(0xFF0F766E),
  'landing': Color(0xFF0369A1),
  'trading': Color(0xFFB45309),
  'local':   Color(0xFF7C3AED),
};

// Transport route polylines
const _routePoints = [
  [LatLng(4.859, 31.571), LatLng(6.207, 31.560)],   // Juba → Bor
  [LatLng(6.207, 31.560), LatLng(9.533, 31.650)],   // Bor → Malakal
  [LatLng(9.533, 31.650), LatLng(11.750, 32.790)],  // Malakal → Renk
  [LatLng(6.207, 31.560), LatLng(6.793, 33.127)],   // Bor → Pibor
  [LatLng(8.520, 30.850), LatLng(9.533, 31.650)],   // Fangak → Malakal
];

class MarketMapScreen extends StatefulWidget {
  final bool showRoutes;
  const MarketMapScreen({super.key, this.showRoutes = false});

  @override
  State<MarketMapScreen> createState() => _MarketMapScreenState();
}

class _MarketMapScreenState extends State<MarketMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  FishMarket? _selected;

  static const _initialCamera = CameraPosition(
    target: LatLng(7.5, 31.8),
    zoom: 6.2,
  );

  Set<Marker> get _markers => _markets.map((m) {
    final isSelected = _selected == m;
    return Marker(
      markerId: MarkerId(m.name),
      position: m.position,
      icon: isSelected
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
          : BitmapDescriptor.defaultMarkerWithHue(
              m.type == 'major'   ? BitmapDescriptor.hueGreen  :
              m.type == 'landing' ? BitmapDescriptor.hueCyan   :
              m.type == 'trading' ? BitmapDescriptor.hueOrange :
                                    BitmapDescriptor.hueViolet),
      infoWindow: InfoWindow(
        title: m.name,
        snippet: m.fish,
      ),
      onTap: () async {
        setState(() => _selected = _selected == m ? null : m);
        final ctrl = await _controller.future;
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(m.position, 9.0));
      },
    );
  }).toSet();

  Set<Polyline> get _polylines {
    if (!widget.showRoutes) return {};
    return _routePoints.asMap().entries.map((e) => Polyline(
      polylineId: PolylineId('route_${e.key}'),
      points: e.value,
      color: AppColors.primary.withValues(alpha: 0.55),
      width: 3,
      patterns: [PatternItem.dash(20), PatternItem.gap(8)],
    )).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            onMapCreated: (ctrl) => _controller.complete(ctrl),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            mapType: MapType.normal,
            onTap: (_) => setState(() => _selected = null),
          ),

          // Legend top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('FISH MARKETS',
                      style: AppTextStyles.label(9,
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  const _LegendRow(color: Color(0xFF0F766E), label: 'Major'),
                  const _LegendRow(color: Color(0xFF0369A1), label: 'Landing'),
                  const _LegendRow(color: Color(0xFFB45309), label: 'Trading'),
                  const _LegendRow(color: Color(0xFF7C3AED), label: 'Local'),
                ],
              ),
            ),
          ),

          // Zoom + centre controls top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.add,
                  onTap: () async {
                    final ctrl = await _controller.future;
                    final zoom = await ctrl.getZoomLevel();
                    ctrl.animateCamera(CameraUpdate.zoomTo(zoom + 1));
                  },
                ),
                const SizedBox(height: 4),
                _MapButton(
                  icon: Icons.remove,
                  onTap: () async {
                    final ctrl = await _controller.future;
                    final zoom = await ctrl.getZoomLevel();
                    ctrl.animateCamera(CameraUpdate.zoomTo(zoom - 1));
                  },
                ),
                const SizedBox(height: 4),
                _MapButton(
                  icon: Icons.center_focus_strong_rounded,
                  onTap: () async {
                    final ctrl = await _controller.future;
                    ctrl.animateCamera(
                        CameraUpdate.newCameraPosition(_initialCamera));
                    setState(() => _selected = null);
                  },
                ),
              ],
            ),
          ),

          // Market detail card at bottom
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        ),
      );
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.ui(10,
                    color: AppColors.onSurfaceVariant)),
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
    final color = _typeColors[market.type] ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.storefront_rounded,
                          color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(market.name,
                              style: AppTextStyles.ui(14,
                                  weight: FontWeight.w700)),
                          Text(market.city,
                              style: AppTextStyles.label(11,
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(market.description,
                    style: AppTextStyles.ui(12,
                        color: AppColors.onSurfaceVariant, height: 1.4)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.set_meal_outlined,
                        size: 13, color: AppColors.onSurfaceFaint),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(market.fish,
                          style: AppTextStyles.ui(12,
                              color: AppColors.onSurfaceVariant,
                              weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
