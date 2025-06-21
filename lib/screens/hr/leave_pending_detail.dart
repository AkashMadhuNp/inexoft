import 'package:flutter/material.dart';

class LeaveDetailsPage extends StatelessWidget {
  final String leaveType;

  const LeaveDetailsPage({super.key, required this.leaveType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$leaveType Leave Requests'),
        backgroundColor: _getAppBarColor(leaveType),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForLeaveType(leaveType),
              size: 80,
              color: _getColorForLeaveType(leaveType),
            ),
            SizedBox(height: 16),
            Text(
              '$leaveType Leave Requests',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Here you can view all $leaveType leave requests',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAppBarColor(String leaveType) {
    switch (leaveType) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconForLeaveType(String leaveType) {
    switch (leaveType) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Approved':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.event_note;
    }
  }

  Color _getColorForLeaveType(String leaveType) {
    switch (leaveType) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
