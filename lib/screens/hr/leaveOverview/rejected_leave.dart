import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RejectLeaveDetails extends StatefulWidget {
  const RejectLeaveDetails({super.key});

  @override
  State<RejectLeaveDetails> createState() => _RejectLeaveDetailsState();
}

class _RejectLeaveDetailsState extends State<RejectLeaveDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> rejectedLeaves = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRejectedLeaves();
  }

  Future<void> _fetchRejectedLeaves() async {
    try {
      setState(() {
        isLoading = true;
      });

      List<Map<String, dynamic>> allRejectedLeaves = [];

      // Method 1: Try to get documents with ordering (if rejectedAt exists)
      try {
        QuerySnapshot rejectedSnapshot = await _firestore
            .collection('leave_rejected')
            .orderBy('rejectedAt', descending: true)
            .get();

        for (var doc in rejectedSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          allRejectedLeaves.add(data);
        }
      } catch (e) {
        print('Error with orderBy query, trying without ordering: $e');
        
        // Method 2: Get documents without ordering if orderBy fails
        QuerySnapshot rejectedSnapshot = await _firestore
            .collection('leave_rejected')
            .get();

        for (var doc in rejectedSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          allRejectedLeaves.add(data);
        }
        
        // Sort manually by rejectedAt if it exists, otherwise by document creation time
        allRejectedLeaves.sort((a, b) {
          Timestamp? timestampA = a['rejectedAt'] as Timestamp?;
          Timestamp timestampB = b['rejectedAt'] as Timestamp? ?? Timestamp.now();
          
          if (timestampA == null) return 1; // Put null values at the end
          return timestampB.compareTo(timestampA); // Descending order
        });
      }

      // Method 3: If still no data, try fetching from subcollections
      if (allRejectedLeaves.isEmpty) {
        print('No direct documents found, checking subcollections...');
        allRejectedLeaves = await _fetchFromSubcollections();
      }

      setState(() {
        rejectedLeaves = allRejectedLeaves;
        isLoading = false;
      });

      print('Total rejected leaves fetched: ${rejectedLeaves.length}');
      
    } catch (e) {
      print('Error fetching rejected leaves: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load rejected leaves: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to fetch from subcollections if main collection is empty
  Future<List<Map<String, dynamic>>> _fetchFromSubcollections() async {
    List<Map<String, dynamic>> subcollectionLeaves = [];
    
    try {
      // Get all user documents from leave_rejected collection
      QuerySnapshot usersSnapshot = await _firestore.collection('leave_rejected').get();
      
      for (var userDoc in usersSnapshot.docs) {
        // Get applications subcollection for each user
        QuerySnapshot applicationsSnapshot = await _firestore
            .collection('leave_rejected')
            .doc(userDoc.id)
            .collection('applications')
            .get();
        
        for (var appDoc in applicationsSnapshot.docs) {
          Map<String, dynamic> data = appDoc.data() as Map<String, dynamic>;
          data['docId'] = appDoc.id;
          data['userId'] = userDoc.id; // Add user ID for reference
          subcollectionLeaves.add(data);
        }
      }
      
      print('Fetched ${subcollectionLeaves.length} leaves from subcollections');
      
    } catch (e) {
      print('Error fetching from subcollections: $e');
    }
    
    return subcollectionLeaves;
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    try {
      if (dateValue is Timestamp) {
        return DateFormat('MMM dd, yyyy').format(dateValue.toDate());
      } else if (dateValue is String) {
        // Handle string dates if any
        DateTime? parsedDate = DateTime.tryParse(dateValue);
        if (parsedDate != null) {
          return DateFormat('MMM dd, yyyy').format(parsedDate);
        }
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    
    return 'N/A';
  }

  String _formatDateTime(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    try {
      if (dateValue is Timestamp) {
        return DateFormat('MMM dd, yyyy hh:mm a').format(dateValue.toDate());
      } else if (dateValue is String) {
        DateTime? parsedDate = DateTime.tryParse(dateValue);
        if (parsedDate != null) {
          return DateFormat('MMM dd, yyyy hh:mm a').format(parsedDate);
        }
      }
    } catch (e) {
      print('Error formatting datetime: $e');
    }
    
    return 'N/A';
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
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Text(
                        (leave['employeeName'] ?? leave['name'] ?? 'N').toString().substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.red.shade800,
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
                            leave['employeeName'] ?? leave['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${leave['employeeId'] ?? leave['id'] ?? 'N/A'} • ${leave['department'] ?? 'N/A'}',
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
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'REJECTED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
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
                      // Rejection Reason - Prominently displayed
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Rejection Reason',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Text(
                                leave['rejectionReason'] ?? leave['reason'] ?? 'No reason provided',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildDetailSection('Leave Information', [
                        _buildDetailItem('Leave Type', leave['leaveType'] ?? leave['type'] ?? 'N/A'),
                        _buildDetailItem('Total Days', '${leave['numberOfDays'] ?? leave['days'] ?? 0} days'),
                        _buildDetailItem('Working Days', '${leave['numberOfWorkingDays'] ?? leave['workingDays'] ?? 0} days'),
                        _buildDetailItem('Start Date', _formatDate(leave['startDate'] ?? leave['from'])),
                        _buildDetailItem('End Date', _formatDate(leave['endDate'] ?? leave['to'])),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      _buildDetailSection('Application Timeline', [
                        _buildDetailItem('Applied On', _formatDateTime(leave['appliedAt'] ?? leave['createdAt'])),
                        _buildDetailItem('Rejected On', _formatDateTime(leave['rejectedAt'])),
                      ]),
                      
                      if ((leave['reason'] != null && leave['reason'].toString().isNotEmpty) ||
                          (leave['description'] != null && leave['description'].toString().isNotEmpty)) ...[
                        const SizedBox(height: 20),
                        _buildDetailSection('Employee\'s Request Details', [
                          if (leave['reason'] != null && leave['reason'].toString().isNotEmpty)
                            _buildDetailItem('Employee\'s Reason', leave['reason']),
                          if (leave['description'] != null && leave['description'].toString().isNotEmpty)
                            _buildDetailItem('Description', leave['description']),
                        ]),
                      ],
                      
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
        title: const Text('Rejected Leave Requests'),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade800,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchRejectedLeaves,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _fetchRejectedLeaves,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : rejectedLeaves.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No rejected leave requests',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rejected leaves will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchRejectedLeaves,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rejectedLeaves.length,
                    itemBuilder: (context, index) {
                      final leave = rejectedLeaves[index];
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
                    backgroundColor: Colors.red.shade100,
                    child: Text(
                      (leave['employeeName'] ?? leave['name'] ?? 'N').toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.red.shade800,
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
                          leave['employeeName'] ?? leave['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${leave['employeeId'] ?? leave['id'] ?? 'N/A'} • ${leave['department'] ?? 'N/A'}',
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
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'REJECTED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(leave['rejectedAt'] ?? leave['createdAt']),
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'Leave Type',
                            leave['leaveType'] ?? leave['type'] ?? 'N/A',
                            Icons.event_note,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'Duration',
                            '${leave['numberOfDays'] ?? leave['days'] ?? 0} days',
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
                            _formatDate(leave['startDate'] ?? leave['from']),
                            Icons.calendar_today,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'To',
                            _formatDate(leave['endDate'] ?? leave['to']),
                            Icons.event,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Rejection reason preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.shade400,
                    width: 4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rejection Reason:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      leave['rejectionReason'] ?? leave['reason'] ?? 'No reason provided',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    'Tap to view full details',
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
          color: Colors.red.shade700,
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