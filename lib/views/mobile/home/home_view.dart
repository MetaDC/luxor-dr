import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controllers/auth_ctrl.dart';
import 'package:intl/intl.dart';
import '../../../controllers/home_ctrl.dart';
import '../../../models/app_meet_model.dart';
import '../../../utils/app_theme.dart';
import 'appointments/appointment_form.dart';
import 'meetings/meeting_form.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeView
// ─────────────────────────────────────────────────────────────────────────────

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
      if (doctorId.isNotEmpty) {
        HomeCtrl.to.getTodayAppointments(doctorId);
        HomeCtrl.to.getTodayMeetings(doctorId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: DrColors.background,
        appBar: AppBar(
          backgroundColor: DrColors.primary,
          centerTitle: false,
          title: const Image(
            image: AssetImage('assets/orange-logo.png'),
            height: 25,
          ),

          actions: [
            IconButton(
              icon: const Icon(
                Icons.account_circle_outlined,
                color: Colors.white,
                // size: 30,
              ),
              onPressed: () => context.go('/home/profile'),
            ),
          ],
        ),
        body: SizedBox(
          child: GetBuilder<HomeCtrl>(
            builder: (ctrl) {
              return CustomScrollView(
                slivers: [
                  // Top Blue Container
                  // const SliverToBoxAdapter(child: _TopHeaderSection()),

                  // ── Today stats + Quick actions ────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(label: "TODAY'S SCHEDULE"),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.calendar_today_rounded,
                                  color: DrColors.primary,
                                  count: ctrl.todayAppointmentsCount,
                                  label: 'Appointments',
                                  onTap: () => context.go(
                                    '/home/schedule?filter=appointment',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.groups_rounded,
                                  color: DrColors.accent,
                                  count: ctrl.todayMeetingsCount,
                                  label: 'Tasks',
                                  onTap: () => context.go(
                                    '/home/schedule?filter=meeting',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _RaySection(parentContext: context),
                          const SizedBox(height: 24),
                          _QuickActions(parentContext: context),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: DrColors.textTertiary,
        letterSpacing: 0.9,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Up-Next carousel
// ─────────────────────────────────────────────────────────────────────────────

class _UpNextCarousel extends StatefulWidget {
  final List<AppointmentMeetingModel> items;
  const _UpNextCarousel({required this.items});

  @override
  State<_UpNextCarousel> createState() => _UpNextCarouselState();
}

class _UpNextCarouselState extends State<_UpNextCarousel> {
  final CarouselSliderController _ctrl = CarouselSliderController();
  int _page = 0;

  String _timeUntil(DateTime t) {
    final now = DateTime.now();
    if (!t.isAfter(now)) return 'In progress';
    final diff = t.difference(now);
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return m > 0 ? 'In ${h}h ${m}m' : 'In ${h}h';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const _EmptyCard();
    final count = widget.items.length;
    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _ctrl,
          itemCount: count,
          options: CarouselOptions(
            height: 172,
            viewportFraction: count > 1 ? 0.88 : 1.0,
            enlargeCenterPage: count > 1,
            enlargeFactor: 0.12,
            enableInfiniteScroll: false,
            onPageChanged: (i, _) => setState(() => _page = i),
          ),
          itemBuilder: (context, i, realIndex) => _FullCard(
            item: widget.items[i],
            index: i,
            total: count,
            timeUntil: _timeUntil(widget.items[i].startTime),
            hasSiblings: count > 1,
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              count,
              (i) => GestureDetector(
                onTap: () => _ctrl.animateToPage(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  width: _page == i ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _page == i ? DrColors.primary : DrColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full gradient card — one per PageView page
// ─────────────────────────────────────────────────────────────────────────────

class _FullCard extends StatelessWidget {
  final AppointmentMeetingModel item;
  final int index;
  final int total;
  final String timeUntil;
  final bool hasSiblings;

  const _FullCard({
    required this.item,
    required this.index,
    required this.total,
    required this.timeUntil,
    this.hasSiblings = false,
  });

  bool get _isAppt => item.docType == 'appointment';

  String get _title {
    if (_isAppt) return item.personName;
    if (item.personName.isNotEmpty) return item.personName;
    if ((item.shortDescription ?? '').isNotEmpty) return item.shortDescription!;
    return item.type
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '',
        )
        .join(' ');
  }

  String get _detail {
    if (_isAppt) {
      final sd = item.shortDescription;
      return (sd != null && sd.isNotEmpty)
          ? sd
          : item.type.replaceAll('_', ' ');
    }
    if (item.personName.isNotEmpty) {
      final desc = item.description;
      if (desc != null && desc.isNotEmpty) return desc;
      if ((item.shortDescription ?? '').isNotEmpty) {
        return item.type.replaceAll('_', ' ');
      }
      return '';
    }
    if ((item.shortDescription ?? '').isNotEmpty) {
      return item.type.replaceAll('_', ' ');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: hasSiblings
          ? const EdgeInsets.symmetric(horizontal: 6)
          : const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DrColors.primary,

        borderRadius: BorderRadius.circular(22),
        // boxShadow: [
        //   BoxShadow(
        //     color: DrColors.primary.withValues(alpha: 0.30),
        //     blurRadius: 24,
        //     offset: const Offset(0, 8),
        //   ),
        // ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      total > 1 ? 'UP NEXT  ${index + 1} / $total' : 'UP NEXT',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  timeUntil,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Type chip + time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isAppt ? 'APPOINTMENT' : 'TASK',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.access_time_rounded,
                size: 12,
                color: Colors.white70,
              ),
              const SizedBox(width: 3),
              Text(
                DateFormat('HH:mm').format(item.startTime),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              if (item.endTime.isAfter(item.startTime))
                Text(
                  ' – ${DateFormat('HH:mm').format(item.endTime)}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Name / title
          Text(
            _title,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Subtitle / location
          Row(
            children: [
              if (!_isAppt && (item.description?.isNotEmpty ?? false)) ...[
                const Icon(
                  Icons.location_on_rounded,
                  size: 11,
                  color: Colors.white54,
                ),
                const SizedBox(width: 2),
              ],
              Expanded(
                child: Text(
                  _detail,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty-state gradient card
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DrColors.primary,
        borderRadius: BorderRadius.circular(22),
        // boxShadow: [
        //   BoxShadow(
        //     color: DrColors.primary.withValues(alpha: 0.30),
        //     blurRadius: 24,
        //     offset: const Offset(0, 8),
        //   ),
        // ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(
                  'UP NEXT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All clear for the next hour',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'No appointments or tasks coming up',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),

        decoration: BoxDecoration(
          color: DrColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DrColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: DrColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DrColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // const SizedBox(width: 8),
            // Container(
            //   width: 38,
            //   height: 38,
            //   decoration: BoxDecoration(
            //     color: color.withValues(alpha: 0.12),
            //     borderRadius: BorderRadius.circular(10),
            //   ),
            //   child: Icon(icon, color: color, size: 20),
            // ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final BuildContext parentContext;
  const _QuickActions({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'QUICK ACTIONS'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: DrColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DrColors.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.calendar_today_rounded,
                color: DrColors.primary,
                label: 'New Appointment',
                subtitle: 'Schedule a patient visit',
                isFirst: true,
                onTap: () => Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                    builder: (_) => const AppointmentFormSheet(),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: .5,
                indent: 16,
                endIndent: 16,
                color: DrColors.border,
              ),
              _ActionRow(
                icon: Icons.groups_rounded,
                color: DrColors.accent,
                label: 'New Task',
                subtitle: 'Schedule a task or review',
                isLast: true,
                onTap: () => Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                    builder: (_) => const MeetingFormSheet(),
                    fullscreenDialog: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
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
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ray Section
// ─────────────────────────────────────────────────────────────────────────────

class _RaySection extends StatelessWidget {
  final BuildContext parentContext;
  const _RaySection({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /*  Text(
          'Ray',
          style: GoogleFonts.lora(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1B2260),
          ),
        ), */
        // const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RayButton(
                icon: CupertinoIcons.calendar,
                // icon: Icons.calendar_month_outlined,
                label: 'Calendar',
                onTap: () => context.go('/home/schedule'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _RayButton(
                icon: Icons.people_outline_rounded,
                label: 'Patients',
                onTap: () => context.go('/home/contacts'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RayButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: DrColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DrColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                // border: Border.all(
                //   color: DrColors.accent.withValues(alpha: 0.5),
                //   width: 1.5,
                // ),
              ),
              child: Icon(icon, color: DrColors.accent, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DrColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Header Section & Tab Item
// ─────────────────────────────────────────────────────────────────────────────

class _TopHeaderSection extends StatelessWidget {
  const _TopHeaderSection();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final doctor = AuthCtrl.to.currentDoctor;
    final doctorName = doctor?.name ?? 'Doctor';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B2C8C), Color(0xFF2E40B7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Logo & Actions
          Row(
            children: [
              const Image(
                image: AssetImage('assets/orange-logo.png'),
                height: 36,
              ),
              const Spacer(),

              IconButton(
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.white,
                  // size: 30,
                ),
                onPressed: () => context.go('/home/profile'),
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // // Greeting
          // Text(
          //   '${_greeting()},',
          //   style: GoogleFonts.inter(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w400,
          //     color: Colors.white.withValues(alpha: 0.8),
          //   ),
          // ),
          // const SizedBox(height: 4),
          // Text(
          //   '$doctorName 👋',
          //   style: GoogleFonts.inter(
          //     fontSize: 26,
          //     fontWeight: FontWeight.w800,
          //     color: Colors.white,
          //   ),
          // ),
          /*       const SizedBox(height: 8),
          // Date
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ), */
          const SizedBox(height: 10),
          // // Tabs
          // const Row(
          //   children: [
          //     _TabItem(label: 'APPS', isActive: true),
          //     SizedBox(width: 24),
          //     _TabItem(label: 'SUMMARY', isActive: false),
          //   ],
          // ),
        ],
      ),
    );
  }
}
