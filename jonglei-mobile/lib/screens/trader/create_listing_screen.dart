import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _pageController = PageController();
  int _step = 0;

  // Step 1 — Fish details
  final _speciesController  = TextEditingController();
  final _descController     = TextEditingController();
  final _qtyController      = TextEditingController();
  final _priceController    = TextEditingController();
  String _unit = 'KG';

  // Step 2 — Location
  final _locationController = TextEditingController();
  double? _lat;
  double? _lng;

  // Step 3 — Photo
  File? _photoFile;

  bool _submitting = false;

  static const _speciesSuggestions = [
    'Nile Perch', 'Tilapia (Fresh)', 'Tilapia (Smoked)',
    'Catfish', 'Lungfish', 'Nile Perch (Smoked)',
    'Elephant Snout', 'Mudfish',
  ];

  static const _locationSuggestions = [
    'Juba', 'Bor', 'Malakal', 'Renk', 'Fangak',
    'Pibor', 'Panyagoor', 'Twic East', 'Wau',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _speciesController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic);
      setState(() => _step++);
    } else {
      _publish();
    }
  }

  void _back() {
    if (_step > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic);
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _speciesController.text.trim().isNotEmpty &&
            _qtyController.text.trim().isNotEmpty &&
            _priceController.text.trim().isNotEmpty;
      case 1:
        return _locationController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _publish() async {
    setState(() => _submitting = true);
    final api = context.read<AuthProvider>().api;
    try {
      final fields = {
        'species':     _speciesController.text.trim(),
        'description': _descController.text.trim(),
        'quantity_kg': _qtyController.text.trim(),
        'price_ssp':   _priceController.text.trim(),
        'unit':        _unit,
        'location':    _locationController.text.trim(),
        'status':      'ACTIVE',
        if (_lat != null) 'latitude':  _lat.toString(),
        if (_lng != null) 'longitude': _lng.toString(),
      };

      if (_photoFile != null) {
        await api.postMultipart(
          '/marketplace/listings/',
          file: _photoFile!,
          fileField: 'photo',
          fields: fields,
        );
      } else {
        await api.post('/marketplace/listings/', {
          ...fields,
          'quantity_kg': double.parse(_qtyController.text.trim()),
          'price_ssp':   double.parse(_priceController.text.trim()),
        }, requiresAuth: true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Listing published!',
              style: AppTextStyles.ui(13, color: AppColors.surface)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(),
              style: AppTextStyles.ui(13, color: AppColors.surface)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary),
          onPressed: _back,
        ),
        title: Text('New Listing',
            style: AppTextStyles.ui(16, weight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _StepIndicator(current: _step),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1(
                  speciesCtrl: _speciesController,
                  descCtrl: _descController,
                  qtyCtrl: _qtyController,
                  priceCtrl: _priceController,
                  unit: _unit,
                  onUnitChanged: (v) => setState(() => _unit = v),
                  suggestions: _speciesSuggestions,
                ),
                _Step2(
                  locationCtrl: _locationController,
                  suggestions: _locationSuggestions,
                  initialLat: _lat,
                  initialLng: _lng,
                  onCoordsChanged: (lat, lng) => setState(() {
                    _lat = lat;
                    _lng = lng;
                  }),
                ),
                _Step3(
                  photoFile: _photoFile,
                  onPhotoSelected: (f) => setState(() => _photoFile = f),
                ),
                _Step4(
                  species:  _speciesController.text,
                  qty:      _qtyController.text,
                  unit:     _unit,
                  price:    _priceController.text,
                  location: _locationController.text,
                  desc:     _descController.text,
                ),
              ],
            ),
          ),

          // CTA
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _canAdvance && !_submitting ? _next : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.bgDeep,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  disabledBackgroundColor: AppColors.surfaceHigh,
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(
                        _step == 3
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18),
                label: Text(
                  _step == 3 ? 'PUBLISH LISTING' : 'CONTINUE',
                  style: AppTextStyles.ui(14,
                      weight: FontWeight.w700,
                      color: AppColors.bgDeep,
                      letterSpacing: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step indicator ─────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  static const _labels = ['DETAILS', 'LOCATION', 'PHOTO', 'REVIEW'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final done   = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          color: done || active
                              ? AppColors.primary
                              : AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _labels[i],
                        style: AppTextStyles.label(8,
                            color: active
                                ? AppColors.primary
                                : done
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.onSurfaceFaint,
                            weight: active
                                ? FontWeight.w800
                                : FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (i < _labels.length - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Step 1: Fish details ───────────────────────────────────────────────────────
class _Step1 extends StatelessWidget {
  static const _units = ['KG', 'PIECE', 'CRATE', 'BUCKET'];

  final TextEditingController speciesCtrl;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final String unit;
  final ValueChanged<String> onUnitChanged;
  final List<String> suggestions;

  const _Step1({
    required this.speciesCtrl,
    required this.descCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.unit,
    required this.onUnitChanged,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FISH DETAILS',
              style: AppTextStyles.label(11,
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),

          Text('SPECIES', style: AppTextStyles.label(11, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextFormField(
            controller: speciesCtrl,
            style: AppTextStyles.ui(14),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.set_meal_outlined),
              hintText: 'e.g. Nile Perch, Tilapia',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: suggestions.map((s) => GestureDetector(
              onTap: () => speciesCtrl.text = s,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s,
                    style: AppTextStyles.ui(11,
                        color: AppColors.onSurfaceVariant,
                        weight: FontWeight.w600)),
              ),
            )).toList(),
          ),

          const SizedBox(height: 20),

          Text('DESCRIPTION (optional)',
              style: AppTextStyles.label(11, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextFormField(
            controller: descCtrl,
            maxLines: 3,
            style: AppTextStyles.ui(14),
            decoration: const InputDecoration(hintText: 'Freshness, catch method, quality notes…'),
          ),

          const SizedBox(height: 20),

          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QUANTITY', style: AppTextStyles.label(11, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.data(14),
                  decoration: const InputDecoration(hintText: '0'),
                ),
              ],
            )),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UNIT', style: AppTextStyles.label(11, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: unit,
                      style: AppTextStyles.ui(14),
                      items: _Step1._units
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) { if (v != null) onUnitChanged(v); },
                    ),
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 20),

          Text('PRICE (SSP per unit)',
              style: AppTextStyles.label(11, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextFormField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            style: AppTextStyles.data(14),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payments_outlined),
              hintText: '0',
              prefixText: 'SSP  ',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Location (Google Maps + GPS) ──────────────────────────────────────
class _Step2 extends StatefulWidget {
  final TextEditingController locationCtrl;
  final List<String> suggestions;
  final double? initialLat;
  final double? initialLng;
  final void Function(double lat, double lng) onCoordsChanged;

  const _Step2({
    required this.locationCtrl,
    required this.suggestions,
    required this.onCoordsChanged,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<_Step2> createState() => _Step2State();
}

class _Step2State extends State<_Step2> {
  GoogleMapController? _mapCtrl;
  LatLng? _pinned;
  bool _gettingLocation = false;

  // South Sudan geographic center
  static const _defaultCenter = LatLng(7.8699, 29.6667);

  static const _locationCoords = {
    'Juba':       LatLng(4.8594,  31.5713),
    'Bor':        LatLng(6.2108,  31.5590),
    'Malakal':    LatLng(9.5337,  31.6581),
    'Renk':       LatLng(11.7907, 32.7909),
    'Fangak':     LatLng(9.0833,  30.9500),
    'Pibor':      LatLng(6.8031,  33.1318),
    'Panyagoor':  LatLng(7.1167,  30.7333),
    'Twic East':  LatLng(7.4500,  31.5000),
    'Wau':        LatLng(7.7023,  27.9939),
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _pinned = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  Future<void> _useCurrentPosition() async {
    setState(() => _gettingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Location permission denied',
                style: AppTextStyles.ui(13, color: AppColors.bgDeep)),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ));
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _pinned = ll);
      widget.onCoordsChanged(pos.latitude, pos.longitude);
      widget.locationCtrl.text =
          'My Location (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 14));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not get location',
              style: AppTextStyles.ui(13, color: AppColors.bgDeep)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  void _onMapTap(LatLng pos) {
    setState(() => _pinned = pos);
    widget.onCoordsChanged(pos.latitude, pos.longitude);
    final current = widget.locationCtrl.text;
    if (current.isEmpty ||
        current.startsWith('My Location') ||
        current.startsWith('Pin:')) {
      widget.locationCtrl.text =
          'Pin: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    }
  }

  void _selectSuggestion(String name) {
    widget.locationCtrl.text = name;
    final coords = _locationCoords[name];
    if (coords != null) {
      setState(() => _pinned = coords);
      widget.onCoordsChanged(coords.latitude, coords.longitude);
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(coords, 11));
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _pinned ?? _defaultCenter;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PICKUP LOCATION',
              style: AppTextStyles.label(11, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Tap the map to pin a location, or use your GPS position.',
              style: AppTextStyles.ui(13,
                  color: AppColors.onSurfaceFaint, height: 1.4)),
          const SizedBox(height: 14),

          // ── Map ──
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: _pinned != null ? 12 : 6,
                ),
                onMapCreated: (c) => _mapCtrl = c,
                onTap: _onMapTap,
                markers: _pinned != null
                    ? {
                        Marker(
                          markerId: const MarkerId('pin'),
                          position: _pinned!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              162), // teal hue
                        ),
                      }
                    : {},
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                liteModeEnabled: false,
              ),
            ),
          ),

          if (_pinned != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 13, color: AppColors.success),
                const SizedBox(width: 5),
                Text(
                  '${_pinned!.latitude.toStringAsFixed(4)}, ${_pinned!.longitude.toStringAsFixed(4)}',
                  style: AppTextStyles.data(11,
                      color: AppColors.success, weight: FontWeight.w600),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ── GPS button ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _gettingLocation ? null : _useCurrentPosition,
              icon: _gettingLocation
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.my_location_rounded, size: 16),
              label: Text(
                _gettingLocation
                    ? 'Getting Location…'
                    : 'USE MY CURRENT POSITION',
                style: AppTextStyles.ui(13,
                    weight: FontWeight.w700, letterSpacing: 0.4),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Manual text field ──
          Text('OR TYPE A LOCATION NAME',
              style: AppTextStyles.label(10,
                  color: AppColors.onSurfaceFaint)),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.locationCtrl,
            style: AppTextStyles.ui(14),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_outlined),
              hintText: 'e.g. Bor, Malakal, Fangak',
            ),
          ),

          const SizedBox(height: 14),

          // ── Quick select chips ──
          Text('QUICK SELECT',
              style: AppTextStyles.label(10,
                  color: AppColors.onSurfaceFaint)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.suggestions.map((s) {
              final isActive = widget.locationCtrl.text == s;
              return GestureDetector(
                onTap: () => _selectSuggestion(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryGlow
                        : AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.place_outlined,
                          size: 13,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Text(s,
                          style: AppTextStyles.ui(13,
                              weight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textPrimary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Step 3: Photo ──────────────────────────────────────────────────────────────
class _Step3 extends StatefulWidget {
  final File? photoFile;
  final ValueChanged<File?> onPhotoSelected;
  const _Step3({required this.photoFile, required this.onPhotoSelected});

  @override
  State<_Step3> createState() => _Step3State();
}

class _Step3State extends State<_Step3> {
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (xfile != null) widget.onPhotoSelected(File(xfile.path));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LISTING PHOTO',
              style: AppTextStyles.label(11, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('A clear photo of your fish increases buyer confidence.',
              style: AppTextStyles.ui(13,
                  color: AppColors.onSurfaceFaint, height: 1.4)),
          const SizedBox(height: 20),

          // Preview or placeholder
          GestureDetector(
            onTap: () => _showSourceSheet(context),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.photoFile != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(widget.photoFile!, fit: BoxFit.cover),
                        Positioned(
                          bottom: 10, right: 10,
                          child: GestureDetector(
                            onTap: () => widget.onPhotoSelected(null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 44, color: AppColors.onSurfaceFaint),
                        const SizedBox(height: 10),
                        Text('Tap to add photo',
                            style: AppTextStyles.ui(13,
                                color: AppColors.onSurfaceVariant,
                                weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Camera or gallery',
                            style: AppTextStyles.label(10,
                                color: AppColors.onSurfaceFaint)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Source buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: Text('Camera',
                      style: AppTextStyles.ui(13, weight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: Text('Gallery',
                      style: AppTextStyles.ui(13, weight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text('Photo is optional — you can skip and add one later.',
              style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
        ],
      ),
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: Text('Take Photo',
                  style: AppTextStyles.ui(14, weight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: Text('Choose from Gallery',
                  style: AppTextStyles.ui(14, weight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 4: Review ─────────────────────────────────────────────────────────────
class _Step4 extends StatelessWidget {
  final String species;
  final String qty;
  final String unit;
  final String price;
  final String location;
  final String desc;
  const _Step4({
    required this.species,
    required this.qty,
    required this.unit,
    required this.price,
    required this.location,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final totalSSP = double.tryParse(price) != null && double.tryParse(qty) != null
        ? (double.parse(price) * double.parse(qty)).toStringAsFixed(0)
        : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REVIEW & PUBLISH',
              style: AppTextStyles.label(11, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Confirm the details before making this listing live.',
              style: AppTextStyles.ui(13, color: AppColors.onSurfaceFaint, height: 1.4)),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.card)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ReviewRow('Species',  species.isEmpty ? '—' : species,   Icons.set_meal_outlined),
                      _ReviewRow('Quantity', qty.isEmpty ? '—' : '$qty $unit',  Icons.scale_outlined),
                      _ReviewRow('Price',    price.isEmpty ? '—' : 'SSP $price / $unit', Icons.payments_outlined),
                      _ReviewRow('Location', location.isEmpty ? '—' : location, Icons.location_on_outlined),
                      if (desc.isNotEmpty)
                        _ReviewRow('Notes', desc, Icons.notes_rounded),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          color: AppColors.secondary, size: 18),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL LISTING VALUE',
                              style: AppTextStyles.label(9,
                                  color: AppColors.secondary)),
                          Text('SSP $totalSSP',
                              style: AppTextStyles.data(18,
                                  weight: FontWeight.w700,
                                  color: AppColors.secondary)),
                        ],
                      ),
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
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReviewRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(label,
                style: AppTextStyles.ui(13,
                    color: AppColors.onSurfaceVariant)),
            const Spacer(),
            Text(value,
                style: AppTextStyles.ui(13, weight: FontWeight.w600)),
          ],
        ),
      );
}
