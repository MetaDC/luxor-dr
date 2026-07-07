import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../controllers/auth_ctrl.dart';
import '../../../../models/doctor_model.dart';
import '../../../../utils/app_theme.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  void _showDoctorPicker(BuildContext context, AuthCtrl auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DoctorPickerSheet(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DrColors.background,
      body: SafeArea(
        child: GetBuilder<AuthCtrl>(
          builder: (auth) {
            final doctor = auth.currentDoctor;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: DrColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Doctor card (tappable) ───────────────────────
                  GestureDetector(
                    onTap: () => _showDoctorPicker(context, auth),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DrColors.primary,

                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                doctor?.initials ?? 'DR',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${doctor?.name ?? ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  doctor?.specialization ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                if (auth.allDoctors.length > 1) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.swap_horiz_rounded,
                                        size: 11,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tap to switch doctor',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Menu items ───────────────────────────────────
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () => launchUrlString(
                      'https://www.luxorhospital.com/privacy-policy.html',
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    subtitle: 'Read our terms of service',
                    onTap: () => launchUrlString(
                      'https://www.luxorhospital.com/privacy-policy.html',
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  // const SizedBox(height: 4),
                  _LogoutMenuItem(auth: auth),
                  const SizedBox(height: 32),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: DrColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'Developed by '),
                          TextSpan(
                            text: 'Diwizon',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                              color: DrColors.primary,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => launchUrlString(
                                'https://diwizon.com',
                                mode: LaunchMode.externalApplication,
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout menu item (stateful to manage loading state)
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutMenuItem extends StatefulWidget {
  final AuthCtrl auth;
  const _LogoutMenuItem({required this.auth});

  @override
  State<_LogoutMenuItem> createState() => _LogoutMenuItemState();
}

class _LogoutMenuItemState extends State<_LogoutMenuItem> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: DrColors.surface,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: DrColors.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: DrColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Log Out',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: DrColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to log out of your account?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: DrColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).pop(false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: DrColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DrColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DrColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).pop(true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: DrColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    await widget.auth.logout(context);
    if (mounted) {
      setState(() => _loggingOut = false);
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DrColors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: _loggingOut ? null : _logout,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DrColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _loggingOut
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          color: DrColors.error,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        color: DrColors.error,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      _loggingOut ? 'Logging out…' : 'Log Out',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: DrColors.error,
                      ),
                    ),
                    Text(
                      'Logout of your account',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DrColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Doctor picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DoctorPickerSheet extends StatelessWidget {
  final AuthCtrl auth;
  const _DoctorPickerSheet({required this.auth});

  @override
  Widget build(BuildContext context) {
    final doctors = auth.allDoctors;
    final current = auth.currentDoctor;

    return Container(
      decoration: const BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DrColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Select Doctor',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All data will update for the selected doctor',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: DrColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          if (doctors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No other doctors found',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: DrColors.textTertiary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doctors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final doc = doctors[i];
                final isActive = doc.docId == current?.docId;
                return _DoctorTile(
                  doctor: doc,
                  isActive: isActive,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isActive) auth.switchDoctor(doc);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  final DoctorModel doctor;
  final bool isActive;
  final VoidCallback onTap;

  const _DoctorTile({
    required this.doctor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? DrColors.primary.withValues(alpha: 0.06)
              : DrColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? DrColors.primary : DrColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? DrColors.primary : DrColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  doctor.initials,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : DrColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${doctor.name}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? DrColors.primary : DrColors.textPrimary,
                    ),
                  ),
                  if (doctor.specialization.isNotEmpty)
                    Text(
                      doctor.specialization,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DrColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DrColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DrColors.primary,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: DrColors.textTertiary.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu item
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.iconColor = DrColors.textSecondary,
    this.labelColor = DrColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DrColors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: DrColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: DrColors.textTertiary.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
