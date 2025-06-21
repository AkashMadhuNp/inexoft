import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inexo/screens/hr/bottom_sheet.dart';
import 'package:inexo/screens/hr/leaveOverview/leave_overview.dart';
import 'package:inexo/services/validation_service.dart';
import 'package:inexo/widgets/hr_dashboard/appbar.dart';
import 'package:inexo/widgets/hr_dashboard/profile_card.dart';
import 'package:inexo/widgets/hr_dashboard/section_header.dart';
import 'package:inexo/widgets/hr_dashboard/stat_grid.dart';
import 'package:inexo/widgets/signUp/custom_text_field.dart';

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
        _handleLogout();
        break;
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      // Navigate to login screen
      // Navigator.of(context).pushReplacementNamed('/login');
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
        onPressed: _showAddEmployeeBottomSheet, // Changed this line
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
            HrProfileCard(hrInfo: hrInfo),
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
                  autoPlay: true, // Enable auto-play
                  autoPlayInterval: Duration(seconds: 3), // 3-second interval
                  autoPlayAnimationDuration: Duration(milliseconds: 800), // Smooth transition
                  autoPlayCurve: Curves.easeInOut, // Easing for transitions
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


