import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../controllers/home_ctrl.dart';
import '../../../../models/app_meet_model.dart';
import '../../../../utils/app_theme.dart';
import '../../../../widgets/app_snackbar.dart';
import '../appointments/appointment_form.dart';
import '../contacts/contacts_view.dart';
import '../contacts/contact_detail_view.dart';

class AppointmentsView extends StatefulWidget {
  const AppointmentsView({super.key});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView> {
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _dateRange;
  String _statusFilter = 'All';
  bool _isRangeMode = false;

  // Fetched items (via .get()) for the selected date or date range
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
    final results = await HomeCtrl.to.fetchAppointmentsForDate(date);
    if (mounted)
      setState(() {
        _fetched = results;
        _loading = false;
      });
  }

  Future<void> _fetchForRange(DateTimeRange range) async {
    setState(() => _loading = true);
    final results = await HomeCtrl.to.fetchAppointmentsForRange(
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
    return _fetched.where((a) => a.status == _statusFilter).toList();
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
                              'Appointments',
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
                                  color: DrColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              GetBuilder<HomeCtrl>(
                                builder: (ctrl) => Text(
                                  '${ctrl.appointmentsForDate(DateTime.now()).length} scheduled today',
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
                                  color: DrColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: DrColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Clear Range',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: DrColors.primary,
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
                                      color: DrColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Range',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: DrColors.primary,
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
                                    ? DrColors.primary
                                    : DrColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? DrColors.primary
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
                                  ? DrColors.primary
                                  : DrColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? DrColors.primary
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
                        color: DrColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 48,
                            color: DrColors.textTertiary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No appointments',
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
                      itemBuilder: (_, i) => _AppointmentCard(
                        appt: _filtered[i],
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

// ─── Appointment Card ─────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final AppointmentMeetingModel appt;
  final VoidCallback onRefresh;
  const _AppointmentCard({required this.appt, required this.onRefresh});

  String _statusLabel() {
    if (appt.status == 'Cancelled') return 'Cancelled';
    if (appt.status == 'Completed') return 'Completed';
    final now = DateTime.now();
    final diff = appt.startTime.difference(now);
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
    return DrColors.primary;
  }

  Color get _accentColor {
    if (appt.status == 'Cancelled') return DrColors.error;
    if (appt.status == 'Completed') return DrColors.success;
    return DrColors.primary;
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppointmentFormSheet(appointment: appt),
    ).then((_) => onRefresh());
  }

  void _showStatusMenu(BuildContext context) {
    final isCancelled = appt.status == 'Cancelled';
    final isCompleted = appt.status == 'Completed';
    if (isCancelled || isCompleted) {
      AppSnackbar.info(
        context,
        'This appointment is already ${appt.status.toLowerCase()}.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusUpdateSheet(
        docId: appt.docId,
        docType: 'appointment',
        onDone: onRefresh,
      ),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    print("Clicked====================================");
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
                            'Appointment Detail',
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
                const SizedBox(height: 24),
                _buildDetailRow(
                  Icons.person_outline_rounded,
                  'Patient',
                  appt.personName,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.calendar_today_rounded,
                  'Date & Time',
                  '${DateFormat('EEEE, MMM d, yyyy').format(appt.startTime)}\n${DateFormat('hh:mm a').format(appt.startTime)} - ${DateFormat('hh:mm a').format(appt.endTime)}',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.category_outlined,
                  'Type',
                  appt.type.replaceAll('_', ' ').toUpperCase(),
                ),
                if ((appt.shortDescription ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.title_rounded,
                    'Title / Description',
                    appt.shortDescription!,
                  ),
                ],
                if ((appt.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.notes_rounded,
                    'Notes',
                    appt.description!,
                  ),
                ],
                if (appt.status == 'Completed' &&
                    (appt.summary ?? '').isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionBlock(
                    title: 'Completion Summary',
                    content: appt.summary!,
                    icon: Icons.check_circle_outline_rounded,
                    color: DrColors.success,
                  ),
                ],
                if (appt.status == 'Cancelled' &&
                    (appt.cancellationReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionBlock(
                    title: 'Cancellation Reason',
                    content: appt.cancellationReason!,
                    icon: Icons.cancel_outlined,
                    color: DrColors.error,
                  ),
                ],
                const SizedBox(height: 24),
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
                              appt.personId,
                              appt.personName,
                              appt.personPhone,
                              appt.personEmail,
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
            color: DrColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: DrColors.primary),
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
    final showActions =
        appt.status != 'Completed' && appt.status != 'Cancelled';
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
            onTap: () {
              print("=================appt.personName=APP=>" + appt.personName);
              _showDetailsDialog(context);
            },
            borderRadius: showActions
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 44,
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
                          appt.personName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DrColors.textPrimary,
                          ),
                        ),
                        if ((appt.shortDescription ?? '').isNotEmpty)
                          Text(
                            appt.shortDescription!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: DrColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            appt.type.replaceAll('_', ' '),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: DrColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(appt.startTime),
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
                      color: DrColors.primary,
                      onTap: () => _openEdit(context),
                    ),
                  ),
                  Container(width: 1, height: 22, color: DrColors.border),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.update_rounded,
                      label: 'Update',
                      color: appt.status == 'Scheduled'
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
  final String docType; // 'appointment' or 'meeting'
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
  String? _chosen; // 'Completed' or 'Cancelled'

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
      if (widget.docType == 'appointment') {
        ok = await ctrl.completeAppointment(
          docId: widget.docId,
          summary: _summaryCtrl.text.trim(),
        );
      } else {
        ok = await ctrl.completeMeeting(
          docId: widget.docId,
          summary: _summaryCtrl.text.trim(),
        );
      }
    } else {
      // if (_reasonCtrl.text.trim().isEmpty) {
      //   setState(() => _loading = false);
      //   AppSnackbar.error(context, 'Please enter a cancellation reason.');
      //   return;
      // }
      if (widget.docType == 'appointment') {
        ok = await ctrl.cancelAppointment(
          docId: widget.docId,
          reason: _reasonCtrl.text.trim(),
        );
      } else {
        ok = await ctrl.cancelMeeting(
          docId: widget.docId,
          reason: _reasonCtrl.text.trim(),
        );
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context);
      widget.onDone();
      AppSnackbar.success(
        context,
        '${widget.docType == 'appointment' ? 'Appointment' : 'Meeting'} marked as $_chosen.',
      );
    } else {
      AppSnackbar.error(context, 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

            // Status choice buttons
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
