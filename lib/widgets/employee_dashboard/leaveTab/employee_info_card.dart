import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeInfoCard extends StatelessWidget {
  final Map<String, dynamic>? employeeData;

  const EmployeeInfoCard({super.key, this.employeeData});

  @override
  Widget build(BuildContext context) {
    if (employeeData == null) return SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF1976D2),
                  child: Text(
                    employeeData!['fullName']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeData!['fullName'] ?? 'Unknown',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        employeeData!['designation'] ?? 'No designation',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      Text(
                        '${employeeData!['department'] ?? 'No department'} • ${employeeData!['employeeId'] ?? 'No ID'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}