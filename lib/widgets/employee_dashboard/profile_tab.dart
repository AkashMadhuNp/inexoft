import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileTab extends StatelessWidget {
  final Map<String, dynamic>? employeeData;
  const ProfileTab({super.key, this.employeeData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF1976D2),
                    child: Text(
                      _getInitials(employeeData?['fullName'] ?? 'User'),
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    employeeData?['fullName'] ?? 'Loading...',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    employeeData?['designation'] ?? 'Loading...',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  _buildProfileInfo(Icons.badge, 'Employee ID', employeeData?['employeeId'] ?? 'N/A'),
                  _buildProfileInfo(Icons.business, 'Department', employeeData?['department'] ?? 'N/A'),
                  _buildProfileInfo(Icons.email, 'Email', employeeData?['email'] ?? 'N/A'),
                  _buildProfileInfo(Icons.calendar_today, 'Joining Date', _formatDate(employeeData?['joiningDate'])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF1976D2)),
      title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: GoogleFonts.inter(color: Colors.grey[600])),
    );
  }

  String _getInitials(String name) {
    return name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Not specified';
    try {
      DateTime date = timestamp is Timestamp ? timestamp.toDate() : timestamp as DateTime;
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return 'Invalid date';
    }
  }
}