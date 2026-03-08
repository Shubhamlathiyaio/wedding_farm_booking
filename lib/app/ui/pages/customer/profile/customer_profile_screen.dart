import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedding_farm_booking/app/utils/constants/app_colors.dart';

import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/settings_controller.dart';
import '../../../widgets/custom_buttons.dart';
import '../../owner/profile/owner_upi_setup_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final settings = SettingsController.to;
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        final profile = authCtrl.profile.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    profile?.fullName.isNotEmpty == true ? profile!.fullName[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                profile?.fullName ?? 'User',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile?.role.toUpperCase() ?? 'CUSTOMER',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Account Info ──────────────────────────────────────────────
            _sectionLabel('Account'),
            _buildInfoTile(Icons.email_outlined, 'Email', user?.email ?? '—'),
            const Divider(height: 1),
            _buildInfoTile(Icons.phone_outlined, 'Phone', profile?.phone ?? '—'),
            const Divider(height: 1),
            _buildInfoTile(Icons.badge_outlined, 'Account Role', profile?.isOwner == true ? 'Farm Owner' : 'Customer'),

            if (profile?.isOwner == true) ...[
              const Divider(height: 1),
              _buildActionTile(Icons.qr_code_scanner, 'UPI Payment Settings', () {
                Get.to(() => const OwnerUpiSetupScreen());
              }),
            ],

            const SizedBox(height: 24),

            // ── Appearance ────────────────────────────────────────────────
            _sectionLabel('Appearance'),
            _ThemeSelectorTile(settings: settings),

            const SizedBox(height: 24),

            // ── Language ──────────────────────────────────────────────────
            _sectionLabel('Language'),
            _LanguageSelectorTile(settings: settings),

            const SizedBox(height: 32),

            // ── Logout ────────────────────────────────────────────────────
            AppButton(
              title: 'Log Out',
              type: AppButtonType.danger,
              icon: Icons.logout_rounded,
              onPressed: () => _showLogoutDialog(context, authCtrl),
            ),
            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthController authCtrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              authCtrl.signOut();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Theme Selector ──────────────────────────────────────────────────────────

class _ThemeSelectorTile extends StatelessWidget {
  final SettingsController settings;
  const _ThemeSelectorTile({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _ThemeOption(
            icon: Icons.wb_sunny_rounded,
            label: 'Light',
            isSelected: settings.themeMode.value == ThemeMode.light,
            onTap: () => settings.setThemeMode(ThemeMode.light),
          ),
          _verticalDivider(),
          _ThemeOption(
            icon: Icons.dark_mode_rounded,
            label: 'Dark',
            isSelected: settings.themeMode.value == ThemeMode.dark,
            onTap: () => settings.setThemeMode(ThemeMode.dark),
          ),
          _verticalDivider(),
          _ThemeOption(
            icon: Icons.phone_android_rounded,
            label: 'System',
            isSelected: settings.themeMode.value == ThemeMode.system,
            onTap: () => settings.setThemeMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(width: 1, height: 60, color: AppColors.divider);
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.grey, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Language Selector ───────────────────────────────────────────────────────

class _LanguageSelectorTile extends StatelessWidget {
  final SettingsController settings;
  const _LanguageSelectorTile({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: settings.supportedLanguages.asMap().entries.map((entry) {
          final i = entry.key;
          final lang = entry.value;
          final isSelected = settings.currentLanguageCode == lang['code'];
          final isLast = i == settings.supportedLanguages.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => settings.setLocale(lang['code']!),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang['native']!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            lang['name']!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isSelected) Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20) else Icon(Icons.circle_outlined, color: AppColors.divider, size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}
