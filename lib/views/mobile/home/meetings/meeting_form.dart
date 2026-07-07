import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../controllers/auth_ctrl.dart';
import '../../../../controllers/home_ctrl.dart';
import '../../../../models/app_meet_model.dart';
import '../../../../models/meeting_per_model.dart';
import '../../../../utils/app_theme.dart';
import '../../../../utils/firebase.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/phone_input_field.dart';
import '../../../../utils/phone_helper.dart';

const _meetingTypes = [
  'Meeting',
  'Call',
  'Lunch',
  'Dinner',
  'Game',
  'Movie',
  'Party',
  'Travel',
];

class MeetingFormSheet extends StatefulWidget {
  final AppointmentMeetingModel? meeting;
  const MeetingFormSheet({super.key, this.meeting});

  @override
  State<MeetingFormSheet> createState() => _MeetingFormSheetState();
}

class _MeetingFormSheetState extends State<MeetingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = HomeCtrl.to;

  MeetingPersonModel? _person;
  String _meetingType = 'business';
  DateTime? _date;
  TimeOfDay? _startTOD;
  TimeOfDay? _endTOD;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  bool _showOnReception = true;

  DateTime? get _startTime => _date != null && _startTOD != null
      ? DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _startTOD!.hour,
          _startTOD!.minute,
        )
      : null;

  DateTime? get _endTime => _date != null && _endTOD != null
      ? DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _endTOD!.hour,
          _endTOD!.minute,
        )
      : null;

  String _selectedDateOption = 'today';

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  List<TimeOfDay> _getQuickStartTimes() {
    final now = DateTime.now();
    final list = <TimeOfDay>[];
    int startHour = now.hour + 1;
    for (int i = 0; i < 3; i++) {
      list.add(TimeOfDay(hour: (startHour + i) % 24, minute: 0));
    }
    return list;
  }

  Widget _buildDateChips() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));

    final isToday = _selectedDateOption == 'today';
    final isTomorrow = _selectedDateOption == 'tomorrow';
    final isDayAfter = _selectedDateOption == 'day_after';
    final isCustom = _selectedDateOption == 'custom';

    final options = [
      {
        'id': 'today',
        'label': 'Today',
        'subtitle': DateFormat('d MMM, EEE').format(today),
        'active': isToday,
        'date': today,
      },
      {
        'id': 'tomorrow',
        'label': 'Tomorrow',
        'subtitle': DateFormat('d MMM, EEE').format(tomorrow),
        'active': isTomorrow,
        'date': tomorrow,
      },
      {
        'id': 'day_after',
        'label': 'Day After',
        'subtitle': DateFormat('d MMM, EEE').format(dayAfter),
        'active': isDayAfter,
        'date': dayAfter,
      },
      {
        'id': 'custom',
        'label': 'Custom',
        'subtitle': (isCustom && _date != null)
            ? DateFormat('d MMM, EEE').format(_date!)
            : 'Select',
        'active': isCustom,
        'date': _date,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText('Date *'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final opt = options[i];
                    if (opt['id'] == 'custom') {
                      final oldDate = _date;
                      await _pickDate();
                      if (_date != oldDate) {
                        setState(() {
                          _selectedDateOption = 'custom';
                        });
                      }
                    } else {
                      setState(() {
                        _date = opt['date'] as DateTime;
                        _selectedDateOption = opt['id'] as String;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: options[i]['active'] as bool
                          ? DrColors.accent
                          : DrColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: options[i]['active'] as bool
                            ? DrColors.accent
                            : DrColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            options[i]['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: options[i]['active'] as bool
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: options[i]['active'] as bool
                                  ? Colors.white
                                  : DrColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            options[i]['subtitle'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: options[i]['active'] as bool
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: options[i]['active'] as bool
                                  ? Colors.white.withOpacity(0.85)
                                  : DrColors.textSecondary.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStartTimeChips() {
    final quickTimes = _getQuickStartTimes();

    String? matchedId;
    for (int i = 0; i < quickTimes.length; i++) {
      if (_startTOD != null &&
          _startTOD!.hour == quickTimes[i].hour &&
          _startTOD!.minute == quickTimes[i].minute) {
        matchedId = 'quick_$i';
      }
    }

    final isCustom = _startTOD != null && matchedId == null;
    String customLabel = 'Custom';
    if (isCustom && _startTOD != null) {
      customLabel = _startTOD!.format(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText('Start Time *'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < quickTimes.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final active = matchedId == 'quick_$i';
                    final time = quickTimes[i];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          final oldStart = _startTOD;
                          _startTOD = time;
                          if (oldStart != null && _endTOD != null) {
                            final startM = oldStart.hour * 60 + oldStart.minute;
                            final endM = _endTOD!.hour * 60 + _endTOD!.minute;
                            final duration = endM - startM;
                            final newStartM =
                                _startTOD!.hour * 60 + _startTOD!.minute;
                            final newEndM = newStartM + duration;
                            _endTOD = TimeOfDay(
                              hour: (newEndM ~/ 60) % 24,
                              minute: newEndM % 60,
                            );
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? DrColors.accent : DrColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active ? DrColors.accent : DrColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            time.format(context),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: active
                                  ? Colors.white
                                  : DrColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(width: 6),
            Expanded(
              child: InkWell(
                onTap: _pickStart,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isCustom ? DrColors.accent : DrColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCustom ? DrColors.accent : DrColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      customLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isCustom
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isCustom ? Colors.white : DrColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _prefill();

    if (_date == null) {
      _date = DateTime.now();
      _selectedDateOption = 'today';
    } else {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final dayAfter = today.add(const Duration(days: 2));
      if (_isSameDay(_date!, today)) {
        _selectedDateOption = 'today';
      } else if (_isSameDay(_date!, tomorrow)) {
        _selectedDateOption = 'tomorrow';
      } else if (_isSameDay(_date!, dayAfter)) {
        _selectedDateOption = 'day_after';
      } else {
        _selectedDateOption = 'custom';
      }
    }

    if (_startTOD == null) {
      final quickTimes = _getQuickStartTimes();
      _startTOD = quickTimes.first;
    }
    if (_endTOD == null && _startTOD != null) {
      final startMinutes = _startTOD!.hour * 60 + _startTOD!.minute;
      final endMinutes = startMinutes + 30;
      _endTOD = TimeOfDay(
        hour: (endMinutes ~/ 60) % 24,
        minute: endMinutes % 60,
      );
    }
  }

  void _prefill() {
    final m = widget.meeting;
    if (m == null) return;
    _meetingType = m.type;
    _date = m.startTime;
    _startTOD = TimeOfDay.fromDateTime(m.startTime);
    _endTOD = TimeOfDay.fromDateTime(m.endTime);
    _titleCtrl.text = m.shortDescription ?? '';
    _descCtrl.text = m.description ?? '';
    _showOnReception = m.showOnReception;
    if (m.personId.isNotEmpty) {
      FBFireStore.meetingPersons.doc(m.personId).get().then((snap) {
        if (snap.exists && mounted) {
          setState(() {
            _person = MeetingPersonModel.fromJson(snap.data()!);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null && mounted) setState(() => _date = d);
  }

  String _getFormattedEndTime(int extraMinutes) {
    if (_startTOD == null) return '';
    final startMinutes = _startTOD!.hour * 60 + _startTOD!.minute;
    final endMinutes = startMinutes + extraMinutes;
    final tempTOD = TimeOfDay(
      hour: (endMinutes ~/ 60) % 24,
      minute: endMinutes % 60,
    );
    return tempTOD.format(context);
  }

  int? get _selectedDurationMinutes {
    if (_startTOD == null || _endTOD == null) return null;
    final startM = _startTOD!.hour * 60 + _startTOD!.minute;
    final endM = _endTOD!.hour * 60 + _endTOD!.minute;
    final diff = endM - startM;
    if (diff == 15 || diff == 30 || diff == 60) {
      return diff;
    }
    return null;
  }

  void _selectDuration(int minutes) {
    if (_startTOD == null) {
      final now = TimeOfDay.now();
      _startTOD = TimeOfDay(hour: now.hour, minute: now.minute);
    }
    final startMinutes = _startTOD!.hour * 60 + _startTOD!.minute;
    final endMinutes = startMinutes + minutes;
    setState(() {
      _endTOD = TimeOfDay(
        hour: (endMinutes ~/ 60) % 24,
        minute: endMinutes % 60,
      );
    });
  }

  Future<void> _pickStart() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _startTOD ?? TimeOfDay.now(),
    );
    if (t != null) {
      setState(() {
        if (_startTOD != null && _endTOD != null) {
          final startM = _startTOD!.hour * 60 + _startTOD!.minute;
          final endM = _endTOD!.hour * 60 + _endTOD!.minute;
          final duration = endM - startM;
          _startTOD = t;
          final newStartM = _startTOD!.hour * 60 + _startTOD!.minute;
          final newEndM = newStartM + duration;
          _endTOD = TimeOfDay(hour: (newEndM ~/ 60) % 24, minute: newEndM % 60);
        } else {
          _startTOD = t;
        }
      });
    }
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _endTOD ?? _startTOD ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _endTOD = t);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startTime == null || _endTime == null) {
      AppSnackbar.error(context, 'Please set date, start and end time.');
      return;
    }
    if (_endTime!.isBefore(_startTime!)) {
      AppSnackbar.error(context, 'End time must be after start time.');
      return;
    }

    setState(() => _loading = true);

    final conflicts = await _ctrl.fetchConflicts(
      newStart: _startTime!,
      newEnd: _endTime!,
      excludeDocId: widget.meeting?.docId ?? '',
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (conflicts.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => _ConflictDialog(count: conflicts.length),
      );
      if (proceed != true) return;
    }

    setState(() => _loading = true);
    final doctor = AuthCtrl.to.currentDoctor!;
    final now = DateTime.now();

    final meeting = AppointmentMeetingModel(
      docId: widget.meeting?.docId ?? '',
      doctorId: doctor.docId,
      doctorName: doctor.name,
      specialization: doctor.specialization,
      docType: 'meeting',
      type: _meetingType,
      personId: _person?.docId ?? '',
      personName: _person?.name ?? '',
      personPhone: _person?.phone ?? '',
      personEmail: _person?.email ?? '',
      startTime: _startTime!,
      endTime: _endTime!,
      status: widget.meeting?.status ?? 'Scheduled',
      createdAt: widget.meeting?.createdAt ?? now,
      createdById: doctor.docId,
      createdByName: doctor.name,
      shortDescription: _titleCtrl.text.trim().isEmpty
          ? null
          : _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      cancelledBy: widget.meeting?.cancelledBy,
      cancellationReason: widget.meeting?.cancellationReason,
      cancelledAt: widget.meeting?.cancelledAt,
      completedBy: widget.meeting?.completedBy,
      summary: widget.meeting?.summary,
      completedAt: widget.meeting?.completedAt,
      showOnReception: _showOnReception,
    );

    final ok = widget.meeting == null
        ? await _ctrl.createMeeting(meeting)
        : await _ctrl.updateMeeting(meeting);

    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context);
      AppSnackbar.success(
        context,
        widget.meeting == null ? 'Meeting created.' : 'Meeting updated.',
      );
    } else {
      AppSnackbar.error(context, 'Something went wrong. Please try again.');
    }
  }

  Widget _buildDurationChips() {
    final durations = [
      {'label': '15 min', 'minutes': 15},
      {'label': '30 min', 'minutes': 30},
      {'label': '1 hr', 'minutes': 60},
    ];

    final currentDuration = _selectedDurationMinutes;
    final isCustom =
        _startTOD != null && _endTOD != null && currentDuration == null;

    final options = [
      for (var d in durations)
        {
          'id': 'dur_${d['minutes']}',
          'label': d['label'] as String,
          'subtitle': _getFormattedEndTime(d['minutes'] as int),
          'active': currentDuration == d['minutes'],
          'minutes': d['minutes'] as int,
        },
      {
        'id': 'custom',
        'label': 'Custom',
        'subtitle': (isCustom && _endTOD != null)
            ? _endTOD!.format(context)
            : 'Select',
        'active': isCustom,
        'minutes': -1,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration / End Time',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: DrColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: () {
                    final opt = options[i];
                    if (opt['id'] == 'custom') {
                      _pickEnd();
                    } else {
                      _selectDuration(opt['minutes'] as int);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: options[i]['active'] as bool
                          ? DrColors.accent
                          : DrColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: options[i]['active'] as bool
                            ? DrColors.accent
                            : DrColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            options[i]['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: options[i]['active'] as bool
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: options[i]['active'] as bool
                                  ? Colors.white
                                  : DrColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            options[i]['subtitle'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: options[i]['active'] as bool
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: options[i]['active'] as bool
                                  ? Colors.white.withOpacity(0.85)
                                  : DrColors.textSecondary.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.meeting != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: DrColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Column(
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
                  Row(
                    children: [
                      Text(
                        isEdit ? 'Edit Task' : 'New Task',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: DrColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: DrColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Show on Reception',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: DrColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'If unchecked, this task will be visible in the doctor\'s app only.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: DrColors.textSecondary,
                          ),
                        ),
                        value: _showOnReception,
                        activeColor: DrColors.accent,
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _showOnReception = v);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildDateChips(),
                      const SizedBox(height: 16),
                      _buildStartTimeChips(),
                      const SizedBox(height: 16),
                      _buildDurationChips(),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Title *',
                        hint: 'e.g. Staff Weekly Standup',
                        controller: _titleCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _meetingTypes.map((t) {
                          final isSelected = _titleCtrl.text.trim() == t;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _titleCtrl.text = t;
                                _meetingType = t;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DrColors.primary.withValues(alpha: 0.1)
                                    : DrColors.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? DrColors.primary
                                      : DrColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                t,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? DrColors.primary
                                      : DrColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Notes',
                        hint: 'Add notes here',
                        controller: _descCtrl,
                        maxLines: 3,

                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      // Person selector
                      _PersonSelector(
                        selected: _person,
                        onChanged: (p) => setState(() => _person = p),
                      ),
                      if (_person != null) ...[
                        const SizedBox(height: 8),
                        _PersonInfoCard(person: _person!),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DrColors.accent,
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
                              : Text(isEdit ? 'Update' : 'Create'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _labelText(String text) => Text(
  text,
  style: GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: DrColors.textSecondary,
  ),
);

class _PersonInfoCard extends StatelessWidget {
  final MeetingPersonModel person;
  const _PersonInfoCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DrColors.accentLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DrColors.accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: DrColors.accent.withOpacity(0.15),
            child: Text(
              person.name.isNotEmpty ? person.name[0].toUpperCase() : 'P',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DrColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DrColors.textPrimary,
                  ),
                ),
                if (person.phone.isNotEmpty)
                  Text(
                    person.phone,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: DrColors.textSecondary,
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

// ─── Person Selector ──────────────────────────────────────────────────────────

final _kNoPerson = MeetingPersonModel(
  docId: '__no_result__',
  name: '__no_result__',
  lowerName: '',
  email: '',
  phone: '',
  createdByRole: '',
  createdAt: DateTime(2000),
  updatedAt: DateTime(2000),
);

class _PersonSelector extends StatefulWidget {
  final MeetingPersonModel? selected;
  final void Function(MeetingPersonModel?) onChanged;

  const _PersonSelector({required this.selected, required this.onChanged});

  @override
  State<_PersonSelector> createState() => _PersonSelectorState();
}

class _PersonSelectorState extends State<_PersonSelector> {
  MeetingPersonModel? _current;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  void didUpdateWidget(_PersonSelector old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) _current = widget.selected;
  }

  Future<Iterable<MeetingPersonModel>> _search(String q) async {
    final lq = q.trim().toLowerCase();
    setState(() => _query = lq);
    if (lq.isEmpty) return const [];
    final snap = await FBFireStore.meetingPersons
        .where('lowerName', isGreaterThanOrEqualTo: lq)
        .where('lowerName', isLessThanOrEqualTo: '$lq\uf8ff')
        .limit(10)
        .get();
    final res = snap.docs.map(MeetingPersonModel.fromSnap).toList();
    return res.isEmpty ? [_kNoPerson] : res;
  }

  Future<void> _quickCreate() async {
    final p = await showDialog<MeetingPersonModel?>(
      context: context,
      builder: (_) => const _QuickCreatePersonDialog(),
    );
    if (p != null) {
      setState(() {
        _current = p;
        _query = '';
      });
      widget.onChanged(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Autocomplete<MeetingPersonModel>(
                initialValue: TextEditingValue(text: _current?.name ?? ''),
                displayStringForOption: (p) =>
                    p.docId == '__no_result__' ? '' : p.name,
                optionsBuilder: (v) => _search(v.text),
                onSelected: (p) {
                  if (p.docId == '__no_result__') return;
                  setState(() {
                    _current = p;
                    _query = '';
                  });
                  widget.onChanged(p);
                },
                optionsViewBuilder: (ctx, onSel, options) => _PersonOptionsView(
                  options: options.toList(),
                  query: _query,
                  onSelected: onSel,
                ),
                fieldViewBuilder: (ctx, ctrl, fn, _) => TextFormField(
                  controller: ctrl,
                  focusNode: fn,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: DrColors.textPrimary,
                  ),
                  onChanged: (v) {
                    if (v.isEmpty) {
                      setState(() {
                        _current = null;
                        _query = '';
                      });
                      widget.onChanged(null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Task Person (Optional)',
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(
                      Icons.person_search_outlined,
                      size: 18,
                    ),
                    suffixIcon: _current != null
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              ctrl.clear();
                              setState(() {
                                _current = null;
                                _query = '';
                              });
                              widget.onChanged(null);
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _quickCreate,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: DrColors.accent),
                  foregroundColor: DrColors.accent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonOptionsView extends StatelessWidget {
  final List<MeetingPersonModel> options;
  final String query;
  final void Function(MeetingPersonModel) onSelected;

  const _PersonOptionsView({
    required this.options,
    required this.query,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isNone =
        options.length == 1 && options.first.docId == '__no_result__';
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 220, maxWidth: 400),
          decoration: BoxDecoration(
            color: DrColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DrColors.border),
          ),
          child: isNone
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No person found for "$query"',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: DrColors.textSecondary,
                    ),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: options
                      .map(
                        (p) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: DrColors.accentLight,
                            child: Text(
                              p.name[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: DrColors.accent,
                              ),
                            ),
                          ),
                          title: Text(
                            p.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            p.phone,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: DrColors.textTertiary,
                            ),
                          ),
                          onTap: () => onSelected(p),
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
    );
  }
}

// ─── Quick Create Person Dialog ───────────────────────────────────────────────

class _QuickCreatePersonDialog extends StatefulWidget {
  const _QuickCreatePersonDialog();

  @override
  State<_QuickCreatePersonDialog> createState() =>
      _QuickCreatePersonDialogState();
}

class _QuickCreatePersonDialogState extends State<_QuickCreatePersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  late final TextEditingController _phoneCtrl;
  late String _dialCode;
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _dialCode = '+91';
    _phoneCtrl = TextEditingController();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final fullPhone = '$_dialCode ${_phoneCtrl.text.trim()}';
    final p = await HomeCtrl.to.createMeetingPerson(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: fullPhone,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (p != null) {
      Navigator.pop(context, p);
    } else {
      AppSnackbar.error(context, 'Failed to create person.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Add Meeting Person',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: DrColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Full Name *',
                hint: 'Contact name',
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              PhoneInputField(
                controller: _phoneCtrl,
                selectedDialCode: _dialCode,
                onDialCodeChanged: (v) => setState(() => _dialCode = v),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final fullPhone = '$_dialCode ${v.trim()}';
                  if (!isValidPhoneNumber(fullPhone)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email',
                hint: 'email@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  if (!isValidEmail(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DrColors.accent,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save'),
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
}

// ─── Conflict Dialog ──────────────────────────────────────────────────────────

class _ConflictDialog extends StatelessWidget {
  final int count;
  const _ConflictDialog({required this.count});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: DrColors.warningBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: DrColors.warning,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scheduling Conflict',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: DrColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have $count conflicting '
              '${count == 1 ? 'slot' : 'slots'} at this time. Save anyway?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DrColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DrColors.warning,
                    ),
                    child: const Text('Save Anyway'),
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
