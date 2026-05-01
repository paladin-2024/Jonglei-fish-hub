import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

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
        'TRADER': '/trader', 'BUYER': '/buyer',
        'TRANSPORTER': '/transporter', 'DRIVER': '/transporter',
      };
      Navigator.pushReplacementNamed(context, routes[role] ?? '/trader');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF00695C),
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Phone Number'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.phone_android_rounded),
                          hintText: '+211 9XX XXX XXX',
                        ),
                        validator: (v) => v != null && v.startsWith('+211') ? null : 'Enter a valid +211 number',
                      ),
                      const SizedBox(height: 16),
                      _label('Display Name'),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          hintText: 'Your name',
                        ),
                        validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Name is required',
                      ),
                      const SizedBox(height: 16),
                      _label('Password'),
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
                      const SizedBox(height: 16),
                      _label('Role'),
                      const SizedBox(height: 8),
                      // Custom role selector
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _roles.map((r) {
                          final selected = _selectedRole == r.$1;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedRole = r.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF00695C) : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? const Color(0xFF00695C) : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(r.$3, size: 16, color: selected ? Colors.white : const Color(0xFF78909C)),
                                  const SizedBox(width: 6),
                                  Text(r.$2,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected ? Colors.white : const Color(0xFF455A64),
                                      )),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _label('Location (optional)'),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_on_outlined),
                          hintText: 'e.g. Juba, Bor, Malakal',
                        ),
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
                        label: 'Create Account',
                        icon: Icons.check_rounded,
                        onPressed: _submit,
                        loading: auth.loading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF455A64))),
  );
}
