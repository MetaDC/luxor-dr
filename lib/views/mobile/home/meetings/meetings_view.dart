import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../controllers/home_ctrl.dart';
import '../../../../models/app_meet_model.dart';
import '../../../../utils/app_theme.dart';
import '../../../../widgets/app_snackbar.dart';
import '../meetings/meeting_form.dart';
import '../contacts/contacts_view.dart';
import '../contacts/contact_detail_view.dart';

class MeetingsView extends StatefulWidget {
  const MeetingsView({super.key});

  @override
  State<MeetingsView> createState() => _MeetingsViewState();
}

class _MeetingsViewState extends State<MeetingsView> {
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _dateRange;
  String _statusFilter = 'All';
  bool _isRangeMode = false;

  List<AppointmentMeetingModel> _fetched = [];
  bool _loading = false;

  static const _statuses = ['All', 'Scheduled', 'Completed', 'Cancelled'];

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
    _fetchForDate(_selectedDate);
  }

  Future<void> _fetchForDate(DateTime date) async {
    setState(() => _loading = true);
    final results = await HomeCtrl.to.fetchMeetingsForDate(date);
    if (mounted)
      setState(() {
        _fetched = results;
        _loading = false;
      });
  }

  Future<void> _fetchForRange(DateTimeRange range) async {
    setState(() => _loading = true);
    final results = await HomeCtrl.to.fetchMeetingsForRange(
      range.start,
      range.end,
    );
    if (mounted)
      setState(() {
        _fetched = results;
        _loading = false;
      });
  }

  List<AppointmentMeetingModel> get _filtered {
    if (_statusFilter == 'All') return _fetched;
    return _fetched.where((m) => m.status == _statusFilter).toList();
  }

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
          colorScheme: const ColorScheme.light(primary: DrColors.accent),
        ),
        child: child!,
      ),
    );
    if (range != null && mounted) {
      setState(() {
        _dateRange = range;
        _isRangeMode = true;
      });
      await _fetchForRange(range);
    }
  }

  void _clearRange() {
    setState(() {
      _dateRange = null;
      _isRangeMode = false;
    });
    _fetchForDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final dates = _weekDates();
    return Scaffold(
      backgroundColor: DrColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meetings',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: DrColors.textPrimary,
                              ),
                            ),
                            if (_isRangeMode && _dateRange != null)
                              Text(
                                '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d').format(_dateRange!.end)}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: DrColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              GetBuilder<HomeCtrl>(
                                builder: (ctrl) => Text(
                                  '${ctrl.meetingsForDate(DateTime.now()).length} scheduled today',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: DrColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Date range button
                      _isRangeMode
                          ? GestureDetector(
                              onTap: _clearRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: DrColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: DrColors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Clear Range',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: DrColors.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: _pickDateRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: DrColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: DrColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.date_range_rounded,
                                      size: 14,
                                      color: DrColors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Range',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: DrColors.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Week Date Selector (hidden in range mode) ────────
                  if (!_isRangeMode)
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: dates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = dates[i];
                          final isSelected =
                              d.year == _selectedDate.year &&
                              d.month == _selectedDate.month &&
                              d.day == _selectedDate.day;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedDate = d);
                              _fetchForDate(d);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DrColors.accent
                                    : DrColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? DrColors.accent
                                      : DrColors.border,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(d).toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white70
                                          : DrColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${d.day}',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : DrColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM').format(d),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
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

                  const SizedBox(height: 12),

                  // ── Status Filter Chips ──────────────────────────────
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statuses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final s = _statuses[i];
                        final active = _statusFilter == s;
                        return GestureDetector(
                          onTap: () => setState(() => _statusFilter = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? DrColors.accent
                                  : DrColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? DrColors.accent
                                    : DrColors.border,
                              ),
                            ),
                            child: Text(
                              s,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : DrColors.textSecondary,
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
            const SizedBox(height: 10),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DrColors.accent,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 48,
                            color: DrColors.textTertiary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No meetings',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: DrColors.textSecondary,
                            ),
                          ),
                          if (_statusFilter != 'All')
                            TextButton(
                              onPressed: () =>
                                  setState(() => _statusFilter = 'All'),
                              child: const Text('Clear filter'),
                            ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _MeetingCard(
                        meeting: _filtered[i],
                        onRefresh: _isRangeMode
                            ? () => _fetchForRange(_dateRange!)
                            : () => _fetchForDate(_selectedDate),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Meeting Card ─────────────────────────────────────────────────────────────

class _MeetingCard extends StatelessWidget {
  final AppointmentMeetingModel meeting;
  final VoidCallback onRefresh;
  const _MeetingCard({required this.meeting, required this.onRefresh});

  String _statusLabel() {
    if (meeting.status == 'Cancelled') return 'Cancelled';
    if (meeting.status == 'Completed') return 'Completed';
    final now = DateTime.now();
    final diff = meeting.startTime.difference(now);
    if (diff.inMinutes < -15) return 'Passed';
    if (diff.inMinutes < 0) return 'Just passed';
    final h = diff.inHours;
    if (h == 0) return 'In ${diff.inMinutes} min';
    return 'In $h hour${h == 1 ? '' : 's'}';
  }

  Color _statusColor() {
    final label = _statusLabel();
    if (label == 'Passed' || label == 'Cancelled') return DrColors.textTertiary;
    if (label == 'Just passed') return DrColors.warning;
    if (label == 'Completed') return DrColors.success;
    return DrColors.accent;
  }

  Color get _accentColor {
    if (meeting.status == 'Cancelled') return DrColors.error;
    if (meeting.status == 'Completed') return DrColors.success;
    return DrColors.accent;
  }

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingFormSheet(meeting: meeting),
        fullscreenDialog: true,
      ),
    ).then((_) => onRefresh());
  }

  void _showStatusMenu(BuildContext context) {
    if (meeting.status == 'Cancelled' || meeting.status == 'Completed') {
      AppSnackbar.info(
        context,
        'This meeting is already ${meeting.status.toLowerCase()}.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      // useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusUpdateSheet(
        docId: meeting.docId,
        docType: 'meeting',
        onDone: onRefresh,
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    final statusColor = _statusColor();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: DrColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
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
                            'Meeting Detail',
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
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: DrColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: DrColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (meeting.personName.isNotEmpty) ...[
                  _buildDetailRow(
                    Icons.groups_outlined,
                    'Meeting Person',
                    meeting.personName,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildDetailRow(
                  Icons.calendar_today_rounded,
                  'Date & Time',
                  '${DateFormat('EEEE, MMM d, yyyy').format(meeting.startTime)}\n${DateFormat('hh:mm a').format(meeting.startTime)} - ${DateFormat('hh:mm a').format(meeting.endTime)}',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.category_outlined,
                  'Type',
                  meeting.type.replaceAll('_', ' ').toUpperCase(),
                ),
                if ((meeting.shortDescription ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.title_rounded,
                    'Title',
                    meeting.shortDescription!,
                  ),
                ],
                if ((meeting.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    'Location / Venue',
                    meeting.description!,
                  ),
                ],
                if (meeting.status == 'Completed' &&
                    (meeting.summary ?? '').isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionBlock(
                    title: 'Completion Summary',
                    content: meeting.summary!,
                    icon: Icons.check_circle_outline_rounded,
                    color: DrColors.success,
                  ),
                ],
                if (meeting.status == 'Cancelled' &&
                    (meeting.cancellationReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionBlock(
                    title: 'Cancellation Reason',
                    content: meeting.cancellationReason!,
                    icon: Icons.cancel_outlined,
                    color: DrColors.error,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (meeting.personId.isNotEmpty) ...[
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _navigateToContactDetail(
                                context,
                                meeting.personId,
                                meeting.personName,
                                meeting.personPhone,
                                meeting.personEmail,
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
                              'Record',
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
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            backgroundColor: DrColors.background,
                            foregroundColor: DrColors.textPrimary,
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: DrColors.accentLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: DrColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: DrColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DrColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionBlock({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: DrColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = meeting.description ?? '';
    final showActions =
        meeting.status != 'Completed' && meeting.status != 'Cancelled';

    final String mainTitle;
    if (meeting.personName.isNotEmpty) {
      mainTitle = meeting.personName;
    } else if ((meeting.shortDescription ?? '').isNotEmpty) {
      mainTitle = meeting.shortDescription!;
    } else {
      mainTitle = meeting.type
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '',
          )
          .join(' ');
    }

    final String? subtitle;
    if (meeting.personName.isNotEmpty) {
      subtitle = (meeting.shortDescription ?? '').isNotEmpty
          ? meeting.shortDescription
          : meeting.type.replaceAll('_', ' ');
    } else if ((meeting.shortDescription ?? '').isNotEmpty) {
      subtitle = meeting.type.replaceAll('_', ' ');
    } else {
      subtitle = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DrColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row wrapped in InkWell
          InkWell(
            onTap: () => _showDetailsDialog(context),
            borderRadius: showActions
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 3.5,
                    height: location.isNotEmpty ? 52 : 44,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mainTitle,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DrColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: DrColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: _accentColor,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(meeting.startTime),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DrColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
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

          // Divider + action buttons
          if (showActions) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      color: DrColors.accent,
                      onTap: () => _openEdit(context),
                    ),
                  ),
                  Container(width: 1, height: 22, color: DrColors.border),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.update_rounded,
                      label: 'Update',
                      color: meeting.status == 'Scheduled'
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
    );
  }
}

// ─── Small reusable widgets ────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
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

// ─── Status Update Bottom Sheet ───────────────────────────────────────────────

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
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String? _submittingAction; // 'Completed' or 'Cancelled'

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String action) async {
    final ctrl = HomeCtrl.to;
    setState(() {
      _loading = true;
      _submittingAction = action;
    });
    bool ok;
    final noteText = _notesCtrl.text.trim();
    if (action == 'Completed') {
      if (widget.docType == 'appointment') {
        ok = await ctrl.completeAppointment(
          docId: widget.docId,
          summary: noteText,
        );
      } else {
        ok = await ctrl.completeMeeting(docId: widget.docId, summary: noteText);
      }
    } else {
      if (widget.docType == 'appointment') {
        ok = await ctrl.cancelAppointment(
          docId: widget.docId,
          reason: noteText,
        );
      } else {
        ok = await ctrl.cancelMeeting(docId: widget.docId, reason: noteText);
      }
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _submittingAction = null;
    });
    if (ok) {
      Navigator.pop(context);
      widget.onDone();
      final label = widget.docType == 'appointment' ? 'Appointment' : 'Task';
      AppSnackbar.success(context, '$label marked as $action.');
    } else {
      AppSnackbar.error(context, 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isAppt = widget.docType == 'appointment';
    final label = isAppt ? 'appointment' : 'task';

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        bottom + 16 + MediaQuery.of(context).padding.bottom,
      ),
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
              'Enter notes and choose to cancel or complete this $label.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DrColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Notes (optional)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DrColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DrColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter notes here...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: DrColors.textTertiary,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _submit('Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DrColors.success,
                  foregroundColor: Colors.white,
                ),
                child: _loading && _submittingAction == 'Completed'
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Complete'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _submit('Cancelled'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DrColors.error,
                  foregroundColor: Colors.white,
                ),
                child: _loading && _submittingAction == 'Cancelled'
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
