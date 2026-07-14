import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controllers/home_ctrl.dart';
import '../../../utils/app_theme.dart';
import '../update_app_view.dart';
import 'appointments/appointment_form.dart';
import 'meetings/meeting_form.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeShell
// ─────────────────────────────────────────────────────────────────────────────

class HomeShell extends StatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  StreamSubscription<List<ConnectivityResult>>? _connectivityStream;
  bool _connectionExist = true;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _connectivityStream = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  @override
  void dispose() {
    _connectivityStream?.cancel();
    super.dispose();
  }

  Future<void> _checkInitial() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) _onConnectivityChanged(result);
  }

  void _onConnectivityChanged(List<ConnectivityResult> result) {
    if (!mounted) return;
    final has = result.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
    setState(() => _connectionExist = has);
    if (!has && !_dialogShowing) {
      _showNoConnectionDialog();
    } else if (has && _dialogShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogShowing = false;
    }
  }

  void _showNoConnectionDialog() {
    _dialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: DrColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.orange,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No Internet Connection',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: DrColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your network.\nThe app will resume automatically.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: DrColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) _dialogShowing = false;
    });
  }

  int _locationIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/home/schedule')) return 1;
    if (loc.startsWith('/home/contacts')) return 2;
    if (loc.startsWith('/home/profile')) return 3;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/home/schedule');
      case 2:
        context.go('/home/contacts');
      case 3:
        context.go('/home/profile');
    }
  }

  void _showNewItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _NewItemSheet(parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeCtrl>(
      builder: (ctrl) {
        if (!ctrl.versionSupported) {
          return const UpdateAppView();
        }
        return Scaffold(
          backgroundColor: DrColors.background,
          body: widget.child,
        );
      },
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
              borderRadius: BorderRadius.circular(16),
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
                // Centre action — not a nav destination
                _CreateTab(onTap: onCreateTap),
                _NavTab(
                  icon: Icons.people_alt_outlined,
                  activeIcon: Icons.people_alt_rounded,
                  label: 'Contacts',
                  active: activeIndex == 2,
                  onTap: () => onItemTap(2),
                ),
                _NavTab(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  active: activeIndex == 3,
                  onTap: () => onItemTap(3),
                  isLast: true,
                ),
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
              color: DrColors.primary,
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomPadding),
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
                    color: DrColors.primary,
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
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (_) => const AppointmentFormSheet(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _SheetOption(
                  icon: Icons.groups_rounded,
                  color: DrColors.success,
                  label: 'New Task',
                  subtitle: 'Schedule a task or review',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(
                        builder: (_) => const MeetingFormSheet(),
                        fullscreenDialog: true,
                      ),
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
