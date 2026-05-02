import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final initials = user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';
    final stars     = user.rating.clamp(0.0, 5.0);

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: CustomScrollView(
        slivers: [
          // ── Flat header — no gradient (impeccable rule) ──────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Identity row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar — tonal circle, no border
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: AppTextStyles.display(26,
                                color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MY ACCOUNT',
                                style: AppTextStyles.label(10,
                                    color: AppColors.onSurfaceFaint)),
                            const SizedBox(height: 4),
                            Text(
                              user.username.isEmpty ? 'Account' : user.username,
                              style: AppTextStyles.display(22),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _RolePill(user.roleDisplay),
                                if (user.isVerified) ...[
                                  const SizedBox(width: 8),
                                  _VerifiedPill(),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Stat row — 3 horizontal chips
                  Row(
                    children: [
                      _StatChip(
                        label: 'TRADES',
                        value: '${user.totalTransactions}',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        label: 'RATING',
                        value: '${stars.toStringAsFixed(1)} ★',
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        label: 'LANGUAGE',
                        value: user.preferredLanguage,
                        color: AppColors.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section label
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 10),
                    child: Text('ACCOUNT DETAILS',
                        style: AppTextStyles.label(10,
                            color: AppColors.onSurfaceFaint)),
                  ),

                  // Info rows in a surface card
                  _InfoCard(children: [
                    _InfoRow(Icons.phone_android_rounded, 'Phone',
                        user.phoneNumber),
                    _InfoRow(Icons.location_on_outlined, 'Location',
                        user.location.isEmpty ? 'Not set' : user.location),
                    _InfoRow(Icons.badge_outlined, 'Role', user.roleDisplay),
                  ]),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 10),
                    child: Text('ACTIONS',
                        style: AppTextStyles.label(10,
                            color: AppColors.onSurfaceFaint)),
                  ),

                  // Edit profile — outlined teal
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profile editing coming soon',
                              style: AppTextStyles.ui(13)),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.surface,
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text('Edit Profile',
                          style: AppTextStyles.ui(14,
                              weight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.35)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Sign out — danger surface, no border
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
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)),
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

// ── Role pill ──────────────────────────────────────────────────────────────────
class _RolePill extends StatelessWidget {
  final String label;
  const _RolePill(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.label(10,
              color: AppColors.primary, weight: FontWeight.w700),
        ),
      );
}

// ── Verified pill ─────────────────────────────────────────────────────────────
class _VerifiedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded,
                size: 11, color: AppColors.success),
            const SizedBox(width: 4),
            Text('VERIFIED',
                style: AppTextStyles.label(10,
                    color: AppColors.success, weight: FontWeight.w700)),
          ],
        ),
      );
}

// ── Stat chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

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
                  style: AppTextStyles.data(14,
                      weight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTextStyles.label(9,
                      color: AppColors.onSurfaceFaint)),
            ],
          ),
        ),
      );
}

// ── Info card — surface bg, no border ─────────────────────────────────────────
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
                  style: AppTextStyles.ui(13,
                      color: AppColors.onSurfaceVariant)),
              const Spacer(),
              Text(value,
                  style: AppTextStyles.data(13,
                      weight: FontWeight.w600)),
            ],
          ),
        ),
        Container(
            height: 1,
            color: AppColors.surfaceLow,
            margin: const EdgeInsets.only(left: 44)),
      ],
    );
  }
}
