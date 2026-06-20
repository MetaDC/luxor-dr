import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_theme.dart';
import 'appointments/appointment_form.dart';
import 'meetings/meeting_form.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeShell
// ─────────────────────────────────────────────────────────────────────────────

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _locationIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/home/schedule')) return 1;
    if (loc.startsWith('/home/profile')) return 2;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/home/schedule');
      case 2:
        context.go('/home/profile');
    }
  }

  void _showNewItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _NewItemSheet(parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = _locationIndex(context);
    return Scaffold(
      backgroundColor: DrColors.background,
      body: child,
      bottomNavigationBar: _FloatingNavBar(
        activeIndex: idx,
        onItemTap: (i) => _onNavTap(context, i),
        onCreateTap: () => _showNewItemSheet(context),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating pill nav bar
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onCreateTap;

  const _FloatingNavBar({
    required this.activeIndex,
    required this.onItemTap,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Same as scaffold background so the gaps around the pill look intentional
      color: DrColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: DrColors.surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: DrColors.primary.withValues(alpha: 0.10),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, -2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavTab(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  active: activeIndex == 0,
                  onTap: () => onItemTap(0),
                  isFirst: true,
                ),
                _NavTab(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  active: activeIndex == 1,
                  onTap: () => onItemTap(1),
                ),
                _NavTab(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  active: activeIndex == 2,
                  onTap: () => onItemTap(2),
                  isLast: true,
                ),
                // Centre action — not a nav destination
                _CreateTab(onTap: onCreateTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav tab item
// ─────────────────────────────────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(26) : Radius.zero,
            right: isLast ? const Radius.circular(26) : Radius.zero,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animated pill background
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 46,
                height: 30,
                decoration: BoxDecoration(
                  color: active
                      ? DrColors.primary.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  active ? activeIcon : icon,
                  size: 20,
                  color: active ? DrColors.primary : DrColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? DrColors.primary : DrColors.textTertiary,
                  height: 1,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Centre create button
// ─────────────────────────────────────────────────────────────────────────────

class _CreateTab extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateTab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DrColors.gradStart, DrColors.gradEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: DrColors.primary.withValues(alpha: 0.38),
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New Item sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NewItemSheet extends StatelessWidget {
  final BuildContext parentContext;
  const _NewItemSheet({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: DrColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DrColors.gradStart, DrColors.gradEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: DrColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Choose what to schedule',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DrColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _SheetOption(
                  icon: Icons.calendar_today_rounded,
                  color: DrColors.primary,
                  label: 'New Appointment',
                  subtitle: 'Schedule a patient visit',
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: parentContext,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AppointmentFormSheet(),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _SheetOption(
                  icon: Icons.groups_rounded,
                  color: DrColors.accent,
                  label: 'New Meeting',
                  subtitle: 'Schedule a meeting or review',
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: parentContext,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const MeetingFormSheet(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
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
                        color: DrColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DrColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
