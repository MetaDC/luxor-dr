import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../controllers/home_ctrl.dart';
import '../../../../models/app_meet_model.dart';
import '../../../../utils/app_theme.dart';
import '../../../../utils/phone_helper.dart';
import '../../../../widgets/app_snackbar.dart';
import '../appointments/appointment_form.dart';
import '../meetings/meeting_form.dart';
import '../contacts/contacts_view.dart';
import '../contacts/contact_detail_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScheduleView — combined appointments + meetings
// ─────────────────────────────────────────────────────────────────────────────

enum _TypeFilter { all, appointments, meetings }

class ScheduleView extends StatefulWidget {
  final String? initialFilter;
  const ScheduleView({super.key, this.initialFilter});
  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _dateRange;
  String _statusFilter = 'Scheduled';
  bool _isRangeMode = false;
  late _TypeFilter _typeFilter;

  StreamSubscription<List<AppointmentMeetingModel>>? _apptSub;
  StreamSubscription<List<AppointmentMeetingModel>>? _meetingSub;
  List<AppointmentMeetingModel> _appts = [];
  List<AppointmentMeetingModel> _meetings = [];

  List<AppointmentMeetingModel> _fetched = [];
  bool _loading = false;

  static const _statuses = ['Scheduled', 'Completed', 'Cancelled', 'All'];

  List<DateTime> _weekDates() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final d = today.add(Duration(days: i - 1));
      return DateTime(d.year, d.month, d.day);
    });
  }

  @override
  void initState() {
    super.initState();
    _initFilters();
    _listenForDate(_selectedDate);
  }

  void _initFilters() {
    if (widget.initialFilter == 'appointment') {
      _typeFilter = _TypeFilter.appointments;
    } else if (widget.initialFilter == 'meeting') {
      _typeFilter = _TypeFilter.meetings;
    } else {
      _typeFilter = _TypeFilter.all;
    }
  }

  @override
  void didUpdateWidget(covariant ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter) {
      setState(() {
        _initFilters();
      });
    }
  }

  void _cancelSubs() {
    _apptSub?.cancel();
    _meetingSub?.cancel();
  }

  @override
  void dispose() {
    _cancelSubs();
    super.dispose();
  }

  void _listenForDate(DateTime date) {
    _cancelSubs();
    setState(() {
      _loading = true;
      _appts = [];
      _meetings = [];
      _fetched = [];
    });

    _apptSub = HomeCtrl.to
        .listenAppointmentsForDate(date)
        .listen(
          (appts) {
            if (!mounted) return;
            setState(() {
              _appts = appts;
              _updateFetched();
              _loading = false;
            });
          },
          onError: (e) {
            if (mounted) setState(() => _loading = false);
          },
        );

    _meetingSub = HomeCtrl.to
        .listenMeetingsForDate(date)
        .listen(
          (meetings) {
            if (!mounted) return;
            setState(() {
              _meetings = meetings;
              _updateFetched();
              _loading = false;
            });
          },
          onError: (e) {
            if (mounted) setState(() => _loading = false);
          },
        );
  }

  void _listenForRange(DateTimeRange range) {
    _cancelSubs();
    setState(() {
      _loading = true;
      _appts = [];
      _meetings = [];
      _fetched = [];
    });

    _apptSub = HomeCtrl.to
        .listenAppointmentsForRange(range.start, range.end)
        .listen(
          (appts) {
            if (!mounted) return;
            setState(() {
              _appts = appts;
              _updateFetched();
              _loading = false;
            });
          },
          onError: (e) {
            if (mounted) setState(() => _loading = false);
          },
        );

    _meetingSub = HomeCtrl.to
        .listenMeetingsForRange(range.start, range.end)
        .listen(
          (meetings) {
            if (!mounted) return;
            setState(() {
              _meetings = meetings;
              _updateFetched();
              _loading = false;
            });
          },
          onError: (e) {
            if (mounted) setState(() => _loading = false);
          },
        );
  }

  void _updateFetched() {
    final all = [..._appts, ..._meetings]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    _fetched = all;
  }

  void _refresh() {
    if (_isRangeMode && _dateRange != null) {
      _listenForRange(_dateRange!);
    } else {
      _listenForDate(_selectedDate);
    }
  }

  List<AppointmentMeetingModel> get _filtered => _fetched.where((item) {
    if (_typeFilter == _TypeFilter.appointments &&
        item.docType != 'appointment')
      return false;
    if (_typeFilter == _TypeFilter.meetings && item.docType != 'meeting') {
      return false;
    }
    if (_statusFilter != 'All' && item.status != _statusFilter) {
      return false;
    }
    return true;
  }).toList();

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange:
          _dateRange ??
          DateTimeRange(
            start: _selectedDate,
            end: _selectedDate.add(const Duration(days: 6)),
          ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: DrColors.primary),
        ),
        child: child!,
      ),
    );
    if (range != null && mounted) {
      setState(() {
        _dateRange = range;
        _isRangeMode = true;
      });
      _listenForRange(range);
    }
  }

  void _clearRange() {
    setState(() {
      _dateRange = null;
      _isRangeMode = false;
    });
    _listenForDate(_selectedDate);
  }

  int get _apptCount =>
      _fetched.where((e) => e.docType == 'appointment').length;
  int get _meetCount => _fetched.where((e) => e.docType == 'meeting').length;

  @override
  Widget build(BuildContext context) {
    final dates = _weekDates();
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: DrColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: DrColors.textPrimary,
                              ),
                            ),
                            if (_isRangeMode && _dateRange != null)
                              Text(
                                '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d').format(_dateRange!.end)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: DrColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              Text(
                                _loading
                                    ? 'Loading...'
                                    : '$_apptCount appt${_apptCount != 1 ? 's' : ''} · $_meetCount task${_meetCount != 1 ? 's' : ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: DrColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Range toggle
                      GestureDetector(
                        onTap: _isRangeMode ? _clearRange : _pickDateRange,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _isRangeMode
                                ? DrColors.primary
                                : DrColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: _isRangeMode
                                ? null
                                : Border.all(color: DrColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isRangeMode
                                    ? Icons.close_rounded
                                    : Icons.calendar_month_rounded,
                                size: 13,
                                color: _isRangeMode
                                    ? Colors.white
                                    : DrColors.primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isRangeMode ? 'Clear' : 'Range',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isRangeMode
                                      ? Colors.white
                                      : DrColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Week Date Strip ──────────────────────────────
                  if (!_isRangeMode)
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: dates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final d = dates[i];
                          final now = DateTime.now();
                          final isToday =
                              d.year == now.year &&
                              d.month == now.month &&
                              d.day == now.day;
                          final isSelected =
                              d.year == _selectedDate.year &&
                              d.month == _selectedDate.month &&
                              d.day == _selectedDate.day;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedDate = d);
                              _listenForDate(d);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 46,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DrColors.primary
                                    : DrColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : isToday
                                      ? DrColors.primary
                                      : DrColors.border,
                                  width: isToday && !isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(d).toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white70
                                          : DrColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${d.day}',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : isToday
                                          ? DrColors.primary
                                          : DrColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM').format(d),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: isSelected
                                          ? Colors.white70
                                          : DrColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 8),

                  // ── Type filter (segmented) ──────────────────────
                  CupertinoSlidingSegmentedControl<_TypeFilter>(
                    groupValue: _typeFilter,
                    onValueChanged: (v) {
                      if (v != null) setState(() => _typeFilter = v);
                    },
                    padding: const EdgeInsets.all(3),
                    backgroundColor: Colors.white,
                    thumbColor: _typeFilter == _TypeFilter.meetings
                        ? DrColors.accent.withValues(alpha: 0.7)
                        : DrColors.primary.withValues(alpha: 0.7),

                    children: {
                      _TypeFilter.all: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          'All',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _typeFilter == _TypeFilter.all
                                ? Colors.white
                                : DrColors.textSecondary,
                          ),
                        ),
                      ),
                      _TypeFilter.appointments: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          'Appointments',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _typeFilter == _TypeFilter.appointments
                                ? Colors.white
                                : DrColors.textSecondary,
                          ),
                        ),
                      ),
                      _TypeFilter.meetings: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          'Tasks',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _typeFilter == _TypeFilter.meetings
                                ? Colors.white
                                : DrColors.textSecondary,
                          ),
                        ),
                      ),
                    },
                  ),

                  const SizedBox(height: 6),

                  // ── Status filter chips ──────────────────────────
                  SizedBox(
                    height: 26,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statuses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 5),
                      itemBuilder: (_, i) {
                        final s = _statuses[i];
                        final active = _statusFilter == s;
                        final color = s == 'Scheduled'
                            ? DrColors.primary
                            : s == 'Completed'
                            ? DrColors.success
                            : s == 'Cancelled'
                            ? DrColors.error
                            : DrColors.textSecondary;
                        return GestureDetector(
                          onTap: () => setState(() => _statusFilter = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? color.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active ? color : DrColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                s,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? color
                                      : DrColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DrColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : filtered.isEmpty
                  ? _EmptyState(
                      hasFilters:
                          _typeFilter != _TypeFilter.all ||
                          _statusFilter != 'All',
                      onClearFilters: () => setState(() {
                        _typeFilter = _TypeFilter.all;
                        _statusFilter = 'All';
                      }),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _ScheduleCard(item: filtered[i], onRefresh: _refresh),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;
  const _EmptyState({required this.hasFilters, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: DrColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 36,
              color: DrColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing scheduled',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasFilters
                ? 'Try adjusting your filters'
                : 'No items for this date',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: DrColors.textTertiary,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule card
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final AppointmentMeetingModel item;
  final VoidCallback onRefresh;

  const _ScheduleCard({required this.item, required this.onRefresh});

  bool get _isAppt => item.docType == 'appointment';

  Future<void> _call(BuildContext context, String phone) async {
    final cleaned = cleanPhoneNumber(phone);
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    try {
      final success = await launchUrl(uri);
      if (!success && context.mounted) {
        AppSnackbar.error(context, 'Could not start phone call.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Could not start phone call.');
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final cleaned = cleanPhoneNumber(phone).replaceAll('+', '');
    if (cleaned.isEmpty) {
      AppSnackbar.error(context, 'Invalid phone number for WhatsApp.');
      return;
    }
    final uri = Uri.parse('https://wa.me/$cleaned');
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success && context.mounted) {
        AppSnackbar.error(context, 'Could not open WhatsApp.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Could not open WhatsApp.');
      }
    }
  }

  Color get _typeColor => _isAppt ? DrColors.primary : DrColors.accent;

  Color get _accentColor {
    if (item.status == 'Cancelled') return DrColors.error;
    if (item.status == 'Completed') return DrColors.success;
    return _typeColor;
  }

  String get _mainTitle {
    return item.personName;
    final sd = item.shortDescription;
    return (sd != null && sd.isNotEmpty) ? sd : item.personName;
  }

  String get _subtitle {
    final sd = item.shortDescription;
    return (sd != null && sd.isNotEmpty) ? sd : item.type.replaceAll('_', ' ');

    final desc = item.description;
    return (desc != null && desc.isNotEmpty) ? desc : '';
  }

  // bool get _subtitleIsLocation =>
  //     !_isAppt && (item.description?.isNotEmpty ?? false);

  String _statusLabel() {
    if (item.status == 'Cancelled') return 'Cancelled';
    if (item.status == 'Completed') return 'Completed';
    final now = DateTime.now();
    final diff = item.startTime.difference(now);
    if (diff.inMinutes < -15) return 'Passed';
    if (diff.inMinutes < 0) return 'Just passed';
    final h = diff.inHours;
    if (h == 0) return 'In ${diff.inMinutes}m';
    return 'In ${h}h';
  }

  Color _statusColor() {
    final label = _statusLabel();
    if (label == 'Passed' || label == 'Cancelled') return DrColors.textTertiary;
    if (label == 'Just passed') return DrColors.warning;
    if (label == 'Completed') return DrColors.success;
    return _typeColor;
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _isAppt
          ? AppointmentFormSheet(appointment: item)
          : MeetingFormSheet(meeting: item),
    ).then((_) => onRefresh());
  }

  void _showStatusMenu(BuildContext context) {
    if (item.status == 'Cancelled' || item.status == 'Completed') {
      AppSnackbar.info(
        context,
        'This ${_isAppt ? 'appointment' : 'task'} is already ${item.status.toLowerCase()}.',
      );
      return;
    }
    showBottomSheet(
      showDragHandle: false,

      context: context,
      backgroundColor: const Color.fromARGB(255, 234, 234, 234),
      // elevation: 2,
      // color: DrColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      builder: (_) => _StatusUpdateSheet(
        docId: item.docId,
        docType: item.docType,
        onDone: onRefresh,
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    final statusColor = _statusColor();
    final themeColor = _typeColor;

    final hasSummary =
        item.status == 'Completed' && (item.summary ?? '').isNotEmpty;
    final hasCancellation =
        item.status == 'Cancelled' &&
        (item.cancellationReason ?? '').isNotEmpty;
    final showExtraBlock = hasSummary || hasCancellation;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: DrColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAppt ? 'Appointment Detail' : 'Task Detail',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: DrColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StatusBadge(
                              label: _statusLabel(),
                              color: statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: DrColors.background,
                      foregroundColor: DrColors.textSecondary,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTimelineItem(
                        icon: Icons.access_time_filled_rounded,
                        label: 'Date & Time',
                        themeColor: themeColor,
                        isLast: false,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'EEEE, MMMM d, yyyy',
                              ).format(item.startTime),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: DrColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('hh:mm a').format(item.startTime)} - ${DateFormat('hh:mm a').format(item.endTime)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: DrColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.personName.isNotEmpty)
                        _buildTimelineItem(
                          icon: _isAppt
                              ? Icons.person_rounded
                              : Icons.groups_rounded,
                          label: _isAppt ? 'Patient' : 'Task Person',
                          themeColor: themeColor,
                          isLast: false,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.personName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: DrColors.textPrimary,
                                ),
                              ),
                              if (item.personPhone.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.personPhone,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: DrColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (item.personEmail.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item.personEmail,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: DrColors.textTertiary,
                                  ),
                                ),
                              ],
                              if (item.personPhone.isNotEmpty)
                                const SizedBox(height: 8),
                              if (item.personPhone.isNotEmpty)
                                Row(
                                  children: [
                                    _ActionChip(
                                      icon: Icons.phone_rounded,
                                      label: 'Call',
                                      color: const Color(0xFF0B57D0),
                                      onTap: () => _call(ctx, item.personPhone),
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionChip(
                                      icon: Icons.chat_rounded,
                                      label: 'WhatsApp',
                                      color: const Color(0xFF128C7E),
                                      onTap: () =>
                                          _openWhatsApp(ctx, item.personPhone),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      _buildTimelineItem(
                        icon: Icons.bookmark_rounded,
                        label: 'Details',
                        themeColor: themeColor,
                        isLast: !showExtraBlock,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                item.type.replaceAll('_', ' ').toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: themeColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if ((item.shortDescription ?? '').isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                item.shortDescription!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: DrColors.textPrimary,
                                ),
                              ),
                            ],
                            if ((item.description ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.description!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: DrColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (hasSummary)
                        _buildTimelineItem(
                          icon: Icons.check_circle_rounded,
                          label: 'Completion Summary',
                          themeColor: DrColors.success,
                          isLast: true,
                          content: Text(
                            item.summary!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: DrColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (hasCancellation)
                        _buildTimelineItem(
                          icon: Icons.cancel_rounded,
                          label: 'Cancellation Reason',
                          themeColor: DrColors.error,
                          isLast: true,
                          content: Text(
                            item.cancellationReason!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: DrColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _navigateToContactDetail(
                            context,
                            item.personId,
                            item.personName,
                            item.personPhone,
                            item.personEmail,
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: DrColors.primaryLight,
                          foregroundColor: DrColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'History',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DrColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: DrColors.border,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DrColors.textPrimary,
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
  }

  void _navigateToContactDetail(
    BuildContext context,
    String personId,
    String personName,
    String personPhone,
    String personEmail,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactDetailView(
          contact: ContactEntry(
            id: personId,
            name: personName,
            email: personEmail,
            phone: personPhone,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String label,
    required Widget content,
    required Color themeColor,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: themeColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: DrColors.border.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DrColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                content,
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showActions =
        item.status != 'Completed' && item.status != 'Cancelled';
    return Container(
      decoration: BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DrColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content row wrapped in InkWell
            InkWell(
              onTap: () => _showDetailsDialog(context),
              borderRadius: showActions
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left accent stripe
                    Container(width: 4, color: _accentColor),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Type badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _typeColor.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _isAppt ? 'Appointment' : 'Task',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _typeColor,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _mainTitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: DrColors.textPrimary,
                                    ),
                                  ),
                                  if (_subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _subtitle,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: DrColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Time + status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(item.startTime),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: DrColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _StatusBadge(
                                  label: _statusLabel(),
                                  color: _statusColor(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action row
            if (showActions) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        color: _typeColor,
                        onTap: () => _openEdit(context),
                      ),
                    ),
                    Container(width: 1, height: 20, color: DrColors.border),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Update Status',
                        color: item.status == 'Scheduled'
                            ? DrColors.warning
                            : DrColors.textTertiary,
                        onTap: () => _showStatusMenu(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status update bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _StatusUpdateSheet extends StatefulWidget {
  final String docId;
  final String docType;
  final VoidCallback onDone;
  const _StatusUpdateSheet({
    required this.docId,
    required this.docType,
    required this.onDone,
  });

  @override
  State<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<_StatusUpdateSheet> {
  final _reasonCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  bool _loading = false;
  String? _chosen;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_chosen == null) return;
    final ctrl = HomeCtrl.to;
    setState(() => _loading = true);
    bool ok;
    if (_chosen == 'Completed') {
      ok = widget.docType == 'appointment'
          ? await ctrl.completeAppointment(
              docId: widget.docId,
              summary: _summaryCtrl.text.trim(),
            )
          : await ctrl.completeMeeting(
              docId: widget.docId,
              summary: _summaryCtrl.text.trim(),
            );
    } else {
      // if (_reasonCtrl.text.trim().isEmpty) {
      //   setState(() => _loading = false);
      //   AppSnackbar.error(context, 'Please enter a cancellation reason.');
      //   return;
      // }
      ok = widget.docType == 'appointment'
          ? await ctrl.cancelAppointment(
              docId: widget.docId,
              reason: _reasonCtrl.text.trim(),
            )
          : await ctrl.cancelMeeting(
              docId: widget.docId,
              reason: _reasonCtrl.text.trim(),
            );
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context);
      widget.onDone();
      AppSnackbar.success(
        context,
        '${widget.docType == 'appointment' ? 'Appointment' : 'Task'} marked as $_chosen.',
      );
    } else {
      AppSnackbar.error(context, 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      // margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 244, 244, 244),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
              'Update Status',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DrColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select the new status for this ${widget.docType}.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DrColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatusChoiceCard(
                    label: 'Completed',
                    icon: Icons.check_circle_rounded,
                    color: DrColors.success,
                    selected: _chosen == 'Completed',
                    onTap: () => setState(() => _chosen = 'Completed'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusChoiceCard(
                    label: 'Cancelled',
                    icon: Icons.cancel_rounded,
                    color: DrColors.error,
                    selected: _chosen == 'Cancelled',
                    onTap: () => setState(() => _chosen = 'Cancelled'),
                  ),
                ),
              ],
            ),
            if (_chosen == 'Completed') ...[
              const SizedBox(height: 16),
              Text(
                'Summary (optional)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DrColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _summaryCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: DrColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Brief summary of the ${widget.docType}...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: DrColors.textTertiary,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
            if (_chosen == 'Cancelled') ...[
              const SizedBox(height: 16),
              Text(
                'Cancellation Reason (optional)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DrColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: DrColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Reason for cancellation...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: DrColors.textTertiary,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_chosen == null || _loading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _chosen == 'Cancelled'
                      ? DrColors.error
                      : _chosen == 'Completed'
                      ? DrColors.success
                      : DrColors.primary,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _chosen == null
                            ? 'Select a Status'
                            : 'Mark as $_chosen',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChoiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChoiceCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.10) : DrColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : DrColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? color : DrColors.textTertiary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : DrColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Chip for calls/whatsapp
// ─────────────────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        highlightColor: color.withOpacity(0.12),
        splashColor: color.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.18), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
