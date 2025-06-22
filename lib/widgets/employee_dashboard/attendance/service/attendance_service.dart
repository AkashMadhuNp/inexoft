import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  LocationData? _clockInLocation;
  String? _clockInAddress;
  DateTime? _clockInTime;
  DateTime? _clockOutTime;
  Timer? _stopwatchTimer;
  String _stopwatchTime = '00:00:00';
  Map<String, Map<String, dynamic>> _attendanceRecords = {};
  String? _employeeId; // Store the employee ID from approved_employee collection

  // Collection references
  CollectionReference get _attendanceCollection => 
      _firestore.collection('attendance');
  
  CollectionReference get _approvedEmployeeCollection => 
      _firestore.collection('approved_employee');

  // Current user ID from Firebase Auth
  String? get _currentUserId => _auth.currentUser?.uid;

  // Employee ID from approved_employee collection
  String? get employeeId => _employeeId;

  // Getters
  LocationData? get clockInLocation => _clockInLocation;
  String? get clockInAddress => _clockInAddress;
  DateTime? get clockInTime => _clockInTime;
  DateTime? get clockOutTime => _clockOutTime;
  String get stopwatchTime => _stopwatchTime;
  Map<String, Map<String, dynamic>> get attendanceRecords => _attendanceRecords;

  /// Initialize service and load user's attendance data
  Future<void> initialize() async {
    if (_currentUserId != null) {
      await _getEmployeeId();
      if (_employeeId != null) {
        await _loadAttendanceData();
      }
    }
  }

  /// Get employee ID from approved_employee collection using Firebase Auth UID
  Future<void> _getEmployeeId() async {
    try {
      if (_currentUserId == null) return;

      final QuerySnapshot snapshot = await _approvedEmployeeCollection
          .where('uid', isEqualTo: _currentUserId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _employeeId = snapshot.docs.first.id; // Use document ID as employee ID
        print('Employee ID found: $_employeeId');
      } else {
        throw Exception('Employee not found in approved_employee collection');
      }
    } catch (e) {
      print('Error getting employee ID: $e');
      throw Exception('Failed to get employee ID: ${e.toString()}');
    }
  }

  /// Load attendance data from Firebase using employee ID
  Future<void> _loadAttendanceData() async {
    try {
      if (_employeeId == null) return;

      final QuerySnapshot snapshot = await _attendanceCollection
          .where('employeeId', isEqualTo: _employeeId)
          .get();

      _attendanceRecords.clear();
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateKey = data['date'] as String;
        
        // Safely handle location data reconstruction
        LocationData? locationData;
        if (data['clockInLocation'] != null) {
          final locationMap = Map<String, dynamic>.from(data['clockInLocation']);
          try {
            locationData = LocationData.fromMap({
              'latitude': locationMap['latitude'],
              'longitude': locationMap['longitude'],
              'accuracy': locationMap['accuracy'],
              'altitude': locationMap['altitude'],
              'speed': locationMap['speed'],
              'speedAccuracy': locationMap['speedAccuracy'],
              'heading': locationMap['heading'],
              'time': locationMap['time']?.toDouble(),
            });
          } catch (e) {
            print('Error reconstructing location data: $e');
            locationData = null;
          }
        }
        
        _attendanceRecords[dateKey] = {
          'docId': doc.id,
          'clockInTime': (data['clockInTime'] as Timestamp?)?.toDate(),
          'clockOutTime': (data['clockOutTime'] as Timestamp?)?.toDate(),
          'clockInLocation': locationData,
          'clockInAddress': data['clockInAddress'] ?? '',
          'totalHours': data['totalHours'],
          'status': data['status'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
        };
      }

      // Check if user is currently clocked in today
      await _checkTodayClockInStatus();
    } catch (e) {
      throw Exception('Failed to load attendance data: ${e.toString()}');
    }
  }

  /// Check if user is currently clocked in today and restore stopwatch
  Future<void> _checkTodayClockInStatus() async {
    final todayKey = _getDateKey(DateTime.now());
    final todayRecord = _attendanceRecords[todayKey];
    
    if (todayRecord != null && todayRecord['status'] == 'clocked_in') {
      _clockInTime = todayRecord['clockInTime'];
      
      // Safely reconstruct LocationData from stored map
      if (todayRecord['clockInLocation'] != null) {
        try {
          _clockInLocation = todayRecord['clockInLocation'] as LocationData?;
        } catch (e) {
          print('Error reconstructing location data: $e');
          _clockInLocation = null;
        }
      }
      
      _clockInAddress = todayRecord['clockInAddress'];
      
      // Restart stopwatch from existing time
      _startStopwatchFromExistingTime();
    }
  }

  /// Start stopwatch from existing clock-in time
  void _startStopwatchFromExistingTime() {
    if (_clockInTime != null) {
      _stopwatchTimer?.cancel();
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final duration = DateTime.now().difference(_clockInTime!);
        _stopwatchTime = _formatDuration(duration);
      });
    }
  }

  Future<void> getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    try {
      // Check location service
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location service is required');
        }
      }

      // Check permissions
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Location permission denied');
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

      _clockInLocation = locationData;
      _clockInAddress = address;
    } catch (e) {
      throw Exception('Error getting location: ${e.toString()}');
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
    return parts.take(3).join(', ');
  }

  void startStopwatch() {
    _clockInTime = DateTime.now();
    _stopwatchTimer?.cancel();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_clockInTime != null) {
        final duration = DateTime.now().difference(_clockInTime!);
        _stopwatchTime = _formatDuration(duration);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  bool canClockInToday() {
    if (_employeeId == null) return false;
    String dateKey = _getDateKey(DateTime.now());
    return !_attendanceRecords.containsKey(dateKey) || 
           _attendanceRecords[dateKey]?['status'] == null;
  }

  bool canClockOutToday() {
    if (_employeeId == null) return false;
    String dateKey = _getDateKey(DateTime.now());
    return _attendanceRecords.containsKey(dateKey) &&
           _attendanceRecords[dateKey]?['status'] == 'clocked_in' &&
           _attendanceRecords[dateKey]?['clockOutTime'] == null;
  }

  /// Clock in with Firebase storage using employee ID
  Future<void> clockIn() async {
    if (_employeeId == null) {
      throw Exception('Employee ID not found');
    }

    String dateKey = _getDateKey(DateTime.now());
    if (!canClockInToday()) {
      throw Exception('Already clocked in today');
    }

    try {
      // Start stopwatch immediately when clock in is initiated
      startStopwatch();
      
      // Serialize location data safely
      Map<String, dynamic>? locationMap;
      if (_clockInLocation != null) {
        locationMap = {
          'latitude': _clockInLocation!.latitude,
          'longitude': _clockInLocation!.longitude,
          'accuracy': _clockInLocation!.accuracy,
          'altitude': _clockInLocation!.altitude,
          'speed': _clockInLocation!.speed,
          'speedAccuracy': _clockInLocation!.speedAccuracy,
          'heading': _clockInLocation!.heading,
          'time': _clockInLocation!.time?.toInt(),
        };
      }

      final attendanceData = {
        'employeeId': _employeeId!, // Use employee ID instead of user ID
        'date': dateKey,
        'clockInTime': Timestamp.fromDate(_clockInTime!),
        'clockInLocation': locationMap,
        'clockInAddress': _clockInAddress ?? '',
        'status': 'clocked_in',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'clockOutTime': null,
        'totalHours': null,
      };

      final DocumentReference docRef = await _attendanceCollection.add(attendanceData);

      // Update local cache
      _attendanceRecords[dateKey] = {
        'docId': docRef.id,
        'clockInTime': _clockInTime,
        'clockInLocation': _clockInLocation,
        'clockInAddress': _clockInAddress,
        'status': 'clocked_in',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
    } catch (e) {
      // Stop stopwatch if clock in fails
      _stopwatchTimer?.cancel();
      _clockInTime = null;
      _stopwatchTime = '00:00:00';
      print('Clock-in error details: $e');
      throw Exception('Failed to save clock-in data: ${e.toString()}');
    }
  }

  /// Clock out with Firebase update
  Future<void> clockOut() async {
    if (_employeeId == null) {
      throw Exception('Employee ID not found');
    }

    String dateKey = _getDateKey(DateTime.now());
    if (!canClockOutToday()) {
      throw Exception('No active clock-in session or already clocked out today');
    }

    try {
      _stopwatchTimer?.cancel();
      _clockOutTime = DateTime.now();

      final docId = _attendanceRecords[dateKey]?['docId'];
      if (docId == null) {
        throw Exception('No document ID found for today\'s attendance');
      }

      final updateData = {
        'clockOutTime': Timestamp.fromDate(_clockOutTime!),
        'totalHours': _stopwatchTime,
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _attendanceCollection.doc(docId).update(updateData);

      // Update local cache
      if (_attendanceRecords.containsKey(dateKey)) {
        _attendanceRecords[dateKey]!.addAll({
          'clockOutTime': _clockOutTime,
          'totalHours': _stopwatchTime,
          'status': 'completed',
          'updatedAt': DateTime.now(),
        });
      }

      // Reset stopwatch
      _stopwatchTime = '00:00:00';
      _clockInTime = null;
      _clockOutTime = null;
    } catch (e) {
      throw Exception('Failed to save clock-out data: ${e.toString()}');
    }
  }

  /// Get attendance records for a specific month
  Future<void> loadMonthlyAttendance(DateTime month) async {
    if (_employeeId == null) return;

    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);
      
      final startKey = _getDateKey(startOfMonth);
      final endKey = _getDateKey(endOfMonth);

      final QuerySnapshot snapshot = await _attendanceCollection
          .where('employeeId', isEqualTo: _employeeId)
          .where('date', isGreaterThanOrEqualTo: startKey)
          .where('date', isLessThanOrEqualTo: endKey)
          .get();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateKey = data['date'] as String;
        
        // Safely handle location data reconstruction
        LocationData? locationData;
        if (data['clockInLocation'] != null) {
          final locationMap = Map<String, dynamic>.from(data['clockInLocation']);
          try {
            locationData = LocationData.fromMap({
              'latitude': locationMap['latitude'],
              'longitude': locationMap['longitude'],
              'accuracy': locationMap['accuracy'],
              'altitude': locationMap['altitude'],
              'speed': locationMap['speed'],
              'speedAccuracy': locationMap['speedAccuracy'],
              'heading': locationMap['heading'],
              'time': locationMap['time']?.toDouble(),
            });
          } catch (e) {
            print('Error reconstructing location data: $e');
            locationData = null;
          }
        }
        
        _attendanceRecords[dateKey] = {
          'docId': doc.id,
          'clockInTime': (data['clockInTime'] as Timestamp?)?.toDate(),
          'clockOutTime': (data['clockOutTime'] as Timestamp?)?.toDate(),
          'clockInLocation': locationData,
          'clockInAddress': data['clockInAddress'] ?? '',
          'totalHours': data['totalHours'],
          'status': data['status'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
        };
      }
    } catch (e) {
      throw Exception('Failed to load monthly attendance: ${e.toString()}');
    }
  }

  String _getDateKey(DateTime date) => 
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String formatTime(DateTime time) => 
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  bool isPastDate(DateTime date) => date.isBefore(DateTime.now()) && !isToday(date);

  bool isFutureDate(DateTime date) => date.isAfter(DateTime.now());

  Map<String, dynamic>? getSelectedDayRecord(DateTime? selectedDay) {
    if (selectedDay == null) return null;
    String dateKey = _getDateKey(selectedDay);
    return _attendanceRecords[dateKey];
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Check if user is currently clocked in
  bool get isClockedInToday {
    final todayKey = _getDateKey(DateTime.now());
    return _attendanceRecords[todayKey]?['status'] == 'clocked_in';
  }

  /// Clean up resources
  void dispose() {
    _stopwatchTimer?.cancel();
  }
}