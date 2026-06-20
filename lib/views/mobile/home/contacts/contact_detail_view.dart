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
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DrColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: DrColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Contact card ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [DrColors.gradStart, DrColors.gradEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              contact.initials,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
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
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      contact.typeLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (contact.email.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 11,
                                      color: Colors.white60,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        contact.email,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (contact.phone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () => _call(contact.phone),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.20),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.call_rounded,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        contact.phone,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          decoration:
                                              TextDecoration.underline,
                                          decorationColor: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
                            gradient: const LinearGradient(
                              colors: [DrColors.gradStart, DrColors.gradEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: Colors.white,
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
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 14,
                                color: Colors.white70,
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
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: DrColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: DrColors.border),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            size: 16,
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
          gradient: active
              ? const LinearGradient(
                  colors: [DrColors.gradStart, DrColors.gradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : DrColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: active ? null : Border.all(color: DrColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : DrColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : DrColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : DrColors.textTertiary,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DrColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: _accentColor),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: 0.10),
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
                            const SizedBox(height: 5),
                            Text(
                              _title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
                              const SizedBox(height: 3),
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
                              const SizedBox(height: 3),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
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
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(5),
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
