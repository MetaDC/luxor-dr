import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../controllers/home_ctrl.dart';
import '../../../models/app_meet_model.dart';
import '../../../utils/app_theme.dart';
import 'appointments/appointment_form.dart';
import 'meetings/meeting_form.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeView
// ─────────────────────────────────────────────────────────────────────────────

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DrColors.background,
      body: SafeArea(
        child: GetBuilder<HomeCtrl>(
          builder: (ctrl) {
            final upNext = ctrl.upcomingNextHour;
            return CustomScrollView(
              slivers: [
                // ── Date + greeting ────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, MMMM d',
                          ).format(DateTime.now()).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: DrColors.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_greeting()} 👋',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: DrColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Up Next carousel (full screen width — no side padding) ──
                SliverToBoxAdapter(child: _UpNextCarousel(items: upNext)),

                // ── Today stats + Quick actions ────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                                label: 'Meetings',
                                onTap: () =>
                                    context.go('/home/schedule?filter=meeting'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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

  String get _title =>
      _isAppt ? item.personName : (item.shortDescription ?? item.personName);

  String get _detail {
    if (_isAppt) {
      final sd = item.shortDescription;
      return (sd != null && sd.isNotEmpty)
          ? sd
          : item.type.replaceAll('_', ' ');
    }
    final desc = item.description;
    return (desc != null && desc.isNotEmpty) ? desc : item.personName;
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
                  _isAppt ? 'APPOINTMENT' : 'MEETING',
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
                      'No appointments or meetings coming up',
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
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: DrColors.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: DrColors.textSecondary,
              ),
            ),
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
                onTap: () => showModalBottomSheet(
                  context: parentContext,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AppointmentFormSheet(),
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
                label: 'New Meeting',
                subtitle: 'Schedule a meeting or review',
                isLast: true,
                onTap: () => showModalBottomSheet(
                  context: parentContext,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const MeetingFormSheet(),
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
