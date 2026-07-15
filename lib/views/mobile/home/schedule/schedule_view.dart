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
  String _statusFilter = 'All';
  late _TypeFilter _typeFilter;

  final ScrollController _scrollController = ScrollController();

  // PageView weeks integration
  late final DateTime _baseMonday;
  late DateTime _visibleWeekMonday;
  late final PageController _pageController;
  bool _isPageAnimating = false;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 10;

  List<AppointmentMeetingModel> _fetched = [];
  bool _loading = false;
  bool _isViewingUpcoming = false;
  bool get _showViewAllButton => _isToday(_selectedDate) && !_isViewingUpcoming;

  static const _statuses = ['Scheduled', 'Completed', 'Cancelled', 'All'];

  void _updateSelectedDate(DateTime date) {
    final targetMonday = date.subtract(Duration(days: date.weekday - 1));
    final targetMondayClean = DateTime(
      targetMonday.year,
      targetMonday.month,
      targetMonday.day,
    );

    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _visibleWeekMonday = targetMondayClean;
    });

    final weekDiff = (targetMondayClean.difference(_baseMonday).inDays / 7)
        .round();
    final targetPage = 5000 + weekDiff;

    if (_pageController.hasClients &&
        _pageController.page?.round() != targetPage) {
      _isPageAnimating = true;
      _pageController.jumpToPage(targetPage);
      _isPageAnimating = false;
    }

    _fetchInitialSchedule();
  }

  @override
  void initState() {
    super.initState();
    _initFilters();
    final now = _selectedDate;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _baseMonday = DateTime(monday.year, monday.month, monday.day);
    _visibleWeekMonday = _baseMonday;
    _pageController = PageController(initialPage: 5000);
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialSchedule() async {
    setState(() {
      _loading = true;
      _fetched = [];
      _lastDoc = null;
      _hasMore = false;
      _isLoadingMore = false;
      _isViewingUpcoming = false;
    });

    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final DateTime end = start.add(const Duration(days: 1));
    final int limit = _isToday(_selectedDate) ? 100 : _pageSize;

    final res = await HomeCtrl.to.fetchSchedulePage(
      docTypeFilter: _typeFilter == _TypeFilter.appointments
          ? 'appointment'
          : _typeFilter == _TypeFilter.meetings
          ? 'meeting'
          : 'all',
      statusFilter: _statusFilter,
      startDateTime: start,
      endDateTime: end,
      limit: limit,
    );

    if (!mounted) return;

    setState(() {
      _fetched = List<AppointmentMeetingModel>.from(res['items']);
      _lastDoc = res['lastDoc'] as DocumentSnapshot?;
      _hasMore = !_isToday(_selectedDate)
          ? (_fetched.length >= _pageSize)
          : false;
      _loading = false;
    });
  }

  Future<void> _fetchUpcomingSchedule() async {
    if (_loading || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _isViewingUpcoming = true;
    });

    final todayStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final res = await HomeCtrl.to.fetchSchedulePage(
      docTypeFilter: _typeFilter == _TypeFilter.appointments
          ? 'appointment'
          : _typeFilter == _TypeFilter.meetings
          ? 'meeting'
          : 'all',
      statusFilter: _statusFilter,
      startDateTime: tomorrowStart,
      endDateTime: null,
      limit: _pageSize,
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

    final DateTime? end;
    final DateTime startQueryDate;
    if (_isToday(_selectedDate)) {
      startQueryDate = start.add(const Duration(days: 1));
      end = null;
    } else {
      startQueryDate = start;
      end = start.add(const Duration(days: 1));
    }

    final res = await HomeCtrl.to.fetchSchedulePage(
      docTypeFilter: _typeFilter == _TypeFilter.appointments
          ? 'appointment'
          : _typeFilter == _TypeFilter.meetings
          ? 'meeting'
          : 'all',
      statusFilter: _statusFilter,
      startDateTime: startQueryDate,
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

  Widget _buildViewAllButton() {
    return true
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: InkWell(
              onTap: _fetchUpcomingSchedule,

              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Upcoming',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DrColors.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: DrColors.primary,
                  ),
                ],
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _fetchUpcomingSchedule,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DrColors.primary,
                    side: const BorderSide(color: DrColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  bool _matchesFilters(AppointmentMeetingModel model) {
    final matchesType =
        _typeFilter == _TypeFilter.all ||
        (_typeFilter == _TypeFilter.appointments &&
            model.docType == 'appointment') ||
        (_typeFilter == _TypeFilter.meetings && model.docType == 'meeting');

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
      if (_isViewingUpcoming) {
        isWithinCurrentView =
            model.startTime.isAtSameMomentAs(start) ||
            model.startTime.isAfter(start);
      } else {
        isWithinCurrentView =
            model.startTime.year == _selectedDate.year &&
            model.startTime.month == _selectedDate.month &&
            model.startTime.day == _selectedDate.day;
      }
    }
    return matchesType && matchesStatus && isWithinCurrentView;
  }

  void _onItemCreated(AppointmentMeetingModel model) {
    if (_matchesFilters(model)) {
      setState(() {
        if (!_fetched.any((e) => e.docId == model.docId)) {
          _fetched.add(model);
          _fetched.sort((a, b) => a.startTime.compareTo(b.startTime));
        }
      });
    }
  }

  void _onItemUpdated(AppointmentMeetingModel model) {
    setState(() {
      final idx = _fetched.indexWhere((e) => e.docId == model.docId);
      if (idx != -1) {
        if (_matchesFilters(model)) {
          _fetched[idx] = model;
        } else {
          _fetched.removeAt(idx);
        }
      } else if (_matchesFilters(model)) {
        _fetched.add(model);
      }
      _fetched.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
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
      _updateSelectedDate(picked);
    }
  }

  DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1)); // Monday
  }

  List<DateTime> weekDays(DateTime start) {
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final currentWeek = getStartOfWeek(DateTime.now());
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
            'CALENDAR',
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
                      DateFormat(
                        'MMM yy',
                      ).format(_visibleWeekMonday).toUpperCase(),
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
                onPressed: () => _updateSelectedDate(DateTime.now()),
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
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        if (_isPageAnimating) return;
                        final newMonday = _baseMonday.add(
                          Duration(days: (index - 5000) * 7),
                        );
                        setState(() {
                          _visibleWeekMonday = newMonday;
                        });
                      },
                      itemBuilder: (context, page) {
                        final weekStart = currentWeek.add(
                          Duration(days: (page - 5000) * 7),
                        );

                        final days = weekDays(weekStart);

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: days.map((day) {
                            final now = DateTime.now();
                            final isToday =
                                day.year == now.year &&
                                day.month == now.month &&
                                day.day == now.day;
                            final isSelected =
                                day.year == _selectedDate.year &&
                                day.month == _selectedDate.month &&
                                day.day == _selectedDate.day;
                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _updateSelectedDate(day),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('EEE').format(day),
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
                                            ? DrColors.primary
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: isToday && !isSelected
                                            ? Border.all(
                                                color: DrColors.primary,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${day.day}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? Colors.white
                                                : isToday
                                                ? DrColors.primary
                                                : DrColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  /*  // ── Type filter (segmented) ──────────────────────
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
                        ? DrColors.accent
                        : DrColors.primary,

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

                  const SizedBox(height: 6), */

                  /*       // ── Status filter chips ──────────────────────────
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
                              color: active ? color : Colors.transparent,
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
                                      ? Colors.white
                                      : DrColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
               */
                ],
              ),
            ),

            const SizedBox(height: 6),
            // Text("-=-=-=-=-=-=-=-=", style: TextStyle(color: DrColors.primary)),
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
                      isToday: _isToday(_selectedDate),
                      isViewingUpcoming: _isViewingUpcoming,
                      actionButton: _showViewAllButton
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _fetchUpcomingSchedule,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: DrColors.primary,
                                    side: const BorderSide(
                                      color: DrColors.primary,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'View',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : null,
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 32),
                      itemCount:
                          filtered.length +
                          (_showViewAllButton ? 1 : 0) +
                          (_hasMore ? 1 : 0) +
                          ((_isViewingUpcoming && !_hasMore) ? 1 : 0),
                      separatorBuilder: (_, si) {
                        if (si >= filtered.length - 1) {
                          return const SizedBox.shrink();
                        }
                        if (!_isSameDay(
                          filtered[si].startTime,
                          filtered[si + 1].startTime,
                        )) {
                          return const SizedBox.shrink();
                        }
                        return const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: DrColors.border,
                        );
                      },
                      itemBuilder: (_, i) {
                        if (i == filtered.length) {
                          if (_showViewAllButton) {
                            return _buildViewAllButton();
                          }
                          if (_hasMore) {
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No more upcoming items',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: DrColors.textTertiary,
                                ),
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
                            _ScheduleCard(
                              item: item,
                              onRefresh: _refresh,
                              onItemUpdated: _onItemUpdated,
                            ),
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
                    onPressed: () async {
                      final result =
                          await Navigator.push<AppointmentMeetingModel>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MeetingFormSheet(
                                initialDate: _selectedDate,
                                initialDoctor: AuthCtrl.to.currentDoctor,
                              ),
                              fullscreenDialog: true,
                            ),
                          );
                      if (result != null && mounted) {
                        _onItemCreated(result);
                      }
                    },
                    child: Text(
                      'ADD TASK',
                      style: GoogleFonts.inter(
                        color: DrColors.success,
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
                    onPressed: () async {
                      final result =
                          await Navigator.push<AppointmentMeetingModel>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppointmentFormSheet(
                                initialDate: _selectedDate,
                                initialDoctor: AuthCtrl.to.currentDoctor,
                              ),
                              fullscreenDialog: true,
                            ),
                          );
                      if (result != null && mounted) {
                        _onItemCreated(result);
                      }
                    },
                    child: Text(
                      'ADD APPOINTMENT',
                      style: GoogleFonts.inter(
                        color: DrColors.primary,
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
              color: true
                  ? DrColors.accent.withValues(alpha: 0.3)
                  : DrColors.border,
              thickness: 1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            // decoration: BoxDecoration(
            //   color: isToday ? DrColors.primary : DrColors.primaryLight,
            //   borderRadius: BorderRadius.circular(16),
            //   border: Border.all(
            //     color: isToday
            //         ? DrColors.primary
            //         : DrColors.primary.withValues(alpha: 0.3),
            //     width: 1.0,
            //   ),
            // ),
            child: Text(
              dateStr.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: DrColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: true
                  ? DrColors.accent.withValues(alpha: 0.3)
                  : DrColors.accent,
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
  final bool isToday;
  final bool isViewingUpcoming;
  final Widget? actionButton;
  const _EmptyState({
    required this.hasFilters,
    required this.onClearFilters,
    required this.isToday,
    required this.isViewingUpcoming,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    String title = 'Nothing scheduled';
    String subtitle = hasFilters
        ? 'Try adjusting your filters'
        : 'No items for this date';

    if (isToday) {
      if (isViewingUpcoming) {
        title = 'No upcoming schedule';
        subtitle = hasFilters
            ? 'Try adjusting your filters'
            : 'No upcoming items found';
      } else {
        title = 'Nothing scheduled for today';
        subtitle = hasFilters
            ? 'Try adjusting your filters'
            : 'Tap below to see future upcoming items';
      }
    }

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
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
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
          if (actionButton != null) ...[
            const SizedBox(height: 20),
            actionButton!,
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
  final Function(AppointmentMeetingModel) onItemUpdated;

  const _ScheduleCard({
    required this.item,
    required this.onRefresh,
    required this.onItemUpdated,
  });

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

  Color get _typeColor => _isAppt ? DrColors.primary : DrColors.success;

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
    if (h >= 24) {
      final d = diff.inDays;
      return 'In ${d}d';
    }
    return 'In ${h}h';
  }

  Color _statusColor() {
    final label = _statusLabel();
    if (label == 'Passed' || label == 'Cancelled') return DrColors.textTertiary;
    if (label == 'Missed') return DrColors.warning;
    if (label == 'Completed') return DrColors.success;
    return _typeColor;
  }

  void _openEdit(BuildContext context) async {
    final result = await Navigator.push<AppointmentMeetingModel>(
      context,
      MaterialPageRoute(
        builder: (_) => _isAppt
            ? AppointmentFormSheet(appointment: item)
            : MeetingFormSheet(meeting: item),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      onItemUpdated(result);
    }
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
        onDone: () async {
          final doc = await FBFireStore.apptAndMeeting.doc(item.docId).get();
          if (doc.exists) {
            final updated = AppointmentMeetingModel.fromQueryDocumentSnapshot(
              doc,
            );
            onItemUpdated(updated);
          }
        },
      ),
    );
  }

  Future<void> _checkInAppointment(BuildContext context) async {
    final ctrl = HomeCtrl.to;
    final success = await ctrl.checkInAppointment(docId: item.docId);
    if (success && context.mounted) {
      AppSnackbar.success(context, 'Checked in successfully.');
      final doc = await FBFireStore.apptAndMeeting.doc(item.docId).get();
      if (doc.exists) {
        final updated = AppointmentMeetingModel.fromQueryDocumentSnapshot(doc);
        onItemUpdated(updated);
      }
    } else if (context.mounted) {
      AppSnackbar.error(context, 'Something went wrong.');
    }
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
                            if (item.persons.isNotEmpty)
                              ...item.persons.map((p) {
                                final name = p['personName'] ?? '';
                                final phone = p['personPhone'] ?? '';
                                final email = p['personEmail'] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: DrColors.textPrimary,
                                        ),
                                      ),
                                      if (phone.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          phone,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: DrColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      if (email.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: DrColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList()
                            else ...[
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
                  if (item.personName.isNotEmpty) ...[
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
                  ],
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isAppt
                                ? DrColors.primary
                                : DrColors.success,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isAppt ? 'Appointment' : 'Task',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _isAppt
                                ? DrColors.primary
                                : DrColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item.checkedIn == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DrColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: DrColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Arrived',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: DrColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
                  } else if (val == 'check_in') {
                    _checkInAppointment(context);
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
                  if (_isAppt &&
                      item.status == 'Scheduled' &&
                      item.checkedIn != true)
                    PopupMenuItem(
                      value: 'check_in',
                      child: Row(
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 16,
                            color: _typeColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Check In',
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
      // margin: const EdgeInsets.only(top: 80),
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
            Row(
              children: [
                Expanded(
                  // width: double.infinity,
                  // height: 52,
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
                const SizedBox(width: 12),
                Expanded(
                  // width: double.infinity,
                  // height: 52,
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
            color: DrColors.primary,
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
                                  ? DrColors.primary
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
                  style: TextButton.styleFrom(
                    foregroundColor: DrColors.primary,
                  ),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: TextButton.styleFrom(
                    foregroundColor: DrColors.primary,
                  ),
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
                      color: isSelected ? DrColors.primary : Colors.transparent,
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
