import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeavewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Modified to accept specific employee ID
  Future<Map<String, dynamic>> fetchLeaveData({String? employeeId}) async {
    String? targetUserId = employeeId;
    
    // If no employeeId provided, use current user (original behavior)
    if (targetUserId == null) {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return _getDefaultLeaveData();
      }
      targetUserId = currentUser.uid;
    }

    try {
      final DocumentSnapshot docSnapshot = await _firestore
          .collection('leave_approved')
          .doc(targetUserId)
          .get();

      if (!docSnapshot.exists) {
        return _getDefaultLeaveData();
      }

      final data = docSnapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        return _getDefaultLeaveData();
      }

      final int totalQuota = data['leaveQuota'] ?? 0;
      final int leaveTaken = data['totalLeaveTaken'] ?? 0;
      final int leaveLeft = data['leaveLeft'] ?? (totalQuota - leaveTaken);

      return {
        'leaveQuota': totalQuota,
        'leaveTaken': leaveTaken,
        'leaveLeft': leaveLeft,
      };
    } catch (e) {
      print('Error fetching leave data: $e');
      return _getDefaultLeaveData();
    }
  }

  Map<String, dynamic> _getDefaultLeaveData() {
    return {
      'leaveQuota': 0,
      'leaveTaken': 0,
      'leaveLeft': 0,
    };
  }
}

class LeaveManagementCard extends StatefulWidget {
  final String? employeeId; // Add this parameter
  final Map<String, dynamic>? employeeData; // Optional employee data
  
  const LeaveManagementCard({
    super.key, 
    this.employeeId,
    this.employeeData,
  });

  @override
  State<LeaveManagementCard> createState() => _LeaveManagementCardState();
}

class _LeaveManagementCardState extends State<LeaveManagementCard> {
  final LeavewService _leaveService = LeavewService();
  Map<String, dynamic>? leaveData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeaveData();
  }

  Future<void> _fetchLeaveData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Use the provided employeeId or fall back to current user
      final data = await _leaveService.fetchLeaveData(
        employeeId: widget.employeeId,
      );
      
      setState(() {
        leaveData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load leave data';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        elevation: 4,
        child: Container(
          height: 200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Card(
        elevation: 4,
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _fetchLeaveData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final int leaveQuota = leaveData?['leaveQuota'] ?? 0;
    final int leaveTaken = leaveData?['leaveTaken'] ?? 0;
    final int remainingLeave = leaveData?['leaveLeft'] ?? 0;

    // Show message if no leave data found
    if (leaveQuota == 0 && leaveTaken == 0 && remainingLeave == 0) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    "Leave Management",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchLeaveData,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'No leave data found for this employee',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.employeeData?['fullName'] ?? 'Employee',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  "Leave Management",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchLeaveData,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildLeaveStatCard(
                    icon: Icons.event_note,
                    value: leaveQuota.toString(),
                    label: "Total Leave Quota",
                    color: Colors.blue.shade600,
                    backgroundColor: Colors.blue.shade50,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLeaveStatCard(
                    icon: Icons.event_busy,
                    value: leaveTaken.toString(),
                    label: "Leave Taken",
                    color: Colors.orange.shade600,
                    backgroundColor: Colors.orange.shade50,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Remaining Leave
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.event_available, color: Colors.green, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    remainingLeave.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    "Remaining Leave Days",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}