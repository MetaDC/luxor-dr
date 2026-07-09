import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luxor_dr/models/doctor_model.dart';
import '../../../../controllers/auth_ctrl.dart';
import '../../../../utils/firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String _statusFilter = 'Scheduled';
  late _TypeFilter _typeFilter;

  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 10;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _realtimeSub;
  List<AppointmentMeetingModel> _fetched = [];
  bool _loading = false;

  static const _statuses = ['Scheduled', 'Completed', 'Cancelled', 'All'];

  List<DateTime> _weekDates() {
    // Find Monday of the week containing _selectedDate (weekday: 1=Mon … 7=Sun)
    final monday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  @override
  void initState() {
    super.initState();
    _initFilters();
    _scrollController.addListener(_onScroll);
    _fetchInitialSchedule();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchNextSchedulePage();
    }
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
      _fetchInitialSchedule();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitialSchedule() async {
    _realtimeSub?.cancel();
    setState(() {
      _loading = true;
      _fetched = [];
      _lastDoc = null;
      _hasMore = true;
      _isLoadingMore = false;
    });

    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final DateTime? end = !_isToday(_selectedDate)
        ? start.add(const Duration(days: 1))
        : null;

    final res = await HomeCtrl.to.fetchSchedulePage(
      docTypeFilter: _typeFilter == _TypeFilter.appointments
          ? 'appointment'
          : _typeFilter == _TypeFilter.meetings
          ? 'meeting'
          : 'all',
      statusFilter: _statusFilter,
      startDateTime: start,
      endDateTime: end,
      limit: _pageSize,
    );

    if (!mounted) return;

    setState(() {
      _fetched = List<AppointmentMeetingModel>.from(res['items']);
      _lastDoc = res['lastDoc'] as DocumentSnapshot?;
      _hasMore = _fetched.length >= _pageSize;
      _loading = false;
    });

    _startRealtimeListener();
  }

  Future<void> _fetchNextSchedulePage() async {
    if (_loading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final DateTime? end = !_isToday(_selectedDate)
        ? start.add(const Duration(days: 1))
        : null;

    final res = await HomeCtrl.to.fetchSchedulePage(
      docTypeFilter: _typeFilter == _TypeFilter.appointments
          ? 'appointment'
          : _typeFilter == _TypeFilter.meetings
          ? 'meeting'
          : 'all',
      statusFilter: _statusFilter,
      startDateTime: start,
      endDateTime: end,
      limit: _pageSize,
      startAfterDoc: _lastDoc,
    );

    if (!mounted) return;

    final newItems = List<AppointmentMeetingModel>.from(res['items']);
    setState(() {
      for (final item in newItems) {
        if (!_fetched.any((e) => e.docId == item.docId)) {
          _fetched.add(item);
        }
      }
      _fetched.sort((a, b) => a.startTime.compareTo(b.startTime));
      _lastDoc = res['lastDoc'] as DocumentSnapshot?;
      _hasMore = newItems.length >= _pageSize;
      _isLoadingMore = false;
    });
  }

  void _startRealtimeListener() {
    _realtimeSub?.cancel();
    final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';
    if (doctorId.isEmpty) return;

    _realtimeSub = FBFireStore.apptAndMeeting
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;

            setState(() {
              for (final change in snap.docChanges) {
                final doc = change.doc;
                final model = AppointmentMeetingModel.fromQueryDocumentSnapshot(
                  doc,
                );

                final matchesType =
                    _typeFilter == _TypeFilter.all ||
                    (_typeFilter == _TypeFilter.appointments &&
                        model.docType == 'appointment') ||
                    (_typeFilter == _TypeFilter.meetings &&
                        model.docType == 'meeting');

                final matchesStatus =
                    _statusFilter == 'All' || model.status == _statusFilter;

                final bool isWithinCurrentView;
                if (!_isToday(_selectedDate)) {
                  isWithinCurrentView =
                      model.startTime.year == _selectedDate.year &&
                      model.startTime.month == _selectedDate.month &&
                      model.startTime.day == _selectedDate.day;
                } else {
                  final start = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                  );
                  isWithinCurrentView =
                      model.startTime.isAtSameMomentAs(start) ||
                      model.startTime.isAfter(start);
                }

                final matchesFilters =
                    matchesType && matchesStatus && isWithinCurrentView;

                if (change.type == DocumentChangeType.removed) {
                  _fetched.removeWhere((e) => e.docId == doc.id);
                } else if (change.type == DocumentChangeType.modified) {
                  final idx = _fetched.indexWhere((e) => e.docId == doc.id);
                  if (idx != -1) {
                    if (matchesFilters) {
                      _fetched[idx] = model;
                    } else {
                      _fetched.removeAt(idx);
                    }
                  } else if (matchesFilters) {
                    _fetched.add(model);
                  }
                } else if (change.type == DocumentChangeType.added) {
                  final exists = _fetched.any((e) => e.docId == doc.id);
                  if (!exists && matchesFilters) {
                    _fetched.add(model);
                  }
                }
              }
              _fetched.sort((a, b) => a.startTime.compareTo(b.startTime));
            });
          },
          onError: (e) {
            debugPrint('Realtime sub error: $e');
          },
        );
  }

  void _refresh() {
    _fetchInitialSchedule();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<AppointmentMeetingModel> get _filtered => _fetched;

  Future<void> _showVerticalCalendarDialog(BuildContext context) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => VerticalCalendarDialog(initialDate: _selectedDate),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchInitialSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = _weekDates();
    final filtered = _filtered;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: DrColors.background,
        appBar: AppBar(
          backgroundColor: DrColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.go('/home'),
          ),
          title: Text(
            'SCHEDULE',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: false,
          actions: [
            GestureDetector(
              onTap: () => _showVerticalCalendarDialog(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                margin: EdgeInsets.only(
                  right: !_isToday(_selectedDate) ? 0 : 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM yy').format(_selectedDate).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            if (!_isToday(_selectedDate))
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime.now();
                  });
                  _fetchInitialSchedule();
                },
                child: Text(
                  'TODAY',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Doctor Selector Dropdown ──────────────────────
                  GetBuilder<AuthCtrl>(
                    builder: (auth) {
                      final doctors = auth.allDoctors;
                      final current = auth.currentDoctor;
                      if (doctors.length <= 1 ||
                          current == null ||
                          !doctors.contains(current)) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: DrColors.primaryLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DrColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonHideUnderline(
                              child: DropdownButton<DoctorModel>(
                                value: current,
                                isExpanded: true,
                                isDense: true,
                                icon: const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: DrColors.primary,
                                ),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: DrColors.textPrimary,
                                  fontSize: 15,
                                ),
                                dropdownColor: DrColors.background,
                                items: doctors.map((doc) {
                                  return DropdownMenuItem<DoctorModel>(
                                    value: doc,
                                    child: Text(
                                      doc.name,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                        color: DrColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newDoc) {
                                  if (newDoc != null && newDoc != current) {
                                    auth.switchDoctor(newDoc);
                                    _fetchInitialSchedule();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // ── Week Date Strip ──────────────────────────────
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dates.length,
                      separatorBuilder: (_, si) => const SizedBox(width: 6),
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
                            _fetchInitialSchedule();
                          },
                          child: Container(
                            width: 46,
                            color: Colors.transparent,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE').format(d),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? DrColors.textPrimary
                                        : DrColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? DrColors.accent
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: isToday && !isSelected
                                        ? Border.all(
                                            color: DrColors.accent,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${d.day}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : isToday
                                            ? DrColors.accent
                                            : DrColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Type filter (segmented) ──────────────────────
                  CupertinoSlidingSegmentedControl<_TypeFilter>(
                    groupValue: _typeFilter,
                    onValueChanged: (v) {
                      if (v != null) {
                        setState(() => _typeFilter = v);
                        _fetchInitialSchedule();
                      }
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
                      separatorBuilder: (_, si) => const SizedBox(width: 5),
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
                          onTap: () {
                            setState(() => _statusFilter = s);
                            _fetchInitialSchedule();
                          },
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

            const SizedBox(height: 6),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: DrColors.primary,
                        size: 32,
                      ),
                    )
                  : filtered.isEmpty
                  ? _EmptyState(
                      hasFilters:
                          _typeFilter != _TypeFilter.all ||
                          _statusFilter != 'Scheduled',
                      onClearFilters: () {
                        setState(() {
                          _typeFilter = _TypeFilter.all;
                          _statusFilter = 'Scheduled';
                        });
                        _fetchInitialSchedule();
                      },
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 32),
                      itemCount: filtered.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, si) => const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: DrColors.border,
                      ),
                      itemBuilder: (_, i) {
                        if (i == filtered.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: DrColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        }

                        final item = filtered[i];
                        final showHeader =
                            i == 0 ||
                            !_isSameDay(
                              item.startTime,
                              filtered[i - 1].startTime,
                            );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showHeader) _DateHeader(date: item.startTime),
                            _ScheduleCard(item: item, onRefresh: _refresh),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MeetingFormSheet(),
                          fullscreenDialog: true,
                        ),
                      ).then((_) => _refresh());
                    },
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppointmentFormSheet(),
                          fullscreenDialog: true,
                        ),
                      ).then((_) => _refresh());
                    },
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
// Date Header Separator
// ─────────────────────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isTomorrow =
        date.year == now.year &&
        date.month == now.month &&
        date.day == (now.day + 1);

    String dateStr;
    if (isToday) {
      dateStr = "Today — ${DateFormat('EEEE, MMMM d').format(date)}";
    } else if (isTomorrow ||
        (date.difference(DateTime(now.year, now.month, now.day)).inDays == 1)) {
      dateStr = "Tomorrow — ${DateFormat('EEEE, MMMM d').format(date)}";
    } else {
      dateStr = DateFormat('EEEE, MMMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isToday
                  ? DrColors.primary.withValues(alpha: 0.3)
                  : DrColors.border,
              thickness: 1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isToday
                  ? DrColors.primary.withValues(alpha: 0.7)
                  : DrColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday
                    ? DrColors.primary.withValues(alpha: 0.7)
                    : DrColors.primary.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Text(
              dateStr.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isToday ? Colors.white : DrColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: isToday
                  ? DrColors.primary.withValues(alpha: 0.3)
                  : DrColors.border,
              thickness: 1,
            ),
          ),
        ],
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

  /*   String get _mainTitle {
    if (item.personName.isNotEmpty) {
      return item.personName;
    }
    if ((item.shortDescription ?? '').isNotEmpty) {
      return item.shortDescription!;
    }
    return item.type
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '',
        )
        .join(' ');
  } */

  // bool get _subtitleIsLocation =>
  //     !_isAppt && (item.description?.isNotEmpty ?? false);

  String _statusLabel() {
    if (item.status == 'Cancelled') return 'Cancelled';
    if (item.status == 'Completed') return 'Completed';
    final now = DateTime.now();
    final diff = item.startTime.difference(now);
    if (diff.inMinutes < -15) return 'Passed';
    if (diff.inMinutes < 0) return 'Missed';
    final h = diff.inHours;
    if (h == 0) return 'In ${diff.inMinutes}m';
    return 'In ${h}h';
  }

  Color _statusColor() {
    final label = _statusLabel();
    if (label == 'Passed' || label == 'Cancelled') return DrColors.textTertiary;
    if (label == 'Missed') return DrColors.warning;
    if (label == 'Completed') return DrColors.success;
    return _typeColor;
  }

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _isAppt
            ? AppointmentFormSheet(appointment: item)
            : MeetingFormSheet(meeting: item),
        fullscreenDialog: true,
      ),
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
    showModalBottomSheet(
      context: context,
      // useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusUpdateSheet(
        docId: item.docId,
        docType: item.docType,
        onDone: onRefresh,
      ),
    );
  }

  void _showDetailsBottomSheet(BuildContext context) {
    final statusColor = _statusColor();
    final themeColor = _typeColor;

    final hasSummary =
        item.status == 'Completed' && (item.summary ?? '').isNotEmpty;
    final hasCancellation =
        item.status == 'Cancelled' &&
        (item.cancellationReason ?? '').isNotEmpty;
    final showExtraBlock = hasSummary || hasCancellation;

    showModalBottomSheet(
      context: context,
      // useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: DrColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAppt ? 'Appointment Detail' : 'Task Detail',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: DrColors.textPrimary,
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
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    24 + MediaQuery.of(ctx).padding.bottom,
                  ),
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
                                    customIcon: Image.asset(
                                      'assets/whatsapp.png',
                                      width: 14,
                                      height: 14,
                                    ),
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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  children: [
                    if (item.personId.isNotEmpty) ...[
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
                    ],
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

    return InkWell(
      onTap: () => _showDetailsBottomSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Time and status badge
            SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(item.startTime),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DrColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(label: _statusLabel(), color: _statusColor()),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Middle Column: Patient details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.personName.isNotEmpty)
                    Text(
                      item.personName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DrColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    item.personName.isNotEmpty
                        ? item.type.replaceAll('_', ' ')
                        : item.shortDescription ??
                              item.type.replaceAll('_', ' '),
                    style: GoogleFonts.inter(
                      fontSize: item.personName.isNotEmpty ? 12 : 14,
                      color: item.personName.isNotEmpty
                          ? DrColors.textSecondary
                          : DrColors.textPrimary,
                      fontWeight: item.personName.isNotEmpty
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      // border: Border.all(
                      color: _isAppt
                          ? DrColors.primary.withValues(alpha: 0.5)
                          : DrColors.accent.withValues(alpha: 0.5),
                      // ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _isAppt ? 'Appointment' : 'Task',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DrColors.background,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right Column: Popup menu button
            if (showActions)
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: DrColors.textSecondary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (val) {
                  if (val == 'edit') {
                    _openEdit(context);
                  } else if (val == 'status') {
                    _showStatusMenu(context);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16, color: _typeColor),
                        const SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: item.status == 'Scheduled'
                              ? DrColors.warning
                              : DrColors.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Update Status',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
        color: color.withValues(alpha: 0.10),
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
        // boxShadow: [
        //   BoxShadow(
        //     color: Color.fromARGB(255, 244, 244, 244),
        //     blurRadius: 10,
        //     spreadRadius: 5,
        //   ),
        // ],
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
          color: selected ? color.withValues(alpha: 0.10) : DrColors.surface,
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
  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    this.icon,
    this.customIcon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        highlightColor: color.withValues(alpha: 0.12),
        splashColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              customIcon ?? Icon(icon, size: 14, color: color),
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

// ─────────────────────────────────────────────────────────────────────────────
// Custom Vertical Scrolling Calendar Dialog
// ─────────────────────────────────────────────────────────────────────────────

class VerticalCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  const VerticalCalendarDialog({super.key, required this.initialDate});

  @override
  State<VerticalCalendarDialog> createState() => _VerticalCalendarDialogState();
}

class _VerticalCalendarDialogState extends State<VerticalCalendarDialog> {
  late DateTime _selected;
  late List<DateTime> _months;
  late ScrollController _scrollController;
  bool _isYearPicker = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;

    // Generate 24 months (6 months before selected to 17 months after)
    final base = DateTime(_selected.year, _selected.month, 1);
    _months = List.generate(24, (i) {
      final monthIndex = base.month - 6 + i;
      return DateTime(base.year, monthIndex, 1);
    });

    final index = _months.indexWhere(
      (m) => m.year == _selected.year && m.month == _selected.month,
    );
    final initialOffset = index != -1 ? index * 260.0 : 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Container (Orange Theme)
          Container(
            width: double.infinity,
            color: DrColors.accent,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE').format(_selected).toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM dd').format(_selected).toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isYearPicker = !_isYearPicker;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('yyyy').format(_selected),
                        style: GoogleFonts.inter(
                          color: _isYearPicker
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: _isYearPicker
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isYearPicker
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body content
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isYearPicker
                  ? GridView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.0,
                          ),
                      itemCount: 11, // 2020 - 2030
                      itemBuilder: (ctx, i) {
                        final yr = 2020 + i;
                        final isSelectedYr = yr == _selected.year;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selected = DateTime(
                                yr,
                                _selected.month,
                                _selected.day,
                              );
                              _isYearPicker = false;

                              // Regenerate months around the new date
                              final base = DateTime(
                                _selected.year,
                                _selected.month,
                                1,
                              );
                              _months = List.generate(24, (i) {
                                final monthIndex = base.month - 6 + i;
                                return DateTime(base.year, monthIndex, 1);
                              });
                            });

                            // Jump List to centered selected month
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final idx = _months.indexWhere(
                                (m) =>
                                    m.year == _selected.year &&
                                    m.month == _selected.month,
                              );
                              if (idx != -1 && _scrollController.hasClients) {
                                _scrollController.jumpTo(idx * 260.0);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelectedYr
                                  ? DrColors.accent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelectedYr
                                    ? Colors.transparent
                                    : DrColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$yr',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelectedYr
                                      ? Colors.white
                                      : DrColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _months.length,
                      itemExtent: 260.0,
                      itemBuilder: (context, idx) {
                        final m = _months[idx];
                        return _MonthWidget(
                          monthDate: m,
                          selectedDate: _selected,
                          onDayTap: (date) {
                            setState(() {
                              _selected = date;
                            });
                          },
                        );
                      },
                    ),
            ),
          ),
          // Actions
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: DrColors.accent),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: TextButton.styleFrom(foregroundColor: DrColors.accent),
                  child: Text(
                    'OK',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthWidget extends StatelessWidget {
  final DateTime monthDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDayTap;

  const _MonthWidget({
    required this.monthDate,
    required this.selectedDate,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday;
    final offset = firstWeekday == 7 ? 0 : firstWeekday;

    final totalItems = daysInMonth + offset;

    const weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Text(
            DateFormat('MMMM yyyy').format(monthDate),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DrColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdayLabels.map((lbl) {
            return SizedBox(
              width: 24,
              child: Text(
                lbl,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: DrColors.textTertiary,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1.0,
            ),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              if (index < offset) {
                return const SizedBox.shrink();
              }
              final day = index - offset + 1;
              final dayDate = DateTime(monthDate.year, monthDate.month, day);
              final isSelected =
                  dayDate.year == selectedDate.year &&
                  dayDate.month == selectedDate.month &&
                  dayDate.day == selectedDate.day;

              return GestureDetector(
                onTap: () => onDayTap(dayDate),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? DrColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : DrColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
