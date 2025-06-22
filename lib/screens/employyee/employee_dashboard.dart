import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inexo/screens/login_screen.dart';
import 'package:inexo/widgets/employee_dashboard/attendance/attendance_tab.dart';

import 'dart:async';

import 'package:inexo/widgets/employee_dashboard/leaveTab/leave_tab.dart';
import 'package:inexo/widgets/employee_dashboard/profile_tab.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? employeeData;
  bool isLoading = true;
  String? errorMessage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchEmployeeData();
  }

  Future<void> _fetchEmployeeData() async {
    try {
      setState(() => isLoading = true);
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      DocumentSnapshot employeeDoc = await _firestore
          .collection('approved_employee')
          .doc(currentUser.uid)
          .get();

      if (employeeDoc.exists) {
        setState(() {
          employeeData = employeeDoc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        throw Exception('Employee data not found');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading employee data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text(
                'Confirm Logout',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: GoogleFonts.inter(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen(),));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(errorMessage!, style: GoogleFonts.inter(fontSize: 16, color: Colors.red)),
              ElevatedButton(onPressed: _fetchEmployeeData, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Dashboard', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Color(0xFF1976D2),
        actions: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Text(
              _getInitials(employeeData?['fullName'] ?? 'User'),
              style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => value == 'Logout' ? _showLogoutDialog() : null,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Profile', child: Text('Profile')),
              PopupMenuItem(value: 'Settings', child: Text('Settings')),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'Logout',
                child: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.event_note), text: 'Leaves'),
            Tab(icon: Icon(Icons.access_time), text: 'Attendance'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          LeaveTab(employeeData: employeeData),
          AttendanceTab(employeeData: employeeData),
          ProfileTab(employeeData: employeeData),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    return name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
  }
}