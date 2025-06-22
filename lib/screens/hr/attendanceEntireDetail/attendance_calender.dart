import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceCalendarScreen extends StatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  State<AttendanceCalendarScreen> createState() => _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  late final ValueNotifier<List<AttendanceRecord>> _selectedAttendance;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<DateTime, List<AttendanceRecord>> _attendanceData = {};
  bool _isLoading = true;
  bool _isLoadingSelectedDay = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedAttendance = ValueNotifier([]);
    _loadAttendanceOverview();
    _loadSelectedDayAttendance(_selectedDay!);
  }

  @override
  void dispose() {
    _selectedAttendance.dispose();
    super.dispose();
  }

  String _getDateKey(DateTime date) => 
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // Load overview data for calendar markers
  Future<void> _loadAttendanceOverview() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final startKey = _getDateKey(startOfMonth);
      final endKey = _getDateKey(endOfMonth);

      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: startKey)
          .where('date', isLessThanOrEqualTo: endKey)
          .get();

      Map<DateTime, List<AttendanceRecord>> attendanceMap = {};

      for (var doc in attendanceSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        if (data['date'] != null) {
          String dateStr = data['date'] as String;
          List<String> dateParts = dateStr.split('-');
          DateTime date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );

          // Create a simple record for calendar markers
          AttendanceRecord record = AttendanceRecord(
            employeeId: data['employeeId'] ?? '',
            employeeName: 'Employee', // We'll get the full name when day is selected
            clockInTime: null,
            clockOutTime: null,
          );

          if (attendanceMap[date] != null) {
            attendanceMap[date]!.add(record);
          } else {
            attendanceMap[date] = [record];
          }
        }
      }

      setState(() {
        _attendanceData = attendanceMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading attendance overview: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load detailed attendance data for selected day
  Future<void> _loadSelectedDayAttendance(DateTime selectedDate) async {
    setState(() {
      _isLoadingSelectedDay = true;
    });

    try {
      String dateKey = _getDateKey(selectedDate);
      
      // Get attendance records for the selected date
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: dateKey)
          .get();

      List<AttendanceRecord> attendanceRecords = [];

      for (var doc in attendanceSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        String employeeId = data['employeeId'] ?? '';
        DateTime? clockInTime = (data['clockInTime'] as Timestamp?)?.toDate();
        DateTime? clockOutTime = (data['clockOutTime'] as Timestamp?)?.toDate();
        
        // Get employee name from approved_employee collection
        String employeeName = await _getEmployeeName(employeeId);
        
        AttendanceRecord record = AttendanceRecord(
          employeeId: employeeId,
          employeeName: employeeName,
          clockInTime: clockInTime,
          clockOutTime: clockOutTime,
        );

        attendanceRecords.add(record);
      }

      _selectedAttendance.value = attendanceRecords;
    } catch (e) {
      print('Error loading selected day attendance: $e');
      _selectedAttendance.value = [];
    } finally {
      setState(() {
        _isLoadingSelectedDay = false;
      });
    }
  }

  // Get employee name from approved_employee collection
  Future<String> _getEmployeeName(String employeeId) async {
    try {
      DocumentSnapshot employeeDoc = await _firestore
          .collection('approved_employee')
          .doc(employeeId)
          .get();

      if (employeeDoc.exists) {
        Map<String, dynamic> employeeData = employeeDoc.data() as Map<String, dynamic>;
        return employeeData['name'] ?? employeeData['fullName'] ?? 'Unknown Employee';
      }
    } catch (e) {
      print('Error getting employee name: $e');
    }
    return 'Employee $employeeId';
  }

  List<AttendanceRecord> _getAttendanceForDay(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return _attendanceData[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _loadSelectedDayAttendance(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null) {
      _loadSelectedDayAttendance(start);
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Not recorded';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Attendance Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF1976D2),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Calendar Widget
                  Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TableCalendar<AttendanceRecord>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      eventLoader: _getAttendanceForDay,
                      rangeSelectionMode: _rangeSelectionMode,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      rangeStartDay: _rangeStart,
                      rangeEndDay: _rangeEnd,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: TextStyle(color: Colors.red[400]),
                        holidayTextStyle: TextStyle(color: Colors.red[400]),
                        selectedDecoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        markerSize: 6,
                        markersMaxCount: 3,
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonShowsNext: false,
                        formatButtonDecoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        formatButtonTextStyle: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onDaySelected: _onDaySelected,
                      onRangeSelected: _onRangeSelected,
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadAttendanceOverview(); // Reload data for new month
                      },
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  // Attendance Records List
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: const Color(0xFF1976D2),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _selectedDay != null 
                                      ? 'Attendance for ${_formatDate(_selectedDay!)}'
                                      : 'Select a date to view attendance',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _isLoadingSelectedDay
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: const Color(0xFF1976D2),
                                    ),
                                  )
                                : ValueListenableBuilder<List<AttendanceRecord>>(
                                    valueListenable: _selectedAttendance,
                                    builder: (context, attendanceList, _) {
                                      if (attendanceList.isEmpty) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.event_busy,
                                                size: 64,
                                                color: Colors.grey[400],
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'No attendance records for this date',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        itemCount: attendanceList.length,
                                        itemBuilder: (context, index) {
                                          final record = attendanceList[index];
                                          bool isComplete = record.clockOutTime != null;
                                          
                                          return Container(
                                            margin: EdgeInsets.only(bottom: 12),
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isComplete 
                                                    ? Colors.green.withOpacity(0.3)
                                                    : Colors.orange.withOpacity(0.3),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: isComplete 
                                                            ? Colors.green.withOpacity(0.1)
                                                            : Colors.orange.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Icon(
                                                        isComplete ? Icons.check_circle : Icons.access_time,
                                                        color: isComplete ? Colors.green : Colors.orange,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            record.employeeName,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                          SizedBox(height: 2),
                                                          Text(
                                                            'ID: ${record.employeeId}',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isComplete 
                                                            ? Colors.green.withOpacity(0.1)
                                                            : Colors.orange.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        isComplete ? 'Complete' : 'In Progress',
                                                        style: TextStyle(
                                                          color: isComplete ? Colors.green : Colors.orange,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                Container(
                                                  padding: EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[50],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Clock In',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey[600],
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              _formatTime(record.clockInTime),
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.green[700],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        width: 1,
                                                        height: 30,
                                                        color: Colors.grey[300],
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            Text(
                                                              'Clock Out',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey[600],
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              _formatTime(record.clockOutTime),
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.bold,
                                                                color: record.clockOutTime != null 
                                                                    ? Colors.red[700]
                                                                    : Colors.grey[500],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class AttendanceRecord {
  final String employeeId;
  final String employeeName;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;

  const AttendanceRecord({
    required this.employeeId,
    required this.employeeName,
    required this.clockInTime,
    required this.clockOutTime,
  });

  @override
  String toString() => employeeName;
}