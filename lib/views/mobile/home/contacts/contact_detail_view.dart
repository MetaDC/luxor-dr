import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../controllers/auth_ctrl.dart';
import '../../../../controllers/home_ctrl.dart';
import '../../../../models/app_meet_model.dart';
import '../../../../utils/app_theme.dart';
import 'contacts_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ContactDetailView
// ─────────────────────────────────────────────────────────────────────────────

enum _RecordTab { upcoming, history }

class ContactDetailView extends StatefulWidget {
  final ContactEntry contact;
  const ContactDetailView({super.key, required this.contact});

  @override
  State<ContactDetailView> createState() => _ContactDetailViewState();
}

class _ContactDetailViewState extends State<ContactDetailView> {
  _RecordTab _tab = _RecordTab.upcoming;
  // Default to today
  DateTime _selectedDate = DateTime.now();
  List<AppointmentMeetingModel> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    final result = await HomeCtrl.to.fetchRecordsForPersonOnDate(
      personId: widget.contact.id,
      doctorId: doctorId,
      date: _selectedDate,
    );
    if (!mounted) return;
    setState(() {
      _records = result;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: DrColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      await _load();
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  List<AppointmentMeetingModel> get _filtered {
    final now = DateTime.now();
    if (_tab == _RecordTab.upcoming) {
      // Scheduled items that haven't started yet (or are in progress today)
      return _records
          .where(
            (r) =>
                r.status == 'Scheduled' &&
                (r.endTime.isAfter(now) || !_isToday),
          )
          .toList();
    } else {
      // Completed, Cancelled, or already passed
      return _records
          .where(
            (r) =>
                r.status != 'Scheduled' ||
                (r.endTime.isBefore(now) && _isToday),
          )
          .toList();
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    final filtered = _filtered;
    final upcomingCount = _records
        .where((r) => r.status == 'Scheduled' &&
            (r.endTime.isAfter(DateTime.now()) || !_isToday))
        .length;
    final historyCount = _records.length - upcomingCount;

    return Scaffold(
      backgroundColor: DrColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Back button ──────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: DrColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DrColors.border, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: DrColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Contact card ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DrColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DrColors.border, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar (Modern Circle with soft accent color)
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: contact.typeColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              contact.initials,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: contact.typeColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      contact.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: DrColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: contact.typeColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      contact.typeLabel.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: contact.typeColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (contact.email.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 13,
                                      color: DrColors.textTertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        contact.email,
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
                              if (contact.phone.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 13,
                                      color: DrColors.textTertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      contact.phone,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: DrColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (contact.phone.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _call(contact.phone),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: DrColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.call_rounded,
                                size: 16,
                                color: DrColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Date selector ────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: DrColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: DrColors.primary.withValues(alpha: 0.12),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: DrColors.primaryDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isToday
                                    ? 'Today'
                                    : DateFormat('MMM d, yyyy')
                                        .format(_selectedDate),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: DrColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 14,
                                color: DrColors.primaryDark.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!_isToday) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(
                              () => _selectedDate = DateTime.now(),
                            );
                            _load();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: DrColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: DrColors.border),
                            ),
                            child: Text(
                              'Back to today',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: DrColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Refresh
                      GestureDetector(
                        onTap: _load,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DrColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DrColors.border, width: 0.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: DrColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Upcoming / History tabs ──────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Upcoming',
                          count: upcomingCount,
                          active: _tab == _RecordTab.upcoming,
                          onTap: () =>
                              setState(() => _tab = _RecordTab.upcoming),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TabButton(
                          label: 'History',
                          count: historyCount,
                          active: _tab == _RecordTab.history,
                          onTap: () =>
                              setState(() => _tab = _RecordTab.history),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Records list ────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DrColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : filtered.isEmpty
                  ? _EmptyRecords(tab: _tab, isToday: _isToday)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _RecordCard(record: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab button
// ─────────────────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? DrColors.primary.withValues(alpha: 0.08)
              : DrColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: active
              ? Border.all(
                  color: DrColors.primary.withValues(alpha: 0.15),
                  width: 0.5,
                )
              : Border.all(color: DrColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? DrColors.primaryDark : DrColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? DrColors.primary.withValues(alpha: 0.15)
                    : DrColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? DrColors.primaryDark : DrColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Record card
// ─────────────────────────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final AppointmentMeetingModel record;
  const _RecordCard({required this.record});

  bool get _isAppt => record.docType == 'appointment';

  Color get _accentColor {
    if (record.status == 'Cancelled') return DrColors.error;
    if (record.status == 'Completed') return DrColors.success;
    return _isAppt ? DrColors.primary : DrColors.accent;
  }

  String get _title {
    if (_isAppt) {
      final sd = record.shortDescription;
      return (sd != null && sd.isNotEmpty)
          ? sd
          : record.type.replaceAll('_', ' ');
    }
    final sd = record.shortDescription;
    return (sd != null && sd.isNotEmpty) ? sd : 'Meeting';
  }

  String get _subtitle {
    if (_isAppt) return record.type.replaceAll('_', ' ');
    final desc = record.description;
    return (desc != null && desc.isNotEmpty) ? desc : '';
  }

  String get _statusLabel {
    if (record.status == 'Cancelled') return 'Cancelled';
    if (record.status == 'Completed') return 'Completed';
    final now = DateTime.now();
    if (record.startTime.isAfter(now)) {
      final diff = record.startTime.difference(now);
      if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
      return 'In ${diff.inHours}h';
    }
    if (record.endTime.isAfter(now)) return 'In progress';
    return 'Passed';
  }

  Color _statusColor() {
    final label = _statusLabel;
    if (label == 'Passed' || label == 'Cancelled') return DrColors.textTertiary;
    if (label == 'In progress' || label.startsWith('In ')) {
      return _isAppt ? DrColors.primary : DrColors.accent;
    }
    if (label == 'Completed') return DrColors.success;
    return _isAppt ? DrColors.primary : DrColors.accent;
  }

  void _showDetailsDialog(BuildContext context) {
    final statusColor = _statusColor();
    final themeColor = _isAppt ? DrColors.primary : DrColors.accent;

    final hasSummary = record.status == 'Completed' && (record.summary ?? '').isNotEmpty;
    final hasCancellation = record.status == 'Cancelled' && (record.cancellationReason ?? '').isNotEmpty;
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
                          _isAppt ? 'Appointment Detail' : 'Meeting Detail',
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
                              label: _statusLabel,
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
                              DateFormat('EEEE, MMMM d, yyyy').format(record.startTime),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: DrColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('hh:mm a').format(record.startTime)} - ${DateFormat('hh:mm a').format(record.endTime)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: DrColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTimelineItem(
                        icon: _isAppt ? Icons.person_rounded : Icons.groups_rounded,
                        label: _isAppt ? 'Patient' : 'Meeting Person',
                        themeColor: themeColor,
                        isLast: false,
                        content: Text(
                          record.personName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DrColors.textPrimary,
                          ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                record.type.replaceAll('_', ' ').toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: themeColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if ((record.shortDescription ?? '').isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                record.shortDescription!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: DrColors.textPrimary,
                                ),
                              ),
                            ],
                            if ((record.description ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                record.description!,
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
                            record.summary!,
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
                            record.cancellationReason!,
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DrColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
            ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: themeColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: DrColors.border.withValues(alpha: 0.6),
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
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DrColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showDetailsDialog(context),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3.5, color: _accentColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _isAppt ? 'Appointment' : 'Meeting',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _accentColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: DrColors.textPrimary,
                                ),
                              ),
                              if (_subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: DrColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (record.status == 'Cancelled' &&
                                  record.cancellationReason != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Reason: ${record.cancellationReason}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: DrColors.error,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (record.status == 'Completed' &&
                                  (record.summary?.isNotEmpty ?? false)) ...[
                                const SizedBox(height: 4),
                                Text(
                                  record.summary!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: DrColors.success,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(record.startTime),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: DrColors.textPrimary,
                              ),
                            ),
                            if (record.endTime.isAfter(record.startTime))
                              Text(
                                '– ${DateFormat('HH:mm').format(record.endTime)}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: DrColors.textTertiary,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _statusLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _accentColor,
                                ),
                              ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyRecords extends StatelessWidget {
  final _RecordTab tab;
  final bool isToday;
  const _EmptyRecords({required this.tab, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final icon = tab == _RecordTab.upcoming
        ? Icons.event_available_rounded
        : Icons.history_rounded;
    final title = tab == _RecordTab.upcoming
        ? 'No upcoming records'
        : 'No history for this day';
    final subtitle = tab == _RecordTab.upcoming
        ? isToday
            ? 'No appointments or meetings scheduled for today'
            : 'Nothing scheduled for this day'
        : 'No completed or cancelled records on this day';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: DrColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: DrColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DrColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: DrColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
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
