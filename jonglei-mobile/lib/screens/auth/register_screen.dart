import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+211');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedRole = 'TRADER';
  bool _obscurePassword = true;

  static const _roles = [
    ('TRADER', 'Fish Trader', Icons.storefront_rounded),
    ('BUYER', 'Buyer', Icons.shopping_bag_rounded),
    ('TRANSPORTER', 'Transporter', Icons.local_shipping_rounded),
    ('DRIVER', 'Driver', Icons.directions_car_rounded),
    ('BORDER_OFFICIAL', 'Border Official', Icons.verified_user_rounded),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AuthProvider>();
    final ok = await provider.register(
      phoneNumber: _phoneController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      location: _locationController.text.trim(),
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
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLow,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Account',
          style: AppTextStyles.ui(16, weight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── YOUR DETAILS section ────────────────────────────────────
              Text('YOUR DETAILS',
                  style: AppTextStyles.label(11,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 12),

              // Phone
              Text('PHONE NUMBER',
                  style: AppTextStyles.label(11,
                      color: AppColors.onSurfaceVariant)),
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

              const SizedBox(height: 16),

              // Display name
              Text('DISPLAY NAME',
                  style: AppTextStyles.label(11,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  hintText: 'Your name',
                ),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty
                        ? null
                        : 'Name is required',
              ),

              const SizedBox(height: 16),

              // Password
              Text('PASSWORD',
                  style: AppTextStyles.label(11,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
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

              const SizedBox(height: 24),

              // ── ROLE section ────────────────────────────────────────────
              Text('YOUR ROLE',
                  style: AppTextStyles.label(11,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _roles.map((r) {
                  final selected = _selectedRole == r.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRole = r.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceHigh,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(r.$3,
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            r.$2,
                            style: AppTextStyles.ui(13,
                                weight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── LOCATION section ─────────────────────────────────────────
              Text('LOCATION',
                  style: AppTextStyles.label(11,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  hintText: 'e.g. Juba, Bor, Malakal (optional)',
                  hintStyle: AppTextStyles.ui(14,
                      color: AppColors.onSurfaceFaint),
                ),
              ),

              // Error container
              if (auth.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: auth.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    'CREATE ACCOUNT',
                    style: AppTextStyles.ui(14,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sign in link
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: AppTextStyles.ui(13,
                          color: AppColors.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'Sign in',
                          style: AppTextStyles.ui(13,
                              weight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
