import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. FullScreenDatePicker - Scrollable calendar matching Image 2
// ─────────────────────────────────────────────────────────────────────────────

class FullScreenDatePicker extends StatefulWidget {
  final DateTime initialDate;
  const FullScreenDatePicker({super.key, required this.initialDate});

  @override
  State<FullScreenDatePicker> createState() => _FullScreenDatePickerState();
}

class _FullScreenDatePickerState extends State<FullScreenDatePicker> {
  late DateTime _selected;
  late List<DateTime> _months;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;

    // Generate 12 months starting from current month
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, 1);
    _months = List.generate(12, (i) {
      return DateTime(base.year, base.month + i, 1);
    });

    // Calculate initial scroll offset to center on selected month
    final index = _months.indexWhere(
      (m) => m.year == _selected.year && m.month == _selected.month,
    );
    final initialOffset = index != -1 ? index * 280.0 : 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    final now = DateTime.now();
    setState(() {
      _selected = now;
    });
    final index = _months.indexWhere(
      (m) => m.year == now.year && m.month == now.month,
    );
    if (index != -1 && _scrollController.hasClients) {
      _scrollController.animateTo(
        index * 280.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2260),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _scrollToToday,
            child: Text(
              'TODAY',
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _months.length,
              itemBuilder: (context, idx) {
                final m = _months[idx];
                return _MonthCalendarItem(
                  monthDate: m,
                  selectedDate: _selected,
                  onDayTap: (date) {
                    Navigator.pop(context, date);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendarItem extends StatelessWidget {
  final DateTime monthDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDayTap;

  const _MonthCalendarItem({
    required this.monthDate,
    required this.selectedDate,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday;
    final offset = firstWeekday == 7 ? 0 : firstWeekday; // Sunday is index 0

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              DateFormat('MMMM yyyy').format(monthDate),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DrColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Day initials header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DrColors.textTertiary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth + offset,
            itemBuilder: (ctx, index) {
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
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1B2260)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : DrColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. FullScreenTimePicker - Analog clock matching Image 3
// ─────────────────────────────────────────────────────────────────────────────

class FullScreenTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final int initialDurationMinutes;

  const FullScreenTimePicker({
    super.key,
    required this.initialTime,
    required this.initialDurationMinutes,
  });

  @override
  State<FullScreenTimePicker> createState() => _FullScreenTimePickerState();
}

class _FullScreenTimePickerState extends State<FullScreenTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;
  late String _period; // 'AM' or 'PM'
  late int _durationMinutes;
  bool _pickingHours = true; // True for Hour picking, False for Minute picking

  final List<int> _durations = [15, 30, 45, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hourOfPeriod == 0
        ? 12
        : widget.initialTime.hourOfPeriod;
    _selectedMinute = widget.initialTime.minute;
    _period = widget.initialTime.period == DayPeriod.am ? 'AM' : 'PM';
    _durationMinutes =
        widget.initialTime.period == DayPeriod.am &&
            widget.initialDurationMinutes == 0
        ? 30
        : widget.initialDurationMinutes;
  }

  void _save() {
    int hour = _selectedHour;
    if (_period == 'AM') {
      if (hour == 12) hour = 0;
    } else {
      if (hour != 12) hour += 12;
    }
    final time = TimeOfDay(hour: hour, minute: _selectedMinute);
    Navigator.pop(context, {'time': time, 'duration': _durationMinutes});
  }

  void _handleDialSelection(double dx, double dy, double radius) {
    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;

    if (_pickingHours) {
      int hr = (angle / (2 * pi / 12)).round();
      if (hr <= 0) hr += 12;
      if (hr > 12) hr -= 12;
      setState(() {
        _selectedHour = hr;
      });
    } else {
      int min = (angle / (2 * pi / 60)).round();
      if (min < 0) min += 60;
      if (min >= 60) min -= 60;
      setState(() {
        _selectedMinute = min;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialSize = MediaQuery.of(context).size.width * 0.7;
    final center = dialSize / 2;

    // Calculate hand angle
    double handAngle;
    if (_pickingHours) {
      handAngle = (_selectedHour * (2 * pi / 12)) - pi / 2;
    } else {
      handAngle = (_selectedMinute * (2 * pi / 60)) - pi / 2;
    }

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
          'SELECT TIME',
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
            onPressed: _save,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 36),
            // Header Display Area
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _pickingHours = true),
                  child: Text(
                    _selectedHour.toString().padLeft(2, '0'),
                    style: GoogleFonts.inter(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: _pickingHours
                          ? Colors.orange
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                Text(
                  ':',
                  style: GoogleFonts.inter(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade300,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _pickingHours = false),
                  child: Text(
                    _selectedMinute.toString().padLeft(2, '0'),
                    style: GoogleFonts.inter(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: !_pickingHours
                          ? Colors.orange
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _period = 'AM'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _period == 'AM'
                              ? Colors.orange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _period == 'AM'
                                ? Colors.orange
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          'AM',
                          style: GoogleFonts.inter(
                            color: _period == 'AM'
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => setState(() => _period = 'PM'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _period == 'PM'
                              ? Colors.orange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _period == 'PM'
                                ? Colors.orange
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          'PM',
                          style: GoogleFonts.inter(
                            color: _period == 'PM'
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Clock Dial
            Center(
              child: SizedBox(
                width: dialSize,
                height: dialSize,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final dx = details.localPosition.dx - center;
                    final dy = details.localPosition.dy - center;
                    _handleDialSelection(dx, dy, center);
                  },
                  onTapDown: (details) {
                    final dx = details.localPosition.dx - center;
                    final dy = details.localPosition.dy - center;
                    _handleDialSelection(dx, dy, center);
                  },
                  onPanEnd: (_) {
                    if (_pickingHours) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() {
                            _pickingHours = false;
                          });
                        }
                      });
                    }
                  },
                  onTapUp: (_) {
                    if (_pickingHours) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() {
                            _pickingHours = false;
                          });
                        }
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      // Dial plate
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Pointer Hand & Selected Circle
                      CustomPaint(
                        size: Size(dialSize, dialSize),
                        painter: _ClockHandPainter(
                          angle: handAngle,
                          radius: center * 0.75,
                          center: Offset(center, center),
                        ),
                      ),
                      // Positioned hour/minute numbers
                      for (int i = 1; i <= 12; i++)
                        _buildClockNumber(i, center, center * 0.75),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Set Duration Section
            Container(
              width: double.infinity,
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Duration',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _durationMinutes,
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      labelStyle: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: DrColors.border),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                    ),
                    items: _durations.map((d) {
                      String label = '$d minutes';
                      if (d >= 60) {
                        final hours = d / 60;
                        label = hours == 1.0
                            ? '1 hour'
                            : '${hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1)} hours';
                      }
                      return DropdownMenuItem<int>(
                        value: d,
                        child: Text(
                          label,
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _durationMinutes = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockNumber(int i, double center, double radius) {
    // Number coordinates
    final theta = (i * 2 * pi / 12) - pi / 2;
    final x = center + radius * cos(theta) - 15;
    final y = center + radius * sin(theta) - 15;

    // Value to show
    String valueStr = i.toString();
    bool isSelectedVal = false;
    if (_pickingHours) {
      isSelectedVal = _selectedHour == i;
    } else {
      final value = (i * 5) % 60;
      valueStr = value.toString().padLeft(2, '0');
      isSelectedVal = _selectedMinute == value;
    }

    return Positioned(
      left: x,
      top: y,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: Text(
            valueStr,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isSelectedVal ? FontWeight.w800 : FontWeight.w500,
              color: isSelectedVal ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClockHandPainter extends CustomPainter {
  final double angle;
  final double radius;
  final Offset center;

  _ClockHandPainter({
    required this.angle,
    required this.radius,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    // Draw hand line
    final endPoint = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
    canvas.drawLine(center, endPoint, paint);

    // Draw center point
    canvas.drawCircle(center, 4.0, paint);

    // Draw selector circular border
    final paintCircle = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, 15.0, paintCircle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// FullScreenDateRangePicker
// ─────────────────────────────────────────────────────────────────────────────

class FullScreenDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  const FullScreenDateRangePicker({super.key, this.initialRange});

  @override
  State<FullScreenDateRangePicker> createState() => _FullScreenDateRangePickerState();
}

class _FullScreenDateRangePickerState extends State<FullScreenDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  late List<DateTime> _months;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _startDate = widget.initialRange!.start;
      _endDate = widget.initialRange!.end;
    }

    final now = DateTime.now();
    final base = DateTime(now.year, now.month, 1);
    _months = List.generate(12, (i) {
      return DateTime(base.year, base.month + i, 1);
    });

    final targetDate = _startDate ?? now;
    final index = _months.indexWhere(
      (m) => m.year == targetDate.year && m.month == targetDate.month,
    );
    final initialOffset = index != -1 ? index * 280.0 : 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



  void _onDayTap(DateTime date) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
      } else if (date.isBefore(_startDate!)) {
        _startDate = date;
      } else {
        _endDate = date;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _startDate != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2260),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Range',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: canSave
                ? () {
                    final start = _startDate!;
                    final end = _endDate ?? start;
                    Navigator.pop(context, DateTimeRange(start: start, end: end));
                  }
                : null,
            child: Text(
              'SAVE',
              style: GoogleFonts.inter(
                color: canSave ? Colors.white : Colors.white60,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected Range Preview Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: const Color(0xFF1B2260).withOpacity(0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START DATE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DrColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _startDate == null
                          ? 'Select date'
                          : DateFormat('EEE, MMM d').format(_startDate!),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _startDate == null ? DrColors.textTertiary : DrColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_rounded, color: DrColors.textTertiary, size: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'END DATE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DrColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _endDate == null
                          ? (_startDate == null ? 'Select date' : DateFormat('EEE, MMM d').format(_startDate!))
                          : DateFormat('EEE, MMM d').format(_endDate!),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _startDate == null ? DrColors.textTertiary : DrColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _months.length,
              itemBuilder: (context, idx) {
                final m = _months[idx];
                return _MonthCalendarRangeItem(
                  monthDate: m,
                  startDate: _startDate,
                  endDate: _endDate,
                  onDayTap: _onDayTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCalendarRangeItem extends StatelessWidget {
  final DateTime monthDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onDayTap;

  const _MonthCalendarRangeItem({
    required this.monthDate,
    required this.startDate,
    required this.endDate,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday;
    final offset = firstWeekday == 7 ? 0 : firstWeekday; // Sunday is index 0

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              DateFormat('MMMM yyyy').format(monthDate),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DrColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Day initials header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DrColors.textTertiary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth + offset,
            itemBuilder: (ctx, index) {
              if (index < offset) {
                return const SizedBox.shrink();
              }
              final day = index - offset + 1;
              final dayDate = DateTime(monthDate.year, monthDate.month, day);

              bool isStart = false;
              bool isEnd = false;
              bool isInRange = false;

              if (startDate != null) {
                isStart = dayDate.year == startDate!.year &&
                    dayDate.month == startDate!.month &&
                    dayDate.day == startDate!.day;

                if (endDate != null) {
                  isEnd = dayDate.year == endDate!.year &&
                      dayDate.month == endDate!.month &&
                      dayDate.day == endDate!.day;

                  isInRange = dayDate.isAfter(startDate!) && dayDate.isBefore(endDate!);
                }
              }

              final isSelected = isStart || isEnd;

              return GestureDetector(
                onTap: () => onDayTap(dayDate),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1B2260)
                        : (isInRange
                            ? const Color(0xFF1B2260).withOpacity(0.08)
                            : Colors.transparent),
                    shape: isSelected ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isSelected
                        ? null
                        : (isInRange ? BorderRadius.circular(4) : null),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isInRange ? const Color(0xFF1B2260) : DrColors.textPrimary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
