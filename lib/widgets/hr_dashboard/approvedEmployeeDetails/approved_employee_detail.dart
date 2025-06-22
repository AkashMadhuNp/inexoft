import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inexo/widgets/hr_dashboard/approvedEmployeeDetails/leave_managment.dart';
import 'package:inexo/widgets/hr_dashboard/approvedEmployeeDetails/permisson_card.dart';


class ApprovedEmployeeDetail extends StatelessWidget {
  final Map<String, dynamic> employeeData;
  final String docId;

  const ApprovedEmployeeDetail({
    super.key,
    required this.employeeData,
    required this.docId,
  });

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'N/A';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(employeeData['fullName'] ?? 'Employee Details'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main Employee Card
            Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status indicator
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "APPROVED EMPLOYEE",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildDetailRow(Icons.person, "Full Name", employeeData['fullName']),
                    _buildDetailRow(Icons.email, "Email", employeeData['email']),
                    _buildDetailRow(Icons.badge, "Employee ID", employeeData['employeeId']),
                    _buildDetailRow(Icons.work, "Designation", employeeData['designation']),
                    _buildDetailRow(Icons.business, "Department", employeeData['department']),
                    _buildDetailRow(Icons.calendar_today, "Joining Date", _formatTimestamp(employeeData['joiningDate'])),
                    _buildDetailRow(Icons.check_circle_outline, "Approved At", _formatTimestamp(employeeData['approvedAt'])),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Leave Management Card
                  LeaveManagementCard(
        employeeId: docId,  // Pass the employee's document ID
        employeeData: employeeData,  // Pass employee data for display
      ),

            
            const SizedBox(height: 16),
            
            // Permissions Card
            PermissionsCard(employeeData: employeeData),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}