import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

const _meetingTypes = [
  'business',
  'consultation',
  'follow_up',
  'review',
  'other',
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
  final _locationCtrl = TextEditingController();
  bool _loading = false;

  DateTime? get _startTime => _date != null && _startTOD != null
      ? DateTime(_date!.year, _date!.month, _date!.day, _startTOD!.hour,
          _startTOD!.minute)
      : null;

  DateTime? get _endTime => _date != null && _endTOD != null
      ? DateTime(_date!.year, _date!.month, _date!.day, _endTOD!.hour,
          _endTOD!.minute)
      : null;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final m = widget.meeting;
    if (m == null) return;
    _person = _ctrl.meetingPersons
        .firstWhereOrNull((p) => p.docId == m.personId);
    _meetingType = m.type;
    _date = m.startTime;
    _startTOD = TimeOfDay.fromDateTime(m.startTime);
    _endTOD = TimeOfDay.fromDateTime(m.endTime);
    _titleCtrl.text = m.shortDescription ?? '';
    _locationCtrl.text = m.description ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
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

  Future<void> _pickStart() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _startTOD ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _startTOD = t);
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
    if (_person == null) {
      AppSnackbar.error(context, 'Please select a meeting person.');
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
      personId: _person!.docId,
      personName: _person!.name,
      personPhone: _person!.phone,
      personEmail: _person!.email,
      startTime: _startTime!,
      endTime: _endTime!,
      status: widget.meeting?.status ?? 'Scheduled',
      createdAt: widget.meeting?.createdAt ?? now,
      createdById: doctor.docId,
      createdByName: doctor.name,
      shortDescription: _titleCtrl.text.trim().isEmpty
          ? null
          : _titleCtrl.text.trim(),
      description: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      cancelledBy: widget.meeting?.cancelledBy,
      cancellationReason: widget.meeting?.cancellationReason,
      cancelledAt: widget.meeting?.cancelledAt,
      completedBy: widget.meeting?.completedBy,
      summary: widget.meeting?.summary,
      completedAt: widget.meeting?.completedAt,
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.meeting != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
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
                      isEdit ? 'Edit Meeting' : 'New Meeting',
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
                    // Type
                    _labelText('Meeting Type'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _meetingType,
                      decoration: const InputDecoration(),
                      items: _meetingTypes
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t.replaceAll('_', ' ').toUpperCase(),
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _meetingType = v!),
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
                    // Date
                    _labelText('Date *'),
                    const SizedBox(height: 6),
                    _TapField(
                      icon: Icons.calendar_today_rounded,
                      text: _date != null
                          ? DateFormat('EEEE, MMM d, yyyy').format(_date!)
                          : 'Select date',
                      hasValue: _date != null,
                      color: DrColors.accent,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _labelText('Start Time *'),
                              const SizedBox(height: 6),
                              _TapField(
                                icon: Icons.schedule_rounded,
                                text: _startTOD != null
                                    ? _startTOD!.format(context)
                                    : 'Start',
                                hasValue: _startTOD != null,
                                color: DrColors.accent,
                                onTap: _pickStart,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _labelText('End Time *'),
                              const SizedBox(height: 6),
                              _TapField(
                                icon: Icons.schedule_rounded,
                                text: _endTOD != null
                                    ? _endTOD!.format(context)
                                    : 'End',
                                hasValue: _endTOD != null,
                                color: DrColors.accent,
                                onTap: _pickEnd,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Title *',
                      hint: 'e.g. Staff Weekly Standup',
                      controller: _titleCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Location / Venue',
                      hint: 'e.g. Conference Room A, Zoom...',
                      controller: _locationCtrl,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: DrColors.accent),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                isEdit ? 'Update Meeting' : 'Create Meeting'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

class _TapField extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool hasValue;
  final Color color;
  final VoidCallback onTap;

  const _TapField({
    required this.icon,
    required this.text,
    required this.hasValue,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: DrColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DrColors.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: hasValue ? color : DrColors.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: hasValue
                      ? DrColors.textPrimary
                      : DrColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  const _PersonSelector(
      {required this.selected, required this.onChanged});

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
        .where('lowerName', isLessThanOrEqualTo: '$lq')
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
        _labelText('Meeting Person *'),
        const SizedBox(height: 6),
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
                optionsViewBuilder: (ctx, onSel, options) =>
                    _PersonOptionsView(
                  options: options.toList(),
                  query: _query,
                  onSelected: onSel,
                ),
                fieldViewBuilder: (ctx, ctrl, fn, _) => TextFormField(
                  controller: ctrl,
                  focusNode: fn,
                  style: GoogleFonts.inter(
                      fontSize: 15, color: DrColors.textPrimary),
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
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.person_search_outlined,
                        size: 18),
                    suffixIcon: _current != null
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 16),
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
    final isNone = options.length == 1 &&
        options.first.docId == '__no_result__';
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints:
              const BoxConstraints(maxHeight: 220, maxWidth: 400),
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
                        color: DrColors.textSecondary),
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
                          title: Text(p.name,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          subtitle: Text(p.phone,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: DrColors.textTertiary)),
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
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final p = await HomeCtrl.to.createMeetingPerson(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
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
              AppTextField(
                label: 'Phone *',
                hint: '+91 9876543210',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email',
                hint: 'email@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
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
                          backgroundColor: DrColors.accent),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Add Person'),
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
              decoration:
                  const BoxDecoration(color: DrColors.warningBg, shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded,
                  color: DrColors.warning, size: 28),
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
                  fontSize: 14, color: DrColors.textSecondary),
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
                        backgroundColor: DrColors.warning),
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
