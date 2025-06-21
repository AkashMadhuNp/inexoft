import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inexo/screens/hr/leaveOverview/approved_leave.dart';
import 'package:inexo/screens/hr/leaveOverview/pending_leave_details.dart';
import 'package:inexo/screens/hr/leaveOverview/rejected_leave.dart';
import 'package:inexo/screens/hr/leave_pending_detail.dart';

class LeaveRequestOverview extends StatefulWidget {
  const LeaveRequestOverview({super.key});

  @override
  State<LeaveRequestOverview> createState() => _LeaveRequestOverviewState();
}

class _LeaveRequestOverviewState extends State<LeaveRequestOverview> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Initialize counts to zero
  Map<String, int> leaveStats = {
    'Pending': 0,
    'Approved': 0,
    'Rejected': 0,
  };
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaveCounts();
  }

  // Fetch counts from all three collections by summing total_applications
  Future<void> _fetchLeaveCounts() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Method 1: Try to get totalApplications from user summary documents
      final results = await Future.wait([
        _firestore.collection('leave_applications').get(),
        _firestore.collection('leave_approved').get(),
        _firestore.collection('leave_rejected').get(),
      ]);

      // Calculate total counts by summing totalApplications from all users
      int pendingCount = _calculateTotalApplications(results[0]);
      int approvedCount = _calculateTotalApplications(results[1]);
      int rejectedCount = _calculateTotalApplications(results[2]);

      // Method 2: If Method 1 gives zero, try counting from subcollections
      if (pendingCount == 0) {
        pendingCount = await _countFromSubcollections('leave_applications');
      }
      if (approvedCount == 0) {
        approvedCount = await _countFromSubcollections('leave_approved');
      }
      if (rejectedCount == 0) {
        rejectedCount = await _countFromSubcollections('rejected_leav');
      }

      // Update the counts
      setState(() {
        leaveStats = {
          'Pending': pendingCount,
          'Approved': approvedCount,
          'Rejected': rejectedCount,
        };
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching leave counts: $e');
      // Keep the initial zero values if there's an error
      setState(() {
        isLoading = false;
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load leave statistics'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Alternative method: Count actual documents in subcollections
  Future<int> _countFromSubcollections(String collectionName) async {
    int totalCount = 0;
    
    try {
      // Get all user documents
      QuerySnapshot usersSnapshot = await _firestore.collection(collectionName).get();
      
      // For each user, count their applications
      for (var userDoc in usersSnapshot.docs) {
        QuerySnapshot applicationsSnapshot = await _firestore
            .collection(collectionName)
            .doc(userDoc.id)
            .collection('applications')
            .get();
        
        totalCount += applicationsSnapshot.docs.length;
      }
      
      print('$collectionName subcollection count: $totalCount');
    } catch (e) {
      print('Error counting from subcollections in $collectionName: $e');
    }
    
    return totalCount;
  }

  // Helper method to calculate total applications from all users in a collection
  int _calculateTotalApplications(QuerySnapshot snapshot) {
    int totalCount = 0;
    
    for (var doc in snapshot.docs) {
      try {
        // Get the data as Map
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Check if totalApplications field exists and add it to the count
        // Note: Based on your code, it's 'totalApplications' not 'total_applications'
        if (data.containsKey('totalApplications')) {
          var totalApps = data['totalApplications'];
          
          // Handle both int and string types
          if (totalApps is int) {
            totalCount += totalApps;
          } else if (totalApps is String) {
            totalCount += int.tryParse(totalApps) ?? 0;
          }
        }
        
        // Debug print to see what's in each document
        print('Document ${doc.id}: ${data.keys.toList()}');
        print('totalApplications value: ${data['totalApplications']}');
        
      } catch (e) {
        print('Error processing document ${doc.id}: $e');
        // Continue processing other documents even if one fails
      }
    }
    
    print('Total count calculated: $totalCount');
    return totalCount;
  }

  // Method to refresh the counts
  Future<void> _refreshCounts() async {
    await _fetchLeaveCounts();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshCounts,
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          _buildStatCard(
            context: context,
            title: 'Pending',
            count: leaveStats['Pending']!,
            icon: Icons.hourglass_empty,
            color: Colors.orange,
            onTap: () =>Navigator.of(context).push(MaterialPageRoute(builder: (context) => PendingLeaveDetails(),)),
            isLoading: isLoading,
          ),
          _buildStatCard(
            context: context,
            title: 'Approved',
            count: leaveStats['Approved']!,
            icon: Icons.check_circle,
            color: Colors.green,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ApprovedLeaveDetail(),)),
            isLoading: isLoading,
          ),
          _buildStatCard(
            context: context,
            title: 'Rejected',
            count: leaveStats['Rejected']!,
            icon: Icons.cancel,
            color: Colors.red,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => RejectLeaveDetails(),)),
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 4),
              isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  
}