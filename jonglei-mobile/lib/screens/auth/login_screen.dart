import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

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
        'TRADER': '/trader', 'BUYER': '/buyer',
        'TRANSPORTER': '/transporter', 'DRIVER': '/transporter',
      };
      Navigator.pushReplacementNamed(context, routes[role] ?? '/trader');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final teal = const Color(0xFF00695C);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF002B27), Color(0xFF004D40), Color(0xFF00695C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF26A69A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.set_meal_rounded, color: Color(0xFF002B27), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jonglei Fish Hub',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Trade · Transport · Market',
                            style: TextStyle(color: Color(0xFF80CBC4), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Tagline
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: TextStyle(color: Color(0xFF80CBC4), fontSize: 14)),
                    Text('Sign in to continue', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Card
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phone Number',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF455A64))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.phone_android_rounded),
                              hintText: '+211 9XX XXX XXX',
                            ),
                            validator: (v) => v != null && v.startsWith('+211') ? null : 'Enter a valid +211 number',
                          ),
                          const SizedBox(height: 20),
                          const Text('Password',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF455A64))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => v != null && v.length >= 8 ? null : 'Min 8 characters',
                          ),

                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(auth.errorMessage!,
                                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),
                          CustomButton(
                            label: 'Sign In',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _submit,
                            loading: auth.loading,
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: const TextStyle(color: Color(0xFF78909C), fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: 'Register',
                                      style: TextStyle(color: teal, fontWeight: FontWeight.w700),
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
