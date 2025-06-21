import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ApprovedLeaveDetail extends StatefulWidget {
  const ApprovedLeaveDetail({super.key});

  @override
  State<ApprovedLeaveDetail> createState() => _ApprovedLeaveDetailState();
}

class _ApprovedLeaveDetailState extends State<ApprovedLeaveDetail> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> approvedLeaves = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApprovedLeaves();
  }

  Future<void> _fetchApprovedLeaves() async {
  try {
    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> allApprovedLeaves = [];

    // First, let's see what documents exist in the collection
    QuerySnapshot allDocsSnapshot = await _firestore
        .collection('leave_approved')
        .get();

    print('Total documents in leave_approved: ${allDocsSnapshot.docs.length}');

    for (var doc in allDocsSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      print('Document ${doc.id} fields: ${data.keys.toList()}');
      print('Document ${doc.id} data sample: $data');
    }

    // Try without orderBy first to see if that's causing issues
    QuerySnapshot approvedSnapshot = await _firestore
        .collection('leave_approved')
        .get(); // Remove orderBy temporarily

    print('Query returned ${approvedSnapshot.docs.length} documents');

    for (var doc in approvedSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['docId'] = doc.id;
      
      // Check if this looks like a leave application or a user summary
      if (data.containsKey('employeeName') || data.containsKey('leaveType')) {
        // This looks like a leave application
        allApprovedLeaves.add(data);
        print('Added leave application: ${data['employeeName']} - ${data['leaveType']}');
      } else if (data.containsKey('totalApplications')) {
        // This looks like a user summary, need to check subcollection
        print('Found user summary for ${doc.id}, checking subcollection...');
        
        QuerySnapshot subcollectionSnapshot = await _firestore
            .collection('leave_approved')
            .doc(doc.id)
            .collection('applications')
            .get();
            
        print('Subcollection has ${subcollectionSnapshot.docs.length} documents');
        
        for (var subDoc in subcollectionSnapshot.docs) {
          Map<String, dynamic> subData = subDoc.data() as Map<String, dynamic>;
          subData['docId'] = subDoc.id;
          subData['userId'] = doc.id;
          allApprovedLeaves.add(subData);
          print('Added from subcollection: ${subData['employeeName']} - ${subData['leaveType']}');
        }
      }
    }

    // Sort by timestamp
    allApprovedLeaves.sort((a, b) {
      Timestamp? aTime = a['approvedAt'] ?? a['appliedAt'];
      Timestamp? bTime = b['approvedAt'] ?? b['appliedAt'];
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return bTime.compareTo(aTime);
    });

    print('Final approved leaves count: ${allApprovedLeaves.length}');

    setState(() {
      approvedLeaves = allApprovedLeaves;
      isLoading = false;
    });
  } catch (e) {
    print('Error fetching approved leaves: $e');
    setState(() {
      isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load approved leaves'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM dd, yyyy hh:mm a').format(timestamp.toDate());
  }

  void _showLeaveDetails(Map<String, dynamic> leave) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        (leave['employeeName'] ?? 'N').toString().substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave['employeeName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${leave['employeeId'] ?? 'N/A'} • ${leave['department'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'APPROVED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Leave Information', [
                        _buildDetailItem('Leave Type', leave['leaveType'] ?? 'N/A'),
                        _buildDetailItem('Total Days', '${leave['numberOfDays'] ?? 0} days'),
                        _buildDetailItem('Working Days', '${leave['numberOfWorkingDays'] ?? 0} days'),
                        _buildDetailItem('Start Date', _formatDate(leave['startDate'])),
                        _buildDetailItem('End Date', _formatDate(leave['endDate'])),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      _buildDetailSection('Application Details', [
                        _buildDetailItem('Applied On', _formatDateTime(leave['appliedAt'])),
                        _buildDetailItem('Approved On', _formatDateTime(leave['approvedAt'])),
                        if (leave['reason'] != null && leave['reason'].toString().isNotEmpty)
                          _buildDetailItem('Reason', leave['reason']),
                        if (leave['description'] != null && leave['description'].toString().isNotEmpty)
                          _buildDetailItem('Description', leave['description']),
                      ]),
                      
                      if (leave['contactDuringLeave'] != null || leave['emergencyContact'] != null) ...[
                        const SizedBox(height: 20),
                        _buildDetailSection('Contact Information', [
                          if (leave['contactDuringLeave'] != null)
                            _buildDetailItem('Contact During Leave', leave['contactDuringLeave']),
                          if (leave['emergencyContact'] != null)
                            _buildDetailItem('Emergency Contact', leave['emergencyContact']),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Leave Requests'),
        backgroundColor: Colors.green.shade50,
        foregroundColor: Colors.green.shade800,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchApprovedLeaves,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _fetchApprovedLeaves,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : approvedLeaves.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No approved leave requests',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Approved leaves will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: approvedLeaves.length,
                    itemBuilder: (context, index) {
                      final leave = approvedLeaves[index];
                      return _buildLeaveCard(leave);
                    },
                  ),
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showLeaveDetails(leave),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with employee info
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      (leave['employeeName'] ?? 'N').toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave['employeeName'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${leave['employeeId'] ?? 'N/A'} • ${leave['department'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'APPROVED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(leave['approvedAt']),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Leave summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'Leave Type',
                            leave['leaveType'] ?? 'N/A',
                            Icons.event_note,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'Duration',
                            '${leave['numberOfDays'] ?? 0} days',
                            Icons.access_time,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'From',
                            _formatDate(leave['startDate']),
                            Icons.calendar_today,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'To',
                            _formatDate(leave['endDate']),
                            Icons.event,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Tap to view details
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.green.shade700,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension StringCapitalization on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}