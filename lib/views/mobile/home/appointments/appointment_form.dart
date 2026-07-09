import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../controllers/auth_ctrl.dart';
import '../../../../controllers/home_ctrl.dart';
import '../../../../models/app_meet_model.dart';
import '../../../../models/patient_model.dart';
import '../../../../utils/app_theme.dart';
import '../../../../utils/firebase.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/phone_input_field.dart';
import '../../../../utils/phone_helper.dart';
import '../../../../widgets/form_date_time_pickers.dart';

const _apptTypes = [
  'Consultation',
  'Follow up',
  'Checkup',
  'Procedure',
  'Emergency',
  'Other',
];

class AppointmentFormSheet extends StatefulWidget {
  final AppointmentMeetingModel? appointment;
  const AppointmentFormSheet({super.key, this.appointment});

  @override
  State<AppointmentFormSheet> createState() => _AppointmentFormSheetState();
}

class _AppointmentFormSheetState extends State<AppointmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = HomeCtrl.to;

  PatientModel? _patient;
  String _apptType = 'Consultation';
  DateTime? _date;
  TimeOfDay? _startTOD;
  TimeOfDay? _endTOD;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

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
    final a = widget.appointment;
    if (a == null) return;
    _apptType = a.type;
    _date = a.startTime;
    _startTOD = TimeOfDay.fromDateTime(a.startTime);
    _endTOD = TimeOfDay.fromDateTime(a.endTime);
    _titleCtrl.text = a.shortDescription ?? '';
    _descCtrl.text = a.description ?? '';
    if (a.personId.isNotEmpty) {
      FBFireStore.patients.doc(a.personId).get().then((snap) {
        if (snap.exists && mounted) {
          setState(() {
            _patient = PatientModel.fromJson(snap.data()!);
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
    final picked = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenDatePicker(initialDate: _date ?? DateTime.now()),
        fullscreenDialog: true,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
      });
    }
  }

  int? get _selectedDurationMinutes {
    if (_startTOD == null || _endTOD == null) return null;
    final startM = _startTOD!.hour * 60 + _startTOD!.minute;
    final endM = _endTOD!.hour * 60 + _endTOD!.minute;
    final diff = endM - startM;
    return diff > 0 ? diff : null;
  }

  String _formattedTimeRange() {
    if (_startTOD == null) return '';
    final startStr = _startTOD!.format(context);
    final duration = _selectedDurationMinutes ?? 30;
    return '$startStr, $duration minutes';
  }

  Future<void> _pickTimeAndDuration() async {
    final initialStart = _startTOD ?? const TimeOfDay(hour: 9, minute: 0);
    int currentDuration = 30;
    if (_startTOD != null && _endTOD != null) {
      final startM = _startTOD!.hour * 60 + _startTOD!.minute;
      final endM = _endTOD!.hour * 60 + _endTOD!.minute;
      currentDuration = endM - startM;
      if (currentDuration <= 0) currentDuration = 30;
    }
    final picked = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenTimePicker(
          initialTime: initialStart,
          initialDurationMinutes: currentDuration,
        ),
        fullscreenDialog: true,
      ),
    );
    if (picked != null && mounted) {
      final time = picked['time'] as TimeOfDay;
      final duration = picked['duration'] as int;
      final startM = time.hour * 60 + time.minute;
      final endM = startM + duration;
      setState(() {
        _startTOD = time;
        _endTOD = TimeOfDay(
          hour: (endM ~/ 60) % 24,
          minute: endM % 60,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_patient == null) {
      AppSnackbar.error(context, 'Please select a patient.');
      return;
    }
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
      excludeDocId: widget.appointment?.docId ?? '',
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

    final appt = AppointmentMeetingModel(
      docId: widget.appointment?.docId ?? '',
      doctorId: doctor.docId,
      doctorName: doctor.name,
      specialization: doctor.specialization,
      docType: 'appointment',
      type: _apptType,
      personId: _patient!.docId,
      personName: _patient!.name,
      personPhone: _patient!.phone,
      personEmail: _patient!.email,
      startTime: _startTime!,
      endTime: _endTime!,
      status: widget.appointment?.status ?? 'Scheduled',
      createdAt: widget.appointment?.createdAt ?? now,
      createdById: doctor.docId,
      createdByName: doctor.name,
      shortDescription: _titleCtrl.text.trim().isEmpty
          ? null
          : _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      cancelledBy: widget.appointment?.cancelledBy,
      cancellationReason: widget.appointment?.cancellationReason,
      cancelledAt: widget.appointment?.cancelledAt,
      completedBy: widget.appointment?.completedBy,
      summary: widget.appointment?.summary,
      completedAt: widget.appointment?.completedAt,
      showOnReception: true,
    );

    final ok = widget.appointment == null
        ? await _ctrl.createAppointment(appt)
        : await _ctrl.updateAppointment(appt);

    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context);
      AppSnackbar.success(
        context,
        widget.appointment == null
            ? 'Appointment created.'
            : 'Appointment updated.',
      );
    } else {
      AppSnackbar.error(context, 'Something went wrong. Please try again.');
    }
  }



  @override
  Widget build(BuildContext context) {
    final isEdit = widget.appointment != null;
    final doctor = AuthCtrl.to.currentDoctor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2260),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'EDIT APPOINTMENT' : 'ADD APPOINTMENT',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(
              'SAVE',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Name (via Autocomplete selector)
                      _PatientSelector(
                        selected: _patient,
                        onChanged: (p) => setState(() => _patient = p),
                      ),
                      const SizedBox(height: 16),

                      // Mobile Number (Read-only/auto-filled)
                      TextFormField(
                        key: ValueKey(_patient?.docId),
                        readOnly: true,
                        initialValue: _patient?.phone ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: DrColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          labelStyle: GoogleFonts.inter(
                            color: DrColors.textSecondary,
                            fontSize: 13,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: DrColors.border, width: 1.0),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: DrColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Doctor Name (Read-only)
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(text: doctor?.name ?? 'Dr Saumya Nayak'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: DrColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Doctor Name',
                          labelStyle: GoogleFonts.inter(
                            color: DrColors.textSecondary,
                            fontSize: 13,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: DrColors.border, width: 1.0),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: DrColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date Field (Tappable)
                      GestureDetector(
                        onTap: _pickDate,
                        behavior: HitTestBehavior.opaque,
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: _date != null
                                  ? DateFormat('dd MMMM, yyyy').format(_date!)
                                  : '',
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: DrColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Date',
                              labelStyle: GoogleFonts.inter(
                                color: DrColors.textSecondary,
                                fontSize: 13,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: DrColors.border, width: 1.0),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: DrColors.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time Field (Tappable)
                      GestureDetector(
                        onTap: _pickTimeAndDuration,
                        behavior: HitTestBehavior.opaque,
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: TextEditingController(text: _formattedTimeRange()),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: DrColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Time',
                              labelStyle: GoogleFonts.inter(
                                color: DrColors.textSecondary,
                                fontSize: 13,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: DrColors.border, width: 1.0),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: DrColors.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: _apptType,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: GoogleFonts.inter(
                            color: DrColors.textSecondary,
                            fontSize: 13,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: DrColors.border, width: 1.0),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: DrColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        items: _apptTypes.map((t) {
                          return DropdownMenuItem<String>(
                            value: t,
                            child: Text(t, style: GoogleFonts.inter(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _apptType = val;
                              _titleCtrl.text = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notes/Procedures
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: DrColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Procedures / Notes',
                          labelStyle: GoogleFonts.inter(
                            color: DrColors.textSecondary,
                            fontSize: 13,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: DrColors.border, width: 1.0),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: DrColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _labelText(String text) => Text(
  text,
  style: GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: DrColors.textSecondary,
  ),
);

class _PatientInfoCard extends StatelessWidget {
  final PatientModel patient;
  const _PatientInfoCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DrColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DrColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: DrColors.primary.withOpacity(0.15),
            child: Text(
              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DrColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DrColors.textPrimary,
                  ),
                ),
                if (patient.phone.isNotEmpty)
                  Text(
                    patient.phone,
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

// ─── Patient Selector ─────────────────────────────────────────────────────────

final _kNoPatient = PatientModel(
  docId: '__no_result__',
  name: '__no_result__',
  lowerName: '',
  email: '',
  phone: '',
  createdByRole: '',
  // doctorId: '',
  createdAt: DateTime(2000),
  updatedAt: DateTime(2000),
);

class _PatientSelector extends StatefulWidget {
  final PatientModel? selected;
  final void Function(PatientModel?) onChanged;

  const _PatientSelector({required this.selected, required this.onChanged});

  @override
  State<_PatientSelector> createState() => _PatientSelectorState();
}

class _PatientSelectorState extends State<_PatientSelector> {
  PatientModel? _current;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  void didUpdateWidget(_PatientSelector old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) _current = widget.selected;
  }

  Future<Iterable<PatientModel>> _search(String q) async {
    final lq = q.trim().toLowerCase();
    setState(() => _query = lq);
    if (lq.isEmpty) return const [];
    final snap = await FBFireStore.patients
        .where('lowerName', isGreaterThanOrEqualTo: lq)
        .where('lowerName', isLessThanOrEqualTo: '$lq\uf8ff')
        .limit(10)
        .get();
    final res = snap.docs.map(PatientModel.fromQueryDocumentSnapshot).toList();
    return res.isEmpty ? [_kNoPatient] : res;
  }

  Future<void> _quickCreate() async {
    final p = await showDialog<PatientModel?>(
      context: context,
      builder: (_) => const _QuickCreatePatientDialog(),
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
              child: Autocomplete<PatientModel>(
                key: ValueKey(_current?.docId),
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
                optionsViewBuilder: (ctx, onSel, options) =>
                    _OptionsView<PatientModel>(
                      options: options.toList(),
                      query: _query,
                      noResultText: 'No patient found',
                      onSelected: onSel,
                      nameOf: (p) => p.name,
                      subOf: (p) => p.phone,
                      idOf: (p) => p.docId,
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
                    labelText: 'Patient Name *',
                    labelStyle: GoogleFonts.inter(
                      color: DrColors.textSecondary,
                      fontSize: 13,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: DrColors.border, width: 1.0),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: DrColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_current != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              ctrl.clear();
                              setState(() {
                                _current = null;
                                _query = '';
                              });
                              widget.onChanged(null);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                          onPressed: _quickCreate,
                          color: DrColors.primary,
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.account_circle_rounded,
                          color: DrColors.textTertiary,
                          size: 32,
                        ),
                      ],
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
}

// ─── Generic Options View ─────────────────────────────────────────────────────

class _OptionsView<T> extends StatelessWidget {
  final List<T> options;
  final String query;
  final String noResultText;
  final void Function(T) onSelected;
  final String Function(T) nameOf;
  final String Function(T) subOf;
  final String Function(T) idOf;

  const _OptionsView({
    required this.options,
    required this.query,
    required this.noResultText,
    required this.onSelected,
    required this.nameOf,
    required this.subOf,
    required this.idOf,
  });

  @override
  Widget build(BuildContext context) {
    final isNone =
        options.length == 1 && idOf(options.first) == '__no_result__';
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
                    '$noResultText for "$query"',
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
                        (item) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: DrColors.primaryLight,
                            child: Text(
                              nameOf(item)[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: DrColors.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            nameOf(item),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            subOf(item),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: DrColors.textTertiary,
                            ),
                          ),
                          onTap: () => onSelected(item),
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
    );
  }
}

// ─── Quick Create Patient Dialog ──────────────────────────────────────────────

class _QuickCreatePatientDialog extends StatefulWidget {
  const _QuickCreatePatientDialog();

  @override
  State<_QuickCreatePatientDialog> createState() =>
      _QuickCreatePatientDialogState();
}

class _QuickCreatePatientDialogState extends State<_QuickCreatePatientDialog> {
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

    final p = await HomeCtrl.to.createPatient(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: fullPhone,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (p != null) {
      Navigator.pop(context, p);
    } else {
      AppSnackbar.error(context, 'Failed to create patient.');
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
                'Quick Add Patient',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: DrColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Full Name *',
                hint: 'Patient name',
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
                hint: 'patient@example.com',
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
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Add'),
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
              decoration: BoxDecoration(
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
