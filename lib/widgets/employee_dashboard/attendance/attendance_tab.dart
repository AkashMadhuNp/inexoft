import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inexo/widgets/employee_dashboard/attendance/action_buttons.dart';
import 'package:inexo/widgets/employee_dashboard/attendance/attendance_details_card.dart';
import 'package:inexo/widgets/employee_dashboard/attendance/calendar_card.dart';
import 'package:inexo/widgets/employee_dashboard/attendance/service/attendance_service.dart';
import 'package:inexo/widgets/employee_dashboard/attendance/stopwatch_card.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceTab extends StatefulWidget {
  final Map<String, dynamic>? employeeData;
  const AttendanceTab({super.key, this.employeeData});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isClockedIn = false;
  bool _isLocationLoading = false;
  bool _isInitializing = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeAttendanceService();
  }

  /// Initialize the attendance service and check current status
  Future<void> _initializeAttendanceService() async {
    try {
      await _attendanceService.initialize();
      
      // Check if user is already clocked in today
      setState(() {
        _isClockedIn = _attendanceService.isClockedInToday;
        _isInitializing = false;
      });

      // Load current month's attendance data
      await _attendanceService.loadMonthlyAttendance(_focusedDay);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializing = false);
        _showSnackBar('Failed to initialize attendance: ${e.toString()}', Colors.red);
      }
    }
  }

  @override
  void dispose() {
    _attendanceService.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle clock in action
  Future<void> _handleClockIn() async {
    setState(() => _isLocationLoading = true);
    
    try {
      print('Starting clock-in process...');
      
      // Get current location
      await _attendanceService.getCurrentLocation();
      print('Location obtained successfully');
      
      if (_attendanceService.clockInLocation != null && 
          _attendanceService.clockInAddress != null) {
        
        print('Saving to Firebase and starting stopwatch...');
        // Clock in (this will start the stopwatch automatically)
        await _attendanceService.clockIn();
        
        setState(() => _isClockedIn = true);
        
        _showSnackBar(
          'Clocked in successfully at ${_attendanceService.formatTime(_attendanceService.clockInTime!)}',
          Colors.green,
        );
        
        print('Clock-in completed successfully');
        
        // Start a timer to update the UI every second to show the running stopwatch
        _startUIUpdateTimer();
      } else {
        throw Exception('Location or address not available');
      }
    } catch (e) {
      print('Clock-in error: $e');
      _showSnackBar('Failed to clock in: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  /// Start UI update timer to refresh stopwatch display
  Timer? _uiUpdateTimer;
  
  void _startUIUpdateTimer() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isClockedIn && mounted) {
        setState(() {
          // This will trigger rebuild and show updated stopwatch time
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// Handle clock out action
  Future<void> _handleClockOut() async {
    try {
      // Save clock out to Firebase
      await _attendanceService.clockOut();
      
      setState(() => _isClockedIn = false);
      
      // Stop UI update timer
      _uiUpdateTimer?.cancel();
      
      _showSnackBar(
        'Clocked out at ${_attendanceService.formatTime(_attendanceService.clockOutTime!)}',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('Failed to clock out: ${e.toString()}', Colors.red);
    }
  }

  /// Handle day selection in calendar
  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (!_attendanceService.isFutureDate(selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      // Load data for the selected month if it's different
      if (selectedDay.month != _focusedDay.month || selectedDay.year != _focusedDay.year) {
        try {
          await _attendanceService.loadMonthlyAttendance(selectedDay);
          if (mounted) setState(() {});
        } catch (e) {
          _showSnackBar('Failed to load attendance data', Colors.orange);
        }
      }
    }
  }

  /// Handle calendar format change
  void _onFormatChanged(CalendarFormat format) {
    setState(() => _calendarFormat = format);
  }

  /// Check if a day has attendance record
  bool _hasAttendanceRecord(DateTime day) {
    final record = _attendanceService.getSelectedDayRecord(day);
    return record != null;
  }

  /// Get event marker for calendar
  List<String> _getEventsForDay(DateTime day) {
    final record = _attendanceService.getSelectedDayRecord(day);
    if (record == null) return [];
    
    List<String> events = [];
    if (record['status'] == 'clocked_in') {
      events.add('clocked_in');
    } else if (record['status'] == 'completed') {
      events.add('completed');
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading attendance data...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Calendar Card
          CalendarCard(
            calendarFormat: _calendarFormat,
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: _onDaySelected,
            onFormatChanged: _onFormatChanged,
            enabledDayPredicate: (day) => !_attendanceService.isFutureDate(day),
            //eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 16),
          
          // Stopwatch Card
          StopwatchCard(
            stopwatchTime: _attendanceService.stopwatchTime,
            isClockedIn: _isClockedIn,
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          ActionButtons(
            canClockIn: _attendanceService.isToday(_selectedDay ?? DateTime.now()) &&
                        _attendanceService.canClockInToday() &&
                        !_isClockedIn,
            canClockOut: _attendanceService.isToday(_selectedDay ?? DateTime.now()) &&
                         _attendanceService.canClockOutToday() &&
                         _isClockedIn,
            isLocationLoading: _isLocationLoading,
            onClockIn: _handleClockIn,
            onClockOut: _handleClockOut,
          ),
          const SizedBox(height: 16),
          
          // Attendance Details Card
          AttendanceDetailsCard(
            record: _attendanceService.getSelectedDayRecord(_selectedDay),
            formattedDate: _attendanceService.formatDate(_selectedDay ?? DateTime.now()),
            isToday: _attendanceService.isToday(_selectedDay ?? DateTime.now()),
          ),
        ],
      ),
    );
  }

  // @override
  // void dispose() {
  //   _uiUpdateTimer?.cancel();
  //   _attendanceService.dispose();
  //   super.dispose();
  // }
}