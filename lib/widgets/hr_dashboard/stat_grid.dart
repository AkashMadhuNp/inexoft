import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inexo/screens/hr/approved_employee.dart';
import 'package:inexo/screens/hr/hr_details.dart';
import 'package:inexo/screens/hr/pending_employee.dart';
import 'package:inexo/screens/hr/rejected_employee.dart';
import 'stat_card.dart';

class StatisticsGrid extends StatelessWidget {
  final Stream<QuerySnapshot> approvedEmployeeStream;
  final Stream<QuerySnapshot> employeeLoginStream; // for pending approvals
  final Stream<QuerySnapshot> rejectedEmployeesStream;
  final Stream<QuerySnapshot> hrLoginStream;

  const StatisticsGrid({
    Key? key,
    required this.approvedEmployeeStream,
    required this.employeeLoginStream,
    required this.rejectedEmployeesStream,
    required this.hrLoginStream,
  }) : super(key: key);

  // Navigation handlers for each card
  void _navigateToEmployeesList(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ApprovedEmployee()));
  }

  void _navigateToPendingApprovals(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => PendingEmployeeApproval()));
  }

  void _navigateToRejectedEmployees(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => RejectedEmployee()));
  }

  void _navigateToHRStaff(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => HRData()));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: approvedEmployeeStream,
      builder: (context, approvedSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: employeeLoginStream,
          builder: (context, employeeLoginSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: rejectedEmployeesStream,
              builder: (context, rejectedSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: hrLoginStream,
                  builder: (context, hrSnapshot) {
                    int totalEmployees = 0;
                    int pendingEmployees = 0;
                    int rejectedEmployees = 0;
                    int totalHR = 0;

                    // Calculate approved employees count
                    if (approvedSnapshot.hasData) {
                      totalEmployees = approvedSnapshot.data!.docs.length;
                    }

                    // Calculate pending employees count from employee_login collection
                    if (employeeLoginSnapshot.hasData) {
                      // If all employees in employee_login are pending, use total count
                      pendingEmployees = employeeLoginSnapshot.data!.docs.length;
                      
                      // If you need to filter by status in employee_login collection:
                      /*
                      for (var doc in employeeLoginSnapshot.data!.docs) {
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        String status = data['status'] ?? '';
                        
                        if (status.toLowerCase() == 'pending') {
                          pendingEmployees++;
                        }
                      }
                      */
                    }

                    // Calculate rejected employees count
                    if (rejectedSnapshot.hasData) {
                      rejectedEmployees = rejectedSnapshot.data!.docs.length;
                    }

                    // Calculate HR count
                    if (hrSnapshot.hasData) {
                      totalHR = hrSnapshot.data!.docs.length;
                    }

                    List<Map<String, dynamic>> stats = [
                      {
                        'title': 'Total Employees',
                        'value': totalEmployees.toString(),
                        'icon': Icons.people,
                        'color': const Color(0xFF4CAF50),
                        'gradient': [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
                        'onTap': () => _navigateToEmployeesList(context),
                      },
                      {
                        'title': 'Pending Approvals',
                        'value': pendingEmployees.toString(),
                        'icon': Icons.hourglass_empty,
                        'color': const Color(0xFFFF9800),
                        'gradient': [const Color(0xFFFF9800), const Color(0xFFF57C00)],
                        'onTap': () => _navigateToPendingApprovals(context),
                      },
                      {
                        'title': 'Rejected Employees',
                        'value': rejectedEmployees.toString(),
                        'icon': Icons.cancel,
                        'color': const Color(0xFFF44336),
                        'gradient': [const Color(0xFFF44336), const Color(0xFFD32F2F)],
                        'onTap': () => _navigateToRejectedEmployees(context),
                      },
                      {
                        'title': 'HR Staff',
                        'value': totalHR.toString(),
                        'icon': Icons.admin_panel_settings,
                        'color': const Color(0xFF9C27B0),
                        'gradient': [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                        'onTap': () => _navigateToHRStaff(context),
                      },
                    ];

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        final stat = stats[index];
                        return StatCard(
                          title: stat['title'],
                          value: stat['value'],
                          icon: stat['icon'],
                          color: stat['color'],
                          gradient: stat['gradient'],
                          onTap: stat['onTap'],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}