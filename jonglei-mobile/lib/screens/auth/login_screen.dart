import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+211');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final ok = await provider.login(
      _phoneController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      final role = context.read<AuthProvider>().currentUser!.role;
      final routes = {
        'TRADER': '/trader',
        'BUYER': '/buyer',
        'TRANSPORTER': '/transporter',
        'DRIVER': '/transporter',
        'BORDER_OFFICIAL': '/border-official',
      };
      Navigator.pushReplacementNamed(context, routes[role] ?? '/trader');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo + wordmark (not a card) ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.set_meal_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jonglei Fish Hub',
                        style: AppTextStyles.display(22,
                            color: AppColors.primary),
                      ),
                      Text(
                        'SIGN IN TO CONTINUE',
                        style: AppTextStyles.label(10,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Big editorial heading ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Welcome\nback.',
                style: AppTextStyles.display(30,
                    color: AppColors.onSurface),
              ),
            ),

            const SizedBox(height: 28),

            // ── Bottom white card ─────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Phone label
                        Text(
                          'PHONE NUMBER',
                          style: AppTextStyles.label(11,
                              color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: AppTextStyles.data(14),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_android_rounded),
                            hintText: '+211 9XX XXX XXX',
                          ),
                          validator: (v) =>
                              v != null && v.startsWith('+211')
                                  ? null
                                  : 'Enter a valid +211 number',
                        ),

                        const SizedBox(height: 20),

                        // Password label
                        Text(
                          'PASSWORD',
                          style: AppTextStyles.label(11,
                              color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) =>
                              v != null && v.length >= 8
                                  ? null
                                  : 'Min 8 characters',
                        ),

                        // Error container
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.danger, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: AppTextStyles.ui(13,
                                        color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // CTA — amber full-width 52px
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: auth.loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            icon: auth.loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.arrow_forward_rounded,
                                    size: 18),
                            label: Text(
                              'SIGN IN',
                              style: AppTextStyles.ui(14,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Register link
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: AppTextStyles.ui(13,
                                    color: AppColors.onSurfaceVariant),
                                children: [
                                  TextSpan(
                                    text: 'Register',
                                    style: AppTextStyles.ui(13,
                                        weight: FontWeight.w700,
                                        color: AppColors.primary),
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
    );
  }
}
