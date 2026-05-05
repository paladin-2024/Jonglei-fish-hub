import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

// ─── Language options ─────────────────────────────────────────────────────────
const _languages = [
  _Language('EN', 'English'),
  _Language('AR', 'العربية'),
  _Language('DIN', 'Thuɔŋjäŋ (Dinka)'),
];

class _Language {
  final String code;
  final String label;
  const _Language(this.code, this.label);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late TextEditingController _usernameCtrl;
  late TextEditingController _locationCtrl;
  bool _saving = false;
  String _saveError = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _locationCtrl = TextEditingController(text: user?.location ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() { _saving = true; _saveError = ''; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.api.patch('/auth/update-profile/', {
        'username': _usernameCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
      });
      await auth.refreshCurrentUser();
      if (mounted) setState(() { _editing = false; _saving = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError = 'Failed to save. Please try again.';
          _saving = false;
        });
      }
    }
  }

  Future<void> _setLanguage(String code) async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.api.patch('/auth/update-profile/', {'preferred_language': code});
      await auth.refreshCurrentUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update language',
              style: AppTextStyles.ui(13, color: AppColors.surface)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final initials  = user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';
    final stars     = user.rating.clamp(0.0, 5.0);
    final lang      = user.preferredLanguage;

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(initials,
                              style: AppTextStyles.display(26, color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MY ACCOUNT',
                                style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
                            const SizedBox(height: 4),
                            Text(user.username.isEmpty ? 'Account' : user.username,
                                style: AppTextStyles.display(22)),
                            const SizedBox(height: 6),
                            Row(children: [
                              _RolePill(user.roleDisplay),
                              if (user.isVerified) ...[
                                const SizedBox(width: 8),
                                _VerifiedPill(),
                              ],
                            ]),
                          ],
                        ),
                      ),
                      // Edit toggle
                      IconButton(
                        icon: Icon(
                          _editing ? Icons.close_rounded : Icons.edit_outlined,
                          size: 20, color: AppColors.onSurfaceVariant),
                        onPressed: () => setState(() {
                          _editing = !_editing;
                          _saveError = '';
                        }),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Stat chips
                  Row(children: [
                    _StatChip(
                        label: 'TRADES',
                        value: '${user.totalTransactions}',
                        color: AppColors.primary),
                    const SizedBox(width: 10),
                    _StatChip(
                        label: 'RATING',
                        value: '${stars.toStringAsFixed(1)} ★',
                        color: AppColors.secondary),
                    const SizedBox(width: 10),
                    _StatChip(
                        label: 'LANGUAGE',
                        value: lang,
                        color: AppColors.info),
                  ]),
                ],
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Account details / edit form ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 10),
                    child: Text('ACCOUNT DETAILS',
                        style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
                  ),

                  if (!_editing)
                    _InfoCard(children: [
                      _InfoRow(Icons.person_outline_rounded, 'Username', user.username),
                      _InfoRow(Icons.phone_android_rounded, 'Phone', user.phoneNumber),
                      _InfoRow(Icons.location_on_outlined, 'Location',
                          user.location.isEmpty ? 'Not set' : user.location),
                      _InfoRow(Icons.badge_outlined, 'Role', user.roleDisplay),
                    ])
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                            ),
                            style: AppTextStyles.ui(14),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _locationCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                            ),
                            style: AppTextStyles.ui(14),
                          ),
                          if (_saveError.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(_saveError,
                                style: AppTextStyles.ui(12, color: AppColors.danger)),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveProfile,
                              child: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('Save Changes',
                                      style: AppTextStyles.ui(14,
                                          weight: FontWeight.w700,
                                          color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Language selector ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 10),
                    child: Text('LANGUAGE',
                        style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Column(
                      children: _languages.asMap().entries.map((e) {
                        final l = e.value;
                        final isSelected = lang == l.code;
                        final isLast = e.key == _languages.length - 1;
                        return GestureDetector(
                          onTap: () => _setLanguage(l.code),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : const Border(
                                      bottom: BorderSide(
                                          color: AppColors.surfaceLow, width: 1)),
                            ),
                            child: Row(
                              children: [
                                Text(l.code,
                                    style: AppTextStyles.data(13,
                                        weight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(l.label,
                                      style: AppTextStyles.ui(14,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.onSurface,
                                          weight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w400)),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      size: 18, color: AppColors.primary),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Actions ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 10),
                    child: Text('ACTIONS',
                        style: AppTextStyles.label(10, color: AppColors.onSurfaceFaint)),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: Text('Sign Out',
                          style: AppTextStyles.ui(14,
                              weight: FontWeight.w600,
                              color: AppColors.danger)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dangerLight,
                        foregroundColor: AppColors.danger,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _RolePill extends StatelessWidget {
  final String label;
  const _RolePill(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label.toUpperCase(),
            style: AppTextStyles.label(10,
                color: AppColors.primary, weight: FontWeight.w700)),
      );
}

class _VerifiedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 11, color: AppColors.success),
            const SizedBox(width: 4),
            Text('VERIFIED',
                style: AppTextStyles.label(10,
                    color: AppColors.success, weight: FontWeight.w700)),
          ],
        ),
      );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Text(value,
                  style: AppTextStyles.data(14, weight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTextStyles.label(9, color: AppColors.onSurfaceFaint)),
            ],
          ),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(children: children),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 17, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(label,
                  style: AppTextStyles.ui(13, color: AppColors.onSurfaceVariant)),
              const Spacer(),
              Text(value, style: AppTextStyles.data(13, weight: FontWeight.w600)),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.surfaceLow, margin: const EdgeInsets.only(left: 44)),
      ],
    );
  }
}
