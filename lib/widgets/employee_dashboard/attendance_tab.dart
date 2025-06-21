import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';

class AttendanceTab extends StatefulWidget {
  final Map<String, dynamic>? employeeData;
  const AttendanceTab({super.key, this.employeeData});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  bool _isClockedIn = false;
  bool _isLocationLoading = false;
  String _stopwatchTime = '00:00:00';
  Timer? _stopwatchTimer;
  DateTime? _clockInTime;
  DateTime? _clockOutTime;
  LocationData? _clockInLocation;
  String? _clockInAddress;
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Store attendance records by date
  Map<String, Map<String, dynamic>> _attendanceRecords = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  // Location Methods
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    try {
      // Check location service
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _showSnackBar('Location service is required', Colors.red);
          return;
        }
      }

      // Check permissions
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _showSnackBar('Location permission denied', Colors.red);
          return;
        }
      }

      // Configure high accuracy
      await location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 1000,
        distanceFilter: 0,
      );

      // Get location
      LocationData locationData = await location.getLocation().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Location request timed out'),
      );

      // Get address
      String address = await _getAddressFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      setState(() {
        _clockInLocation = locationData;
        _clockInAddress = address;
        _isLocationLoading = false;
      });

    } catch (e) {
      setState(() => _isLocationLoading = false);
      _showSnackBar('Error getting location: ${e.toString()}', Colors.red);
      rethrow;
    }
  }

  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return _formatAddress(place);
      }
      return 'Unknown location';
    } catch (e) {
      return 'Address unavailable';
    }
  }

  String _formatAddress(Placemark placemark) {
    List<String> parts = [];
    if (placemark.name?.isNotEmpty == true) parts.add(placemark.name!);
    if (placemark.street?.isNotEmpty == true) parts.add(placemark.street!);
    if (placemark.locality?.isNotEmpty == true) parts.add(placemark.locality!);
    if (placemark.administrativeArea?.isNotEmpty == true) parts.add(placemark.administrativeArea!);
    return parts.take(3).join(', '); // Limit to first 3 parts for brevity
  }

  // Stopwatch Methods
  void _startStopwatch() {
    _clockInTime = DateTime.now();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_clockInTime != null) {
        final duration = DateTime.now().difference(_clockInTime!);
        setState(() => _stopwatchTime = _formatDuration(duration));
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  // Attendance Methods
  void _clockIn() async {
    try {
      await _getCurrentLocation();
      if (_clockInLocation != null && _clockInAddress != null) {
        setState(() => _isClockedIn = true);
        _startStopwatch();
        
        // Store clock in record
        String dateKey = _getDateKey(DateTime.now());
        _attendanceRecords[dateKey] = {
          'clockInTime': _clockInTime,
          'clockInLocation': _clockInLocation,
          'clockInAddress': _clockInAddress,
          'status': 'clocked_in',
        };
        
        _showSnackBar('Clocked in successfully at ${_formatTime(_clockInTime!)}', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Failed to clock in: ${e.toString()}', Colors.red);
    }
  }

  void _clockOut() {
    _stopwatchTimer?.cancel();
    _clockOutTime = DateTime.now();
    
    setState(() => _isClockedIn = false);
    
    // Update attendance record
    String dateKey = _getDateKey(DateTime.now());
    if (_attendanceRecords.containsKey(dateKey)) {
      _attendanceRecords[dateKey]!['clockOutTime'] = _clockOutTime;
      _attendanceRecords[dateKey]!['totalHours'] = _stopwatchTime;
      _attendanceRecords[dateKey]!['status'] = 'completed';
    }
    
    _showSnackBar('Clocked out at ${_formatTime(_clockOutTime!)}', Colors.green);
  }

  // Utility Methods
  String _getDateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  
  String _formatTime(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  
  bool _isToday(DateTime date) => isSameDay(date, DateTime.now());
  
  bool _isPastDate(DateTime date) => date.isBefore(DateTime.now()) && !_isToday(date);
  
  bool _isFutureDate(DateTime date) => date.isAfter(DateTime.now());

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  Map<String, dynamic>? _getSelectedDayRecord() {
    if (_selectedDay == null) return null;
    String dateKey = _getDateKey(_selectedDay!);
    return _attendanceRecords[dateKey];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCalendarCard(),
          const SizedBox(height: 16),
          _buildStopwatchCard(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 16),
          _buildAttendanceDetails(),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TableCalendar<String>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.now(),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (!_isFutureDate(selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) => setState(() => _calendarFormat = format),
          enabledDayPredicate: (day) => !_isFutureDate(day),
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

  Widget _buildStopwatchCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, color: Colors.blue[700], size: 28),
                const SizedBox(width: 8),
                Text(
                  'Work Hours',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _stopwatchTime,
                style: GoogleFonts.orbitron(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  letterSpacing: 2,
                ),
              ),
            ),
            if (_isClockedIn) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.green[600], size: 12),
                    const SizedBox(width: 6),
                    Text(
                      'Active Session',
                      style: GoogleFonts.inter(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    bool canClockIn = _isToday(_selectedDay ?? DateTime.now()) && !_isClockedIn;
    bool canClockOut = _isToday(_selectedDay ?? DateTime.now()) && _isClockedIn;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canClockIn && !_isLocationLoading ? _clockIn : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: canClockIn ? 4 : 0,
            ),
            icon: _isLocationLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(
              _isLocationLoading ? 'Getting Location...' : 'Clock In',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canClockOut ? _clockOut : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canClockOut ? const Color(0xFFF44336) : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: canClockOut ? 4 : 0,
            ),
            icon: const Icon(Icons.logout),
            label: Text(
              'Clock Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceDetails() {
    final record = _getSelectedDayRecord();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Attendance Details',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (record != null) ...[
              _buildDetailRow('Date', _formatDate(_selectedDay!)),
              if (record['clockInTime'] != null)
                _buildDetailRow('Clock In', _formatTime(record['clockInTime'])),
              if (record['clockOutTime'] != null)
                _buildDetailRow('Clock Out', _formatTime(record['clockOutTime'])),
              if (record['totalHours'] != null)
                _buildDetailRow('Total Hours', record['totalHours']),
              if (record['clockInAddress'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Location:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record['clockInAddress'],
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildStatusChip(record['status']),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      _isToday(_selectedDay!) 
                          ? 'No attendance recorded for today'
                          : 'No attendance data for selected date',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'clocked_in':
        color = Colors.orange;
        text = 'In Progress';
        icon = Icons.play_circle_filled;
        break;
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}