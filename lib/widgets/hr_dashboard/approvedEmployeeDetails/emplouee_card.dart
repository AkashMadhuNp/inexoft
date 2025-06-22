import 'package:flutter/material.dart';
import 'approved_employee_detail.dart';

class ApprovedEmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employeeData;
  final String docId;

  const ApprovedEmployeeCard({
    super.key,
    required this.employeeData,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApprovedEmployeeDetail(
                employeeData: employeeData,
                docId: docId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "APPROVED",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Employee Name
              _buildInfoRow(
                Icons.person,
                Colors.blue,
                "Name: ",
                employeeData['fullName'] ?? 'N/A',
              ),
              const SizedBox(height: 12),
              
              // Employee Email
              _buildInfoRow(
                Icons.email,
                Colors.green,
                "Email: ",
                employeeData['email'] ?? 'N/A',
              ),
              const SizedBox(height: 12),
              
              // Employee ID
              _buildInfoRow(
                Icons.badge,
                Colors.orange,
                "ID: ",
                employeeData['employeeId'] ?? 'N/A',
              ),
              const SizedBox(height: 12),
              
              // Employee Designation
              _buildInfoRow(
                Icons.work,
                Colors.purple,
                "Designation: ",
                employeeData['designation'] ?? 'N/A',
              ),
              const SizedBox(height: 16),
              
              // Tap to view more indicator
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Tap to view details",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color iconColor, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}