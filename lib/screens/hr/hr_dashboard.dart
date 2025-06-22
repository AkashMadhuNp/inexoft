import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inexo/screens/hr/attendanceEntireDetail/attendance_calender.dart';
import 'package:inexo/screens/hr/bottom_sheet.dart';
import 'package:inexo/screens/hr/leaveOverview/leave_overview.dart';
import 'package:inexo/screens/login_screen.dart';
import 'package:inexo/widgets/hr_dashboard/appbar.dart';
import 'package:inexo/widgets/hr_dashboard/profile_card.dart';
import 'package:inexo/widgets/hr_dashboard/section_header.dart';
import 'package:inexo/widgets/hr_dashboard/stat_grid.dart';

class HrDashboard extends StatefulWidget {
  const HrDashboard({super.key});

  @override
  State<HrDashboard> createState() => _HrDashboardState();
}

class _HrDashboardState extends State<HrDashboard> {
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Streams for Firestore collections
  late Stream<QuerySnapshot> _approvedEmployeeStream;
  late Stream<QuerySnapshot> _employeeLoginStream;
  late Stream<QuerySnapshot> _rejectedEmployeesStream;
  late Stream<QuerySnapshot> _hrStream;

  Map<String, String> hrInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
    _loadHRInfo();
  }

  void _initializeStreams() {
    // Stream for approved employees
    _approvedEmployeeStream = _firestore
        .collection('approved_employee')
        .orderBy('createdAt', descending: true)
        .snapshots();

    // Stream for pending approvals (employee_login)
    _employeeLoginStream = _firestore
        .collection('employee_login')
        .orderBy('createdAt', descending: true)
        .snapshots();

    // Stream for rejected employees
    _rejectedEmployeesStream = _firestore
        .collection('rejected_employees')
        .orderBy('createdAt', descending: true)
        .snapshots();

    // Stream for HR staff
    _hrStream = _firestore
        .collection('hrlogin')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _loadHRInfo() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot hrDoc = await _firestore
            .collection('hrlogin')
            .doc(currentUser.uid)
            .get();

        if (hrDoc.exists) {
          Map<String, dynamic> data = hrDoc.data() as Map<String, dynamic>;
          setState(() {
            hrInfo = {
              'name': data['fullName'] ?? 'HR Manager',
              'email': data['email'] ?? currentUser.email ?? '',
              'role': data['role'] ?? 'HR Manager',
              'uid': currentUser.uid,
            };
            _isLoading = false;
          });
        } else {
          setState(() {
            hrInfo = {
              'name': 'HR Manager',
              'email': currentUser.email ?? '',
              'role': 'HR Manager',
              'uid': currentUser.uid,
            };
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading HR info: $e');
      setState(() {
        hrInfo = {
          'name': 'HR Manager',
          'email': '',
          'role': 'HR Manager',
          'uid': '',
        };
        _isLoading = false;
      });
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'Profile':
        break;
      case 'Settings':
        break;
      case 'Logout':
        _showLogoutDialog();
        break;
    }
  }

  // Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: const Color(0xFF1976D2),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _handleLogout(); // Proceed with logout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to show the bottom sheet
  void _showAddEmployeeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEmployeeBottomSheet(),
    );
  }

  // Navigate to Attendance Calendar
  void _navigateToAttendanceCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceCalendarScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF1976D2),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: HrAppBar(
        hrInfo: hrInfo,
        onMenuSelected: _handleMenuAction,
      ),
      body: _buildBody(size),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeBottomSheet,
        backgroundColor: const Color(0xFF1976D2),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(Size size) {
    return Container(
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            // Profile Card with Attendance Detail Button
            Column(
              children: [
                HrProfileCard(hrInfo: hrInfo),
                SizedBox(height: 16),
                // Attendance Detail Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAttendanceCalendar,
                    icon: Icon(Icons.calendar_today, size: 20),
                    label: Text(
                      'Attendance Detail',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SectionHeader(
              title: "OVERVIEWS",
              icon: Icons.dashboard,
            ),
            SizedBox(height: 16),
            Expanded(
              child: CarouselSlider(
                options: CarouselOptions(
                  height: double.infinity,
                  viewportFraction: 1.0,
                  enlargeCenterPage: false,
                  enableInfiniteScroll: false,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 3),
                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                  autoPlayCurve: Curves.easeInOut,
                ),
                items: [
                  // Dashboard Overview
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: "DASHBOARD OVERVIEW",
                        icon: Icons.analytics,
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: StatisticsGrid(
                          approvedEmployeeStream: _approvedEmployeeStream,
                          employeeLoginStream: _employeeLoginStream,
                          rejectedEmployeesStream: _rejectedEmployeesStream,
                          hrLoginStream: _hrStream,
                        ),
                      ),
                    ],
                  ),
                  // Leave Request Overview
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: "LEAVE REQUEST OVERVIEW",
                        icon: Icons.event_note,
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: LeaveRequestOverview(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}