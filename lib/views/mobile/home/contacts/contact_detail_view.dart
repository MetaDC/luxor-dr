import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/app_meet_model.dart';
import '../../../../utils/app_theme.dart';
import '../../../../utils/phone_helper.dart';
import 'contacts_view.dart';
import '../appointments/appointment_form.dart';
import '../meetings/meeting_form.dart';
import '../../../../models/patient_model.dart';
import '../../../../models/meeting_per_model.dart';
import '../../../../utils/firebase.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ContactDetailView
// ─────────────────────────────────────────────────────────────────────────────

import '../../../../widgets/form_date_time_pickers.dart'; // ─────────────────────────────────────────────────────────────────────────────
// ContactDetailView
// ─────────────────────────────────────────────────────────────────────────────

enum _TimeFilter { upcoming, today, thisWeek, thisMonth, custom }

class ContactDetailView extends StatefulWidget {
  final ContactEntry contact;
  const ContactDetailView({super.key, required this.contact});

  @override
  State<ContactDetailView> createState() => _ContactDetailViewState();
}

class _ContactDetailViewState extends State<ContactDetailView> {
  late ContactEntry _contact;
  final ScrollController _scrollController = ScrollController();

  _TimeFilter _filter = _TimeFilter.upcoming;
  DateTimeRange? _customRange;

  List<AppointmentMeetingModel> _records = [];
  bool _loading = false;
  bool _loadingMore = false;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage(isLoadMore: true);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _records.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    await _loadNextPage();
  }

  Future<void> _loadNextPage({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else {
      if (_loading) return;
      setState(() => _loading = true);
    }

    try {
      final now = DateTime.now();
      Query<Map<String, dynamic>> query = FBFireStore.apptAndMeeting.where(
        'personId',
        isEqualTo: _contact.id,
      );

      switch (_filter) {
        case _TimeFilter.upcoming:
          query = query.where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now),
          );
          break;
        case _TimeFilter.today:
          final start = DateTime(now.year, now.month, now.day);
          final end = start.add(const Duration(days: 1));
          query = query
              .where(
                'startTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('startTime', isLessThan: Timestamp.fromDate(end));
          break;
        case _TimeFilter.thisWeek:
          final start = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: now.weekday - 1));
          final end = start.add(const Duration(days: 7));
          query = query
              .where(
                'startTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('startTime', isLessThan: Timestamp.fromDate(end));
          break;
        case _TimeFilter.thisMonth:
          final start = DateTime(now.year, now.month, 1);
          final end = DateTime(now.year, now.month + 1, 1);
          query = query
              .where(
                'startTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('startTime', isLessThan: Timestamp.fromDate(end));
          break;
        case _TimeFilter.custom:
          if (_customRange != null) {
            final start = DateTime(
              _customRange!.start.year,
              _customRange!.start.month,
              _customRange!.start.day,
            );
            final end = DateTime(
              _customRange!.end.year,
              _customRange!.end.month,
              _customRange!.end.day,
            ).add(const Duration(days: 1));
            query = query
                .where(
                  'startTime',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(start),
                )
                .where('startTime', isLessThan: Timestamp.fromDate(end));
          } else {
            setState(() {
              if (isLoadMore) {
                _loadingMore = false;
              } else {
                _loading = false;
              }
            });
            return;
          }
          break;
      }

      query = query.orderBy('startTime', descending: true).limit(_pageSize);

      if (isLoadMore && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snap = await query.get();
      var items = snap.docs
          .map(AppointmentMeetingModel.fromQueryDocumentSnapshot)
          .toList();

      if (_filter == _TimeFilter.upcoming) {
        items = items.where((e) => e.status == 'Scheduled').toList();
      }

      if (!mounted) return;

      setState(() {
        if (isLoadMore) {
          _records.addAll(items);
          _loadingMore = false;
        } else {
          _records = items;
          _loading = false;
        }
        _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
        _hasMore = items.length == _pageSize;
      });
    } on FirebaseException catch (e) {
      debugPrint('Firestore Error (Check if index is required): $e');
      if (e.message != null &&
          e.message!.contains('https://console.firebase.google.com')) {
        debugPrint('Index Required! Click here to create it:');
        final startIndex = e.message!.indexOf('https://');
        if (startIndex != -1) {
          final url = e.message!.substring(startIndex);
          debugPrint(url);
        }
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading records: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _changeFilter(_TimeFilter newFilter) async {
    if (newFilter == _TimeFilter.custom) {
      final picked = await Navigator.push<DateTimeRange>(
        context,
        MaterialPageRoute(
          builder: (_) => FullScreenDateRangePicker(initialRange: _customRange),
          fullscreenDialog: true,
        ),
      );
      if (picked == null) return;
      setState(() {
        _customRange = picked;
        _filter = _TimeFilter.custom;
        _records.clear();
        _lastDoc = null;
        _hasMore = true;
      });
      _loadNextPage();
    } else {
      setState(() {
        _filter = newFilter;
        _records.clear();
        _lastDoc = null;
        _hasMore = true;
      });
      _loadNextPage();
    }
  }

  Future<void> _addAppointment() async {
    final snap = await FBFireStore.patients.doc(_contact.id).get();
    if (!snap.exists || !mounted) return;
    final patient = PatientModel.fromJson(snap.data()!);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentFormSheet(initialPatient: patient),
        fullscreenDialog: true,
      ),
    ).then((_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _addTask() async {
    final snap = await FBFireStore.meetingPersons.doc(_contact.id).get();
    if (!snap.exists || !mounted) return;
    final person = MeetingPersonModel.fromJson(snap.data()!);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingFormSheet(initialPerson: person),
        fullscreenDialog: true,
      ),
    ).then((_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _editContact() async {
    final snap = await FBFireStore.patients.doc(_contact.id).get();
    if (!snap.exists || !mounted) return;
    final patient = PatientModel.fromJson(snap.data()!);
    if (!mounted) return;
    final result = await showDialog<PatientModel>(
      context: context,
      builder: (_) => PatientFormDialog(patient: patient),
    );
    if (result != null && mounted) {
      setState(() {
        _contact = ContactEntry(
          id: result.docId,
          name: result.name,
          email: result.email,
          phone: result.phone,
        );
      });
    }
  }

  List<DropdownMenuItem<_TimeFilter>> _buildDropdownItems() {
    return [
      const DropdownMenuItem(
        value: _TimeFilter.upcoming,
        child: Text('Upcoming'),
      ),
      const DropdownMenuItem(value: _TimeFilter.today, child: Text('Today')),
      const DropdownMenuItem(
        value: _TimeFilter.thisWeek,
        child: Text('This Week'),
      ),
      const DropdownMenuItem(
        value: _TimeFilter.thisMonth,
        child: Text('This Month'),
      ),
      DropdownMenuItem(
        value: _TimeFilter.custom,
        child: Text(
          _customRange == null
              ? 'Custom Range'
              : 'Custom: ${DateFormat('MMM d').format(_customRange!.start)} – ${DateFormat('MMM d').format(_customRange!.end)}',
        ),
      ),
    ];
  }

  Future<void> _call(String phone) async {
    final cleaned = cleanPhoneNumber(phone);
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsapp(String phone) async {
    try {
      var cleaned = cleanPhoneNumber(phone);
      if (cleaned.isEmpty) return;
      if (cleaned.startsWith('+')) {
        cleaned = cleaned.substring(1);
      }
      final uri = Uri.parse('https://wa.me/$cleaned');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = _contact;
    final filtered = _records;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _contact);
      },
      child: Scaffold(
        backgroundColor: DrColors.background,
        appBar: AppBar(
          backgroundColor: DrColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context, _contact),
          ),
          title: Text(
            'Patient Profile',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: _editContact,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Contact card ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: DrColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: DrColors.border.withValues(alpha: 0.8),
                        width: 0.5,
                      ),
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: Colors.black.withValues(alpha: 0.03),
                      //     blurRadius: 12,
                      //     offset: const Offset(0, 4),
                      //   ),
                      // ],
                    ),
                    child: Row(
                      children: [
                        // Avatar (Modern Circle with soft accent color)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: contact.typeColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              contact.initials,
                              style: GoogleFonts.inter(
                                fontSize: 18,
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
                              Text(
                                contact.name,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: DrColors.textPrimary,
                                ),
                              ),
                              if (contact.email.isNotEmpty) ...[
                                const SizedBox(height: 6),
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
                                const SizedBox(height: 4),
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
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: DrColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.call_rounded,
                                size: 18,
                                color: DrColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _whatsapp(contact.phone),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF25D366,
                                ).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/whatsapp.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: DrColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DrColors.border.withValues(alpha: 0.8),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<_TimeFilter>(
                              dropdownColor: Colors.white,
                              value: _filter,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: DrColors.textSecondary,
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DrColors.textPrimary,
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  _changeFilter(val);
                                }
                              },
                              items: _buildDropdownItems(),
                            ),
                          ),
                        ),
                      ),
                      if (_filter == _TimeFilter.custom &&
                          _customRange != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _changeFilter(_TimeFilter.custom),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: DrColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: DrColors.primary.withValues(alpha: 0.12),
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: DrColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            Divider(height: 0),

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
                  ? _EmptyRecords(filter: _filter, customRange: _customRange)
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      itemCount: filtered.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        if (i == filtered.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: DrColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        }
                        final record = filtered[i];
                        final DateTime currentDate = _dateOnly(
                          record.startTime,
                        );
                        bool showHeader = false;
                        if (i == 0) {
                          showHeader = true;
                        } else {
                          final prevRecord = filtered[i - 1];
                          final DateTime prevDate = _dateOnly(
                            prevRecord.startTime,
                          );
                          if (currentDate != prevDate) {
                            showHeader = true;
                          }
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showHeader)
                              _DateHeader(
                                label: _formatDateHeader(record.startTime),
                              ),
                            _RecordCard(record: record),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: DrColors.border, width: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _addTask,
                    child: Text(
                      'ADD TASK',
                      style: GoogleFonts.inter(
                        color: DrColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: DrColors.border),
                Expanded(
                  child: TextButton(
                    onPressed: _addAppointment,
                    child: Text(
                      'ADD APPOINTMENT',
                      style: GoogleFonts.inter(
                        color: DrColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
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

    final hasSummary =
        record.status == 'Completed' && (record.summary ?? '').isNotEmpty;
    final hasCancellation =
        record.status == 'Cancelled' &&
        (record.cancellationReason ?? '').isNotEmpty;
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
                              DateFormat(
                                'EEEE, MMMM d, yyyy',
                              ).format(record.startTime),
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
                        icon: _isAppt
                            ? Icons.person_rounded
                            : Icons.groups_rounded,
                        label: _isAppt ? 'Patient' : 'Person',
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
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
              child: Icon(icon, size: 18, color: themeColor),
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
        border: Border.all(
          color: DrColors.border.withValues(alpha: 0.8),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
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
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                  _isAppt ? 'Appointment' : 'Task',
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
                          mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: DrColors.textTertiary,
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
  final _TimeFilter filter;
  final DateTimeRange? customRange;
  const _EmptyRecords({required this.filter, this.customRange});

  @override
  Widget build(BuildContext context) {
    final icon = filter == _TimeFilter.upcoming
        ? Icons.event_available_rounded
        : Icons.history_rounded;
    String title = 'No records';
    String subtitle = 'No appointments or tasks found.';

    switch (filter) {
      case _TimeFilter.upcoming:
        title = 'No upcoming records';
        subtitle = 'Nothing scheduled for the future.';
        break;
      case _TimeFilter.today:
        title = 'No records for today';
        subtitle = 'No appointments or tasks scheduled for today.';
        break;
      case _TimeFilter.thisWeek:
        title = 'No records for this week';
        subtitle = 'No appointments or tasks scheduled for this week.';
        break;
      case _TimeFilter.thisMonth:
        title = 'No records for this month';
        subtitle = 'No appointments or tasks scheduled for this month.';
        break;
      case _TimeFilter.custom:
        final dateStr = customRange != null
            ? '${DateFormat('MMMM d').format(customRange!.start)} – ${DateFormat('MMMM d').format(customRange!.end)}'
            : 'this range';
        title = 'No records for $dateStr';
        subtitle = 'No appointments or tasks scheduled for this range.';
        break;
    }

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

// ─────────────────────────────────────────────────────────────────────────────
// _DateHeader & Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: DrColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _formatDateHeader(DateTime date) {
  final now = DateTime.now();
  final today = _dateOnly(now);
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));

  final headerDate = _dateOnly(date);
  if (headerDate == today) {
    return 'Today · ${DateFormat('MMMM d, yyyy').format(date)}';
  } else if (headerDate == yesterday) {
    return 'Yesterday · ${DateFormat('MMMM d, yyyy').format(date)}';
  } else if (headerDate == tomorrow) {
    return 'Tomorrow · ${DateFormat('MMMM d, yyyy').format(date)}';
  }
  return DateFormat('EEEE, MMMM d, yyyy').format(date);
}
