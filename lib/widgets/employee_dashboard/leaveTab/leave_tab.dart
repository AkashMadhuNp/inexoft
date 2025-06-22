import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inexo/services/leave_count_fetching_service.dart';
import 'package:inexo/widgets/employee_dashboard/leaveTab/employee_info_card.dart';
import 'package:inexo/widgets/employee_dashboard/leaveTab/leave_application_sheet.dart';
import 'package:inexo/widgets/employee_dashboard/leaveTab/leave_stats_carousel.dart';

class LeaveTab extends StatefulWidget {
  final Map<String, dynamic>? employeeData;
  const LeaveTab({super.key, this.employeeData});

  @override
  State<LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<LeaveTab> with SingleTickerProviderStateMixin {
  final _leaveFormKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _workingDaysController = TextEditingController();
  
  String? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LeaveService _leaveService = LeaveService();

  Map<String, dynamic>? _currentEmployeeData;
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;

  final List<String> leaveTypes = [
    'Sick Leave',
    'Casual Leave',
    'Annual Leave',
    'Maternity Leave',
    'Emergency Leave',
    'Personal Leave'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchEmployeeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _workingDaysController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployeeData() async {
    try {
      setState(() => _isLoading = true);

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection('approved_employee')
          .where('uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _currentEmployeeData = querySnapshot.docs.first.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Employee data not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching employee data';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? get employeeData => _currentEmployeeData ?? widget.employeeData;

  int _calculateWorkingDays(DateTime start, DateTime end) {
    int workingDays = 0;
    DateTime current = start;
    while (!current.isAfter(end)) {
      if (current.weekday != DateTime.sunday) workingDays++;
      current = current.add(Duration(days: 1));
    }
    return workingDays;
  }

  Stream<QuerySnapshot> getLeaveHistoryStreamByStatus(String status) {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();
    
    final collectionPath = status == 'Pending' ? 'leave_applications' : 
                         status == 'Approved' ? 'leave_approved' : 'leave_rejected';
    
    return _firestore
        .collection(collectionPath)
        .doc(currentUser.uid)
        .collection('applications')
        .where('status', isEqualTo: status)
        .orderBy('appliedAt', descending: true)
        .snapshots();
  }

  Widget _buildLeaveHistoryTab(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: getLeaveHistoryStreamByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading leave history', style: GoogleFonts.inter(fontSize: 16, color: Colors.red)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final leaves = snapshot.data?.docs ?? [];
        if (leaves.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getStatusIcon(status), size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No ${status.toLowerCase()} leaves found', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index].data() as Map<String, dynamic>;
              leave['status'] = status; // Set status for approved/rejected collections
              return _buildLeaveCard(leave, leaves[index].id);
            },
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    return {
      'Pending': Icons.pending,
      'Approved': Icons.check_circle,
      'Rejected': Icons.cancel,
    }[status] ?? Icons.history;
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave, String documentId) {
    final startDate = (leave['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final endDate = (leave['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final appliedAt = (leave['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final statusDetails = {
      'Pending': {'color': Colors.orange, 'icon': Icons.pending},
      'Approved': {'color': Colors.green, 'icon': Icons.check_circle},
      'Rejected': {'color': Colors.red, 'icon': Icons.cancel},
    }[leave['status']] ?? {'color': Colors.grey, 'icon': Icons.help};

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showLeaveDetails(leave, documentId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (statusDetails['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (statusDetails['color'] as Color).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusDetails['icon'] as IconData, size: 16, color: statusDetails['color'] as Color),
                    const SizedBox(width: 4),
                    Text(
                      leave['status'] ?? 'Unknown',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: statusDetails['color'] as Color),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                leave['leaveType'] ?? 'Unknown',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF718096)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF718096)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Color(0xFF718096)),
                  const SizedBox(width: 8),
                  Text(
                    '${leave['numberOfWorkingDays'] ?? 0} working days',
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF718096)),
                  ),
                ],
              ),
              if (leave['reason']?.toString().isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Text('Reason:', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF2D3748))),
                const SizedBox(height: 4),
                Text(
                  leave['reason'].toString().length > 100 ? '${leave['reason'].toString().substring(0, 100)}...' : leave['reason'].toString(),
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4A5568)),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Applied: ${appliedAt.day}/${appliedAt.month}/${appliedAt.year}',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                  ),
                  Row(
                    children: [
                      if (leave['leaveId'] != null)
                        Text('ID: ${leave['leaveId']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0))),
                      if (leave['leaveId'] != null) const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFA0AEC0)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveDetails(Map<String, dynamic> leave, String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(leave['leaveType'] ?? 'Leave Details', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', leave['status'] ?? 'Unknown'),
              _buildDetailRow('Leave ID', leave['leaveId'] ?? documentId),
              _buildDetailRow('Employee ID', leave['employeeId'] ?? 'N/A'),
              _buildDetailRow('Start Date', leave['startDate'] != null 
                  ? '${(leave['startDate'] as Timestamp).toDate().day}/${(leave['startDate'] as Timestamp).toDate().month}/${(leave['startDate'] as Timestamp).toDate().year}'
                  : 'N/A'),
              _buildDetailRow('End Date', leave['endDate'] != null 
                  ? '${(leave['endDate'] as Timestamp).toDate().day}/${(leave['endDate'] as Timestamp).toDate().month}/${(leave['endDate'] as Timestamp).toDate().year}'
                  : 'N/A'),
              _buildDetailRow('Working Days', '${leave['numberOfWorkingDays'] ?? 0}'),
              if (leave['reason']?.toString().isNotEmpty ?? false)
                _buildDetailRow('Reason', leave['reason'].toString()),
              if (leave['description']?.toString().isNotEmpty ?? false)
                _buildDetailRow('Description', leave['description'].toString()),
              _buildDetailRow('Applied Date', leave['appliedAt'] != null 
                  ? '${(leave['appliedAt'] as Timestamp).toDate().day}/${(leave['appliedAt'] as Timestamp).toDate().month}/${(leave['appliedAt'] as Timestamp).toDate().year}'
                  : 'N/A'),
              if (leave['status'] == 'Approved' || leave['status'] == 'Rejected') ...[
                if (leave['processedAt'] != null)
                  _buildDetailRow('Processed Date', 
                      '${(leave['processedAt'] as Timestamp).toDate().day}/${(leave['processedAt'] as Timestamp).toDate().month}/${(leave['processedAt'] as Timestamp).toDate().year}'),
                if (leave['processedBy'] != null)
                  _buildDetailRow('Processed By', leave['processedBy'].toString()),
                if (leave['adminComments']?.toString().isNotEmpty ?? false)
                  _buildDetailRow('Admin Comments', leave['adminComments'].toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1976D2)),
              const SizedBox(height: 16),
              Text('Loading employee data...', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF4A5568))),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: GoogleFonts.inter(fontSize: 16, color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchEmployeeData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmployeeInfoCard(employeeData: employeeData),
                const SizedBox(height: 24),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _leaveService.fetchLeaveStats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: size.height * 0.20 + 20,
                        child: const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2))),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return SizedBox(
                        height: size.height * 0.20 + 20,
                        child: Center(
                          child: Text(
                            'No leave statistics available',
                            style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF4A5568)),
                          ),
                        ),
                      );
                    }
                    return LeaveStatsCarousel(leaveStats: snapshot.data!, size: size);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), spreadRadius: 1, blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1976D2),
              unselectedLabelColor: const Color(0xFF718096),
              indicatorColor: const Color(0xFF1976D2),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(icon: Icon(Icons.pending), text: 'Pending'),
                Tab(icon: Icon(Icons.check_circle), text: 'Approved'),
                Tab(icon: Icon(Icons.cancel), text: 'Rejected'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaveHistoryTab('Pending'),
                _buildLeaveHistoryTab('Approved'),
                _buildLeaveHistoryTab('Rejected'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: employeeData?['permissions']?['canApplyLeave'] == true
          ? FloatingActionButton(
              onPressed: () => LeaveApplicationSheet.show(
                workingDaysController: _workingDaysController,
                context: context,
                leaveFormKey: _leaveFormKey,
                leaveTypes: leaveTypes,
                selectedLeaveType: _selectedLeaveType,
                reasonController: _reasonController,
                descriptionController: _descriptionController,
                startDateController: _startDateController,
                endDateController: _endDateController,
                startDate: _startDate,
                endDate: _endDate,
                onLeaveTypeChanged: (value) => setState(() => _selectedLeaveType = value),
                onDateSelected: (date, isStartDate) {
                  setState(() {
                    if (isStartDate) {
                      _startDate = date;
                      _startDateController.text = "${date.day}/${date.month}/${date.year}";
                      if (_endDate != null && _endDate!.isBefore(date)) {
                        _endDate = null;
                        _endDateController.clear();
                        _workingDaysController.clear();
                      }
                    } else {
                      if (_startDate != null && date.isBefore(_startDate!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('End date cannot be before start date'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      _endDate = date;
                      _endDateController.text = "${date.day}/${date.month}/${date.year}";
                    }
                    if (_startDate != null && _endDate != null) {
                      final workingDays = _calculateWorkingDays(_startDate!, _endDate!);
                      _workingDaysController.text = workingDays.toString();
                    }
                  });
                },
                onSubmit: _submitLeaveApplication,
              ),
              backgroundColor: const Color(0xFF1976D2),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _submitLeaveApplication() async {
    if (!_leaveFormKey.currentState!.validate()) return;

    final data = employeeData;
    final User? currentUser = _auth.currentUser;
    
    if (data == null || currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee data or authentication not available'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final workingDays = int.parse(_workingDaysController.text);
      
      final leaveId = _firestore
          .collection('leave_applications')
          .doc(currentUser.uid)
          .collection('applications')
          .doc()
          .id;
      
      final applicationData = {
        'leaveId': leaveId,
        'employeeId': data['employeeId'],
        'employeeName': data['fullName'],
        'employeeEmail': data['email'],
        'department': data['department'] ?? '',
        'position': data['position'] ?? '',
        'leaveType': _selectedLeaveType,
        'reason': _reasonController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'numberOfDays': _endDate!.difference(_startDate!).inDays + 1,
        'numberOfWorkingDays': workingDays,
        'status': 'Pending',
        'appliedAt': FieldValue.serverTimestamp(),
        'uid': currentUser.uid,
      };

      final batch = _firestore.batch();
      final leaveAppRef = _firestore
          .collection('leave_applications')
          .doc(currentUser.uid)
          .collection('applications')
          .doc(leaveId);
      
      batch.set(leaveAppRef, applicationData);

      final summaryRef = _firestore
          .collection('leave_applications')
          .doc(currentUser.uid);
      
      batch.set(summaryRef, {
        'employeeId': data['employeeId'],
        'employeeName': data['fullName'],
        'employeeEmail': data['email'],
        'department': data['department'] ?? '',
        'position': data['position'] ?? '',
        'uid': currentUser.uid,
        'totalApplications': FieldValue.increment(1),
        'lastApplicationDate': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave application submitted successfully!\nLeave ID: $leaveId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context);
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting application'), backgroundColor: Colors.red),
      );
    }
  }

  void _resetForm() {
    _reasonController.clear();
    _descriptionController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _workingDaysController.clear();
    setState(() {
      _selectedLeaveType = null;
      _startDate = null;
      _endDate = null;
    });
  }
}