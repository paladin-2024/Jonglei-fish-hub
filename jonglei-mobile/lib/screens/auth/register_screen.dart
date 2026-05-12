import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// ─── Auth palette (shared with login) ────────────────────────────────────────
const _bg     = Color(0xFFF0EDE5);
const _card   = Color(0xFFFAFAF8);
const _fill   = Color(0xFFE8E4DD);
const _border = Color(0xFFD0CBC3);
const _ink    = Color(0xFF1C1914);
const _green  = Color(0xFF1A3D28);
const _muted  = Color(0xFF7A7065);
const _brand  = Color(0xFFC4631A);

// ─── Data ─────────────────────────────────────────────────────────────────────

const _roles = [
  ('TRADER',          'Fish Trader',    Icons.storefront_rounded),
  ('BUYER',           'Buyer',          Icons.shopping_bag_rounded),
  ('TRANSPORTER',     'Transporter',    Icons.local_shipping_rounded),
  ('DRIVER',          'Driver',         Icons.directions_car_rounded),
  ('BORDER_OFFICIAL', 'Border Official',Icons.verified_user_rounded),
];

const _locations = [
  ('Juba',       LatLng(4.8594,  31.5713)),
  ('Bor',        LatLng(6.2108,  31.5590)),
  ('Malakal',    LatLng(9.5337,  31.6581)),
  ('Renk',       LatLng(11.7907, 32.7909)),
  ('Fangak',     LatLng(9.0833,  30.9500)),
  ('Pibor',      LatLng(6.8031,  33.1318)),
  ('Wau',        LatLng(7.7023,  27.9939)),
  ('Twic East',  LatLng(7.4500,  31.5000)),
  ('Panyagoor',  LatLng(7.1167,  30.7333)),
];

const _defaultCenter = LatLng(7.8699, 29.6667); // South Sudan centre

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(text,
      style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _muted,
          letterSpacing: 0.6)),
);

InputDecoration _dec({required String hint, IconData? icon, Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: _muted, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: _muted) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: _fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD94040))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD94040), width: 1.5)),
    );

String _roleRoute(String role) => const {
      'TRADER':          '/trader',
      'BUYER':           '/buyer',
      'TRANSPORTER':     '/transporter',
      'DRIVER':          '/transporter',
      'BORDER_OFFICIAL': '/border-official',
    }[role] ??
    '/trader';

// ─── Screen ───────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // Step 0 — personal details
  final _step1Key  = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+211');
  final _nameCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  String _role     = 'TRADER';
  bool _obscure    = true;

  // OTP verification (between step 0 and step 1)
  bool _otpSent         = false;
  bool _otpVerified     = false;
  bool _sendingOtp      = false;
  bool _verifyingOtp    = false;
  String? _otpError;
  String? _verificationId;
  final _otpCtrl = TextEditingController();
  final List<TextEditingController> _otpDigits =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  // Step 1 — location
  GoogleMapController? _mapCtrl;
  LatLng? _pinned;
  bool _gettingLocation = false;
  String _locationName  = '';

  // Navigation
  int _step = 0;
  late final AnimationController _headingAnim;
  late Animation<double> _headingFade;
  late Animation<Offset> _headingSlide;

  @override
  void initState() {
    super.initState();
    _headingAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _headingFade = CurvedAnimation(
        parent: _headingAnim, curve: Curves.easeOut);
    _headingSlide = Tween(
            begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _headingAnim, curve: Curves.easeOutCubic));
    _headingAnim.forward();
  }

  @override
  void dispose() {
    _headingAnim.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _otpCtrl.dispose();
    for (final c in _otpDigits) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  // ── OTP ────────────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_step1Key.currentState!.validate()) return;
    setState(() { _sendingOtp = true; _otpError = null; });

    try {
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneCtrl.text.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (fb.PhoneAuthCredential cred) async {
          // Auto-verify on supported devices (Android SMS retrieval)
          await fb.FirebaseAuth.instance.signInWithCredential(cred);
          if (mounted) setState(() { _otpVerified = true; _sendingOtp = false; });
          _proceedToLocation();
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          if (mounted) setState(() {
            _otpError = e.message ?? 'Verification failed. Check the number.';
            _sendingOtp = false;
          });
        },
        codeSent: (String vId, int? resendToken) {
          if (mounted) setState(() {
            _verificationId = vId;
            _otpSent = true;
            _sendingOtp = false;
          });
          // Auto-focus first digit
          Future.delayed(const Duration(milliseconds: 100),
              () => _otpFocus[0].requestFocus());
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      if (mounted) setState(() {
        _otpError = 'Could not send OTP. Try again.';
        _sendingOtp = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpDigits.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _otpError = 'Enter all 6 digits.');
      return;
    }
    setState(() { _verifyingOtp = true; _otpError = null; });
    try {
      final cred = fb.PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: code);
      await fb.FirebaseAuth.instance.signInWithCredential(cred);
      if (mounted) setState(() { _otpVerified = true; _verifyingOtp = false; });
      _proceedToLocation();
    } on fb.FirebaseAuthException catch (e) {
      if (mounted) setState(() {
        _otpError = e.code == 'invalid-verification-code'
            ? 'Wrong code. Try again.'
            : e.message ?? 'Verification failed.';
        _verifyingOtp = false;
      });
    }
  }

  void _proceedToLocation() {
    _headingAnim.reverse().then((_) {
      setState(() => _step = 1);
      _headingAnim.forward();
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  bool get _firebaseReady {
    try {
      fb.FirebaseAuth.instance.app;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _goStep1() {
    if (!_step1Key.currentState!.validate()) return;
    // Skip OTP if Firebase not configured (google-services.json missing)
    if (!_firebaseReady) { _proceedToLocation(); return; }
    if (_otpVerified) { _proceedToLocation(); return; }
    _sendOtp();
  }

  void _goStep0() {
    _headingAnim.reverse().then((_) {
      setState(() => _step = 0);
      _headingAnim.forward();
    });
  }

  // ── Location ────────────────────────────────────────────────────────────────

  void _selectLocation(String name, LatLng coords) {
    setState(() {
      _locationName = name;
      _pinned = coords;
    });
    _mapCtrl?.animateCamera(
      CameraUpdate.newCameraPosition(
          CameraPosition(target: coords, zoom: 11.5)),
    );
  }

  Future<void> _useGPS() async {
    setState(() => _gettingLocation = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _gettingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final ll = LatLng(pos.latitude, pos.longitude);
      // Try to match to a known location (within ~50 km)
      String name = 'My Location';
      double minDist = double.infinity;
      for (final loc in _locations) {
        final d = _approxKm(ll, loc.$2);
        if (d < minDist) {
          minDist = d;
          if (d < 50) name = loc.$1;
        }
      }
      setState(() {
        _pinned = ll;
        _locationName = name;
        _gettingLocation = false;
      });
      _mapCtrl?.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(target: ll, zoom: 12)),
      );
    } catch (_) {
      setState(() => _gettingLocation = false);
    }
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _pinned = pos;
      _locationName = 'Custom location';
    });
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final prov = context.read<AuthProvider>();
    final ok = await prov.register(
      phoneNumber: _phoneCtrl.text.trim(),
      username: _nameCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role,
      location: _locationName,
    );
    if (!mounted) return;
    if (ok) {
      final role = context.read<AuthProvider>().currentUser!.role;
      Navigator.pushReplacementNamed(context, _roleRoute(role));
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(8, 20, 24, 0),
                child: Row(
                  children: [
                    // Back — visible on step 1
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _step == 1 ? 1.0 : 0.0,
                      child: IconButton(
                        icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: _ink),
                        onPressed: _step == 1 ? _goStep0 : null,
                      ),
                    ),
                    // Logo — visible on step 0
                    if (_step == 0) ...[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: _brand,
                            borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.set_meal_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jonglei Fish Hub',
                              style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 16,
                                  color: _green,
                                  letterSpacing: -0.2)),
                          Text('CREATE ACCOUNT',
                              style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _muted,
                                  letterSpacing: 0.8)),
                        ],
                      ),
                    ],
                    const Spacer(),
                    // Step dots
                    Row(
                      children: List.generate(2, (i) {
                        final active = _step == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(left: 5),
                          width: active ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: active ? _brand : _border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Animated headline ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SlideTransition(
                  position: _headingSlide,
                  child: FadeTransition(
                    opacity: _headingFade,
                    child: Text(
                      _step == 0
                          ? 'Create your\naccount.'
                          : 'Where are\nyou based?',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 38, color: _ink, height: 1.05),
                    ),
                  ),
                ),
              ),

              if (_step == 1) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Pick your main market location.',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: _muted),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Sliding form card ────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: _card,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 20,
                          offset: Offset(0, -4))
                    ],
                  ),
                  // IndexedStack keeps both pages alive — prevents map disposal
                  child: IndexedStack(
                    index: _step,
                    children: [
                      _buildStep0(auth),
                      _buildStep1(auth),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 0 — Personal details ───────────────────────────────────────────────

  Widget _buildStep0(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('PHONE NUMBER'),
            TextFormField(
              controller: _phoneCtrl,
              cursorColor: _green,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.outfit(fontSize: 14, color: _ink),
              decoration: _dec(
                  hint: '+211 9XX XXX XXX',
                  icon: Icons.phone_android_rounded),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                if (v.startsWith('+211') || v.startsWith('+256')) return null;
                return 'Enter a +211 (South Sudan) or +256 number';
              },
            ),

            const SizedBox(height: 16),

            _label('DISPLAY NAME'),
            TextFormField(
              controller: _nameCtrl,
              cursorColor: _green,
              style: GoogleFonts.outfit(fontSize: 14, color: _ink),
              decoration:
                  _dec(hint: 'Your name', icon: Icons.person_outline_rounded),
              validator: (v) =>
                  v != null && v.trim().isNotEmpty ? null : 'Name is required',
            ),

            const SizedBox(height: 16),

            _label('PASSWORD'),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              cursorColor: _green,
              style: GoogleFonts.outfit(fontSize: 14, color: _ink),
              decoration: _dec(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                suffix: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: _muted),
                  ),
                ),
              ),
              validator: (v) =>
                  v != null && v.length >= 8 ? null : 'Min 8 characters',
            ),

            const SizedBox(height: 24),

            _label('YOUR ROLE'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roles.map((r) {
                final selected = _role == r.$1;
                return GestureDetector(
                  onTap: () => setState(() => _role = r.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? _brand : _fill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected ? _brand : _border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(r.$3,
                            size: 15,
                            color: selected ? Colors.white : _muted),
                        const SizedBox(width: 6),
                        Text(r.$2,
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : _ink)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // ── OTP section (shown after code is sent) ──────────────────────
            if (_otpSent && !_otpVerified) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.sms_rounded, size: 16, color: _green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Code sent to ${_phoneCtrl.text.trim()}',
                          style: GoogleFonts.outfit(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: _ink),
                        ),
                      ),
                      GestureDetector(
                        onTap: _sendingOtp ? null : _sendOtp,
                        child: Text('Resend',
                            style: GoogleFonts.outfit(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: _green)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // 6-digit OTP boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => SizedBox(
                        width: 44,
                        height: 52,
                        child: TextField(
                          controller: _otpDigits[i],
                          focusNode: _otpFocus[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: _ink),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: _fill,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _border)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _border)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: _green, width: 2)),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) {
                              _otpFocus[i + 1].requestFocus();
                            } else if (v.isEmpty && i > 0) {
                              _otpFocus[i - 1].requestFocus();
                            }
                            // Auto-submit when last digit filled
                            if (i == 5 && v.isNotEmpty) _verifyOtp();
                          },
                        ),
                      )),
                    ),
                    if (_otpError != null) ...[
                      const SizedBox(height: 10),
                      Text(_otpError!,
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: const Color(0xFFD94040))),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _verifyingOtp ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _verifyingOtp
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('VERIFY & CONTINUE',
                          style: GoogleFonts.outfit(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              letterSpacing: 0.8, color: Colors.white)),
                ),
              ),
            ] else ...[
              // Error shown before OTP sent
              if (_otpError != null && !_otpSent) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD94040).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFD94040).withValues(alpha: 0.3)),
                  ),
                  child: Text(_otpError!,
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: const Color(0xFFD94040))),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _sendingOtp ? null : _goStep1,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _sendingOtp
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_to_mobile_rounded, size: 18),
                  label: Text(
                    _sendingOtp ? 'SENDING CODE…' : 'SEND VERIFICATION CODE',
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        letterSpacing: 0.8, color: Colors.white)),
                ),
              ),
            ],

            const SizedBox(height: 20),

            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: GoogleFonts.outfit(fontSize: 13, color: _muted),
                    children: [
                      TextSpan(
                        text: 'Sign in',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1 — Location picker ────────────────────────────────────────────────

  Widget _buildStep1(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: SizedBox(
              height: 230,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                    target: _defaultCenter, zoom: 6.5),
                onMapCreated: (c) => _mapCtrl = c,
                onTap: _onMapTap,
                markers: _pinned != null
                    ? {
                        Marker(
                          markerId: const MarkerId('pin'),
                          position: _pinned!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              20), // burnt-orange hue
                        )
                      }
                    : {},
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Selected location display ──────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _locationName.isEmpty
                      ? const SizedBox(height: 32, key: ValueKey('empty'))
                      : Container(
                          key: ValueKey(_locationName),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: _brand.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _brand.withValues(alpha: 0.25)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.location_on_rounded,
                                size: 16, color: _brand),
                            const SizedBox(width: 8),
                            Text(
                              _locationName,
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _brand),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() {
                                _locationName = '';
                                _pinned = null;
                              }),
                              child: const Icon(Icons.close_rounded,
                                  size: 15, color: _brand),
                            ),
                          ]),
                        ),
                ),

                // ── Top location chips ─────────────────────────────────────
                _label('TOP LOCATIONS'),
              ],
            ),
          ),

          // Horizontal chip scroll
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _locations.length,
              separatorBuilder: (_, idx) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final loc   = _locations[i];
                final active = _locationName == loc.$1;
                return GestureDetector(
                  onTap: () => _selectLocation(loc.$1, loc.$2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? _brand : _fill,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: active ? _brand : _border),
                    ),
                    child: Text(
                      loc.$1,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : _ink),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── GPS button ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _gettingLocation ? null : _useGPS,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _gettingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _green))
                        : const Icon(Icons.my_location_rounded,
                            size: 17),
                    label: Text(
                      _gettingLocation
                          ? 'Getting location…'
                          : 'Use my current position',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _green),
                    ),
                  ),
                ),

                // Error banner
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(auth.errorMessage!),
                ],

                const SizedBox(height: 20),

                // ── Create Account CTA ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: auth.loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _brand.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: auth.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text('CREATE ACCOUNT',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: Text(
                    'Location is optional — you can update it later.',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: _muted),
                    textAlign: TextAlign.center,
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

// ─── Shared micro-widget ──────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEECEC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFD94040), size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: const Color(0xFFD94040)))),
        ]),
      );
}

// ─── Approximate distance in km (equirectangular, good enough for ~500 km) ──
double _approxKm(LatLng a, LatLng b) {
  final latKm = (b.latitude  - a.latitude)  * 111.0;
  final lonKm = (b.longitude - a.longitude) * 111.0 *
      math.cos(a.latitude * math.pi / 180);
  return math.sqrt(latKm * latKm + lonKm * lonKm);
}
