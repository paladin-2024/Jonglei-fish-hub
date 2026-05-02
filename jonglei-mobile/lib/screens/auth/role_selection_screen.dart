import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Shown during registration — replaces the chip selector in register_screen.
/// Also accessible as standalone for first-time login flow awareness.
class RoleSelectionScreen extends StatefulWidget {
  /// If true, acts as a standalone screen navigating to register.
  /// If false, returns the selected role string via Navigator.pop().
  final bool standalone;
  const RoleSelectionScreen({super.key, this.standalone = true});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selected = 'TRADER';
  String _lang = 'EN';

  static const _roles = [
    _Role('TRADER', 'Trader', 'Manage daily sales and inventory.',
        Icons.storefront_rounded, AppColors.primary),
    _Role('BUYER', 'Buyer', 'Browse stocks and place bulk orders.',
        Icons.shopping_basket_rounded, AppColors.primary),
    _Role('TRANSPORTER', 'Transporter', 'Logistics and fleet management.',
        Icons.local_shipping_rounded, AppColors.primary),
    _Role('DRIVER', 'Driver', 'Real-time tracking and dispatch.',
        Icons.drive_eta_rounded, AppColors.primary),
    _Role('BORDER_OFFICIAL', 'Border Official', 'Clearance and duty verification.',
        Icons.verified_user_rounded, AppColors.primary),
    _Role('ADMIN', 'Admin', 'System oversight and analytics.',
        Icons.admin_panel_settings_rounded, AppColors.primary),
  ];

  static const _langs = ['EN', 'AR', 'DI', 'NR'];

  void _continue() {
    if (widget.standalone) {
      Navigator.pushReplacementNamed(context, '/register',
          arguments: _selected);
    } else {
      Navigator.pop(context, _selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                children: [
                  // Logo row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.set_meal_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Text('Jonglei Fish Hub',
                          style: AppTextStyles.display(22,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Follow Your Catch from Fishing to Market',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.ui(14,
                        color: AppColors.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('SELECT YOUR ROLE',
                        style: AppTextStyles.label(12,
                            weight: FontWeight.w700,
                            color: AppColors.onSurface)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Role grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: _roles.length,
                  itemBuilder: (_, i) => _RoleCard(
                    role: _roles[i],
                    selected: _selected == _roles[i].key,
                    onTap: () => setState(() => _selected = _roles[i].key),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Continue CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            // Language switcher
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _langs.map((l) {
                  final active = l == _lang;
                  return GestureDetector(
                    onTap: () => setState(() => _lang = l),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        l,
                        style: AppTextStyles.ui(13,
                            weight: active ? FontWeight.w800 : FontWeight.w400,
                            color: active
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Role {
  final String key;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  const _Role(this.key, this.name, this.description, this.icon, this.color);
}

class _RoleCard extends StatelessWidget {
  final _Role role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: selected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(role.icon,
                  size: 28,
                  color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
              const Spacer(),
              Text(role.name,
                  style: AppTextStyles.ui(14,
                      weight: FontWeight.w700, color: AppColors.onSurface)),
              const SizedBox(height: 3),
              Text(role.description,
                  style: AppTextStyles.ui(11,
                      color: AppColors.onSurfaceVariant, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
