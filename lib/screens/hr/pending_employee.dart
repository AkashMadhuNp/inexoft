import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingEmployeeApproval extends StatefulWidget {
  const PendingEmployeeApproval({super.key});

  @override
  State<PendingEmployeeApproval> createState() => _PendingEmployeeApprovalState();
}

class _PendingEmployeeApprovalState extends State<PendingEmployeeApproval> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _rejectionReasonController = TextEditingController();

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _approveEmployee(Map<String, dynamic> employeeData, String docId) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Processing approval..."),
              ],
            ),
          );
        },
      );

      // Create approved employee data with updated status and leave fields
      Map<String, dynamic> approvedEmployeeData = Map.from(employeeData);
      approvedEmployeeData['status'] = 'Approved';
      approvedEmployeeData['approvedAt'] = FieldValue.serverTimestamp();
      approvedEmployeeData['processedAt'] = FieldValue.serverTimestamp();
      
      // Add leave management fields
      approvedEmployeeData['leaveQuota'] = 24;
      approvedEmployeeData['leaveTaken'] = 0;

      // Add to approved_employee collection
      await _firestore.collection('approved_employee').doc(docId).set(approvedEmployeeData);

      // Remove from employee_login collection
      await _firestore.collection('employee_login').doc(docId).delete();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog
      _showDialog(
        title: "Employee Approved",
        content: "${employeeData['fullName']} has been approved successfully with 24 leave quota.",
        isSuccess: true,
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      _showDialog(
        title: "Error",
        content: "Failed to approve employee. Please try again.",
        isSuccess: false,
      );
    }
  }

  Future<void> _rejectEmployee(Map<String, dynamic> employeeData, String docId) async {
    // Show rejection reason dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rejection Reason"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Please provide a reason for rejecting ${employeeData['fullName']}:"),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rejectionReasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter rejection reason...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _rejectionReasonController.clear();
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String reason = _rejectionReasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a rejection reason")),
                  );
                  return;
                }
                
                Navigator.of(context).pop(); // Close reason dialog
                await _processRejection(employeeData, docId, reason);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Reject", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRejection(Map<String, dynamic> employeeData, String docId, String reason) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Processing rejection..."),
              ],
            ),
          );
        },
      );

      // Create rejected employee data with updated status and reason
      Map<String, dynamic> rejectedEmployeeData = Map.from(employeeData);
      rejectedEmployeeData['status'] = 'Rejected';
      rejectedEmployeeData['rejectionReason'] = reason;
      rejectedEmployeeData['rejectedAt'] = FieldValue.serverTimestamp();
      rejectedEmployeeData['processedAt'] = FieldValue.serverTimestamp();

      // Add to rejected_employees collection
      await _firestore.collection('rejected_employees').doc(docId).set(rejectedEmployeeData);

      // Remove from employee_login collection
      await _firestore.collection('employee_login').doc(docId).delete();

      // Clear the text controller
      _rejectionReasonController.clear();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog
      _showDialog(
        title: "Employee Rejected",
        content: "${employeeData['fullName']} has been rejected.",
        isSuccess: true,
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      _showDialog(
        title: "Error",
        content: "Failed to reject employee. Please try again.",
        isSuccess: false,
      );
    }
  }

  void _showDialog({
    required String title,
    required String content,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employeeData, String docId) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Name
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  "Name: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    employeeData['fullName'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Employee Email
            Row(
              children: [
                const Icon(Icons.email, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  "Email: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    employeeData['email'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Employee ID
            Row(
              children: [
                const Icon(Icons.badge, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  "ID: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    employeeData['employeeId'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Employee Designation
            Row(
              children: [
                const Icon(Icons.work, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  "Designation: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    employeeData['designation'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Department
            Row(
              children: [
                const Icon(Icons.business, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  "Department: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    employeeData['department'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Status
            Row(
              children: [
                const Icon(Icons.info, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  "Status: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    employeeData['status'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _rejectEmployee(employeeData, docId),
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _approveEmployee(employeeData, docId),
                  icon: const Icon(Icons.check),
                  label: const Text("Approve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Employee Approvals"),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('employee_login')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pending employee approvals',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              Map<String, dynamic> employeeData = doc.data() as Map<String, dynamic>;
              
              return _buildEmployeeCard(employeeData, doc.id);
            },
          );
        },
      ),
    );
  }
}