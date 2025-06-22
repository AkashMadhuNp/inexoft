import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarCard extends StatelessWidget {
  final CalendarFormat calendarFormat;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final bool Function(DateTime) enabledDayPredicate;

  const CalendarCard({
    super.key,
    required this.calendarFormat,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.enabledDayPredicate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TableCalendar<String>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.now(),
          focusedDay: focusedDay,
          calendarFormat: calendarFormat,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          onFormatChanged: onFormatChanged,
          enabledDayPredicate: enabledDayPredicate,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)],
            ),
            selectedDecoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)],
            ),
            disabledDecoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
            weekendTextStyle: TextStyle(color: Colors.red[600]),
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}