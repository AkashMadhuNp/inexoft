import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PendingLeaveDetails extends StatefulWidget {
  const PendingLeaveDetails({super.key});

  @override
  State<PendingLeaveDetails> createState() => _PendingLeaveDetailsState();
}

class _PendingLeaveDetailsState extends State<PendingLeaveDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> pendingLeaves = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingLeaves();
  }

  Future<void> _fetchPendingLeaves() async {
    try {
      if (!mounted) return;

      setState(() {
        isLoading = true;
        pendingLeaves = [];
      });

      QuerySnapshot userDocsSnapshot = await _firestore.collection('leave_applications').get();

      if (userDocsSnapshot.docs.isEmpty) {
        print('No user documents found in leave_applications');
      }

      List<Map<String, dynamic>> allPendingLeaves = [];

      for (var userDoc in userDocsSnapshot.docs) {
        String userId = userDoc.id;
        print('Fetching pending leaves for user: $userId');

        QuerySnapshot pendingAppsSnapshot = await _firestore
            .collection('leave_applications')
            .doc(userId)
            .collection('applications')
            .where('status', isEqualTo: 'Pending')
            .orderBy('appliedAt', descending: true)
            .get();

        if (pendingAppsSnapshot.docs.isEmpty) {
          print('No pending leaves found for user: $userId');
          continue;
        }

        for (var appDoc in pendingAppsSnapshot.docs) {
          Map<String, dynamic> leaveData = appDoc.data() as Map<String, dynamic>;
          leaveData['docId'] = appDoc.id;
          leaveData['userId'] = userId;
          allPendingLeaves.add(leaveData);
        }
      }

      allPendingLeaves.sort((a, b) {
        Timestamp? aTime = a['appliedAt'] as Timestamp?;
        Timestamp? bTime = b['appliedAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;

      setState(() {
        pendingLeaves = allPendingLeaves;
        isLoading = false;
      });

      print('Fetched ${allPendingLeaves.length} pending leaves');
    } catch (e, stackTrace) {
      print('Error fetching pending leaves: $e\nStackTrace: $stackTrace');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load pending leaves: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
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

  Future<void> _handleLeaveAction(Map<String, dynamic> leave, String action, {String? rejectionReason}) async {
    try {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      String userId = leave['userId'];
      String docId = leave['docId'];
      String leaveId = leave['leaveId'] ?? docId;

      WriteBatch batch = _firestore.batch();
      Map<String, dynamic> processedLeaveData = Map<String, dynamic>.from(leave);
      processedLeaveData.remove('docId');
      processedLeaveData.remove('userId');

      if (action == 'Approved') {
        const int leaveQuota = 24;
        dynamic workingDaysValue = leave['numberOfWorkingDays'] ?? 0;
        int currentWorkingDays = 0;
        if (workingDaysValue is int) {
          currentWorkingDays = workingDaysValue;
        } else if (workingDaysValue is double) {
          currentWorkingDays = workingDaysValue.toInt();
        } else if (workingDaysValue is String) {
          currentWorkingDays = int.tryParse(workingDaysValue) ?? 0;
        }

        QuerySnapshot existingApproved = await _firestore
            .collection('leave_approved')
            .doc(userId)
            .collection('applications')
            .get();

        int totalPreviousWorkingDays = 0;
        for (var doc in existingApproved.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          dynamic workingDays = data['numberOfWorkingDays'] ?? 0;
          if (workingDays is int) {
            totalPreviousWorkingDays += workingDays;
          } else if (workingDays is double) {
            totalPreviousWorkingDays += workingDays.toInt();
          } else if (workingDays is String) {
            totalPreviousWorkingDays += int.tryParse(workingDays) ?? 0;
          }
        }

        int totalLeaveTaken = totalPreviousWorkingDays + currentWorkingDays;
        int leaveLeft = leaveQuota - totalLeaveTaken;

        DocumentReference approvedRef = _firestore
            .collection('leave_approved')
            .doc(userId)
            .collection('applications')
            .doc(leaveId);

        batch.set(approvedRef, {
          ...processedLeaveData,
          'status': 'Approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': 'Admin',
          'leaveQuota': leaveQuota,
          'numberOfLeaveTaken': totalLeaveTaken,
          'leaveLeft': leaveLeft,
          'currentApplicationWorkingDays': currentWorkingDays,
          'previousLeaveTaken': totalPreviousWorkingDays,
          'employeeId': leave['employeeId'] ?? '',
          'employeeName': leave['employeeName'] ?? '',
          'employeeEmail': leave['employeeEmail'] ?? '',
          'department': leave['department'] ?? '',
          'position': leave['position'] ?? '',
          'uid': leave['uid'] ?? userId,
        });

        DocumentReference userSummaryRef = _firestore.collection('leave_approved').doc(userId);
        batch.set(userSummaryRef, {
          'employeeId': leave['employeeId'] ?? '',
          'employeeName': leave['employeeName'] ?? '',
          'employeeEmail': leave['employeeEmail'] ?? '',
          'department': leave['department'] ?? '',
          'position': leave['position'] ?? '',
          'uid': leave['uid'] ?? userId,
          'leaveQuota': leaveQuota,
          'totalLeaveTaken': totalLeaveTaken,
          'leaveLeft': leaveLeft,
          'totalApplications': FieldValue.increment(1),
          'totalApproved': FieldValue.increment(1),
          'lastApprovedDate': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'firstApprovedDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (action == 'Rejected') {
        DocumentReference rejectedRef = _firestore
            .collection('leave_rejected')
            .doc(userId)
            .collection('applications')
            .doc(leaveId);

        batch.set(rejectedRef, {
          ...processedLeaveData,
          'status': 'Rejected',
          'rejectionReason': rejectionReason ?? 'No reason provided',
          'rejectedAt': FieldValue.serverTimestamp(),
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': 'Admin',
          'employeeId': leave['employeeId'] ?? '',
          'employeeName': leave['employeeName'] ?? '',
          'employeeEmail': leave['employeeEmail'] ?? '',
          'department': leave['department'] ?? '',
          'position': leave['position'] ?? '',
          'uid': leave['uid'] ?? userId,
        });

        DocumentReference rejectedSummaryRef = _firestore.collection('leave_rejected').doc(userId);
        batch.set(rejectedSummaryRef, {
          'employeeId': leave['employeeId'] ?? '',
          'employeeName': leave['employeeName'] ?? '',
          'employeeEmail': leave['employeeEmail'] ?? '',
          'department': leave['department'] ?? '',
          'position': leave['position'] ?? '',
          'uid': leave['uid'] ?? userId,
          'totalApplications': FieldValue.increment(1),
          'totalRejected': FieldValue.increment(1),
          'lastRejectedDate': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'firstRejectedDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      DocumentReference pendingRef = _firestore
          .collection('leave_applications')
          .doc(userId)
          .collection('applications')
          .doc(docId);
      batch.delete(pendingRef);

      DocumentReference leaveAppSummaryRef = _firestore.collection('leave_applications').doc(userId);
      batch.update(leaveAppSummaryRef, {
        'totalApplications': FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop();
        await _fetchPendingLeaves();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request ${action.toLowerCase()} successfully'),
            backgroundColor: action == 'Approved' ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error ${action.toLowerCase()}ing leave: $e\nStackTrace: $stackTrace');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${action.toLowerCase()} leave request: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showLeaveDetails(Map<String, dynamic> leave) {
    if (!mounted) return;

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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        (leave['employeeName'] ?? 'N').toString().substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.orange.shade800,
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
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Leave Information', [
                        _buildDetailItem('Leave ID', leave['leaveId'] ?? 'N/A'),
                        _buildDetailItem('Leave Type', leave['leaveType'] ?? 'N/A'),
                        _buildDetailItem('Total Days', '${leave['numberOfDays'] ?? 0} days'),
                        _buildDetailItem('Working Days', '${leave['numberOfWorkingDays'] ?? 0} days'),
                        _buildDetailItem('Start Date', _formatDate(leave['startDate'])),
                        _buildDetailItem('End Date', _formatDate(leave['endDate'])),
                      ]),
                      const SizedBox(height: 20),
                      _buildDetailSection('Application Details', [
                        _buildDetailItem('Applied On', _formatDateTime(leave['appliedAt'])),
                        _buildDetailItem('Status', (leave['status'] ?? 'pending').toString().toUpperCase()),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRejectionDialog(leave),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('Reject', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleLeaveAction(leave, 'Approved'),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Approve', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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

  void _showRejectionDialog(Map<String, dynamic> leave) {
    if (!mounted) return;

    final TextEditingController reasonController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide a reason for rejecting ${leave['employeeName']}\'s leave request:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason for rejection';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                _handleLeaveAction(leave, 'Rejected', rejectionReason: reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          const Text(': ', style: TextStyle(fontSize: 14, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
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
        title: const Text('Pending Leave Requests'),
        backgroundColor: Colors.orange.shade50,
        foregroundColor: Colors.orange.shade800,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchPendingLeaves,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _fetchPendingLeaves,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : pendingLeaves.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pending_actions,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending leave requests',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pending leaves will appear here',
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
                    itemCount: pendingLeaves.length,
                    itemBuilder: (context, index) {
                      final leave = pendingLeaves[index];
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
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      (leave['employeeName'] ?? 'N').toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.orange.shade800,
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
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PENDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(leave['appliedAt']),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectionDialog(leave),
                      icon: Icon(Icons.close, size: 16, color: Colors.red.shade700),
                      label: Text('Reject', style: TextStyle(color: Colors.red.shade700)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleLeaveAction(leave, 'Approved'),
                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                      label: const Text('Approve', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showLeaveDetails(leave),
                    icon: Icon(Icons.visibility, color: Colors.grey.shade600),
                    tooltip: 'View Details',
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
        Icon(icon, size: 16, color: Colors.orange.shade700),
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