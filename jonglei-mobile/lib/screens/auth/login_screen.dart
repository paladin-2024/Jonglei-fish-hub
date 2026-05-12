import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// ─── Auth palette — light parchment (login & register only) ──────────────────
const _bg     = Color(0xFFF0EDE5);   // warm linen scaffold
const _card   = Color(0xFFFAFAF8);   // near-white form card
const _fill   = Color(0xFFE8E4DD);   // input background
const _border = Color(0xFFD0CBC3);   // input stroke
const _ink    = Color(0xFF1C1914);   // near-black heading
const _green  = Color(0xFF1A3D28);   // deep forest green (wordmark, links)
const _muted  = Color(0xFF7A7065);   // warm grey labels / hints
const _brand  = Color(0xFFC4631A);   // burnt orange CTA & logo badge

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    text,
    style: GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: _muted,
      letterSpacing: 0.6,
    ),
  ),
);

InputDecoration _dec({
  required String hint,
  IconData? icon,
  Widget? suffix,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: _muted, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: _muted) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: _fill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
          borderSide:
              const BorderSide(color: Color(0xFFD94040), width: 1.5)),
    );

String _roleRoute(String role) {
  const map = {
    'TRADER':          '/trader',
    'BUYER':           '/buyer',
    'TRANSPORTER':     '/transporter',
    'DRIVER':          '/transporter',
    'BORDER_OFFICIAL': '/border-official',
  };
  return map[role] ?? '/trader';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+256');
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<AuthProvider>();
    final ok   = await prov.login(_phoneCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      final role = context.read<AuthProvider>().currentUser!.role;
      Navigator.pushReplacementNamed(context, _roleRoute(role));
    }
  }

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
              // ── Logo ───────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _brand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.set_meal_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jonglei Fish Hub',
                          style: GoogleFonts.dmSerifDisplay(
                              fontSize: 20,
                              color: _green,
                              letterSpacing: -0.3),
                        ),
                        Text(
                          'SIGN IN TO CONTINUE',
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                              letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Headline ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Welcome\nback.',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 44, color: _ink, height: 1.05),
                ),
              ),

              const SizedBox(height: 24),

              // ── Form card ──────────────────────────────────────────────────
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('PHONE NUMBER'),
                          TextFormField(
                            controller: _phoneCtrl,
                            cursorColor: _green,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.outfit(
                                fontSize: 14, color: _ink),
                            decoration: _dec(
                                hint: '+256 7XX XXX XXX',
                                icon: Icons.phone_android_rounded),
                            validator: (v) =>
                                v != null && v.startsWith('+256')
                                    ? null
                                    : 'Enter a valid +256 number',
                          ),

                          const SizedBox(height: 20),

                          _label('PASSWORD'),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            cursorColor: _green,
                            style: GoogleFonts.outfit(
                                fontSize: 14, color: _ink),
                            decoration: _dec(
                              hint: '••••••••',
                              icon: Icons.lock_outline_rounded,
                              suffix: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(right: 12),
                                  child: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: _muted),
                                ),
                              ),
                            ),
                            validator: (v) => v != null && v.length >= 8
                                ? null
                                : 'Min 8 characters',
                          ),

                          // Error banner
                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(auth.errorMessage!),
                          ],

                          const SizedBox(height: 28),

                          // CTA
                          _CTA(
                            label: 'SIGN IN',
                            loading: auth.loading,
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _submit,
                          ),

                          const SizedBox(height: 20),

                          // Register link
                          Center(
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/register'),
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: GoogleFonts.outfit(
                                      fontSize: 13, color: _muted),
                                  children: [
                                    TextSpan(
                                      text: 'Register',
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared micro-widgets ─────────────────────────────────────────────────────

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

class _CTA extends StatelessWidget {
  final String label;
  final bool loading;
  final IconData icon;
  final VoidCallback onPressed;
  const _CTA(
      {required this.label,
      required this.loading,
      required this.icon,
      required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _brand,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _brand.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(icon, size: 18),
          label: Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.white)),
        ),
      );
}
