import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inexo/screens/login_screen.dart';
import 'package:inexo/services/auth_service.dart';

class RejectedStatusScreen extends StatefulWidget {
  final User user;

  const RejectedStatusScreen({super.key, required this.user});

  @override
  State<RejectedStatusScreen> createState() => _RejectedStatusScreenState();
}

class _RejectedStatusScreenState extends State<RejectedStatusScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('rejected_employees')
          .doc(widget.user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userDetails = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading user details: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Status'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusIcon(screenWidth),
                      SizedBox(height: screenHeight * 0.01),
                      _buildStatusTitle(screenWidth),
                      SizedBox(height: screenHeight * 0.01),
                      _buildStatusMessage(screenWidth),
                      SizedBox(height: screenHeight * 0.03),
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.red)
                          : _buildUserDetails(screenWidth, screenHeight),
                      SizedBox(height: screenHeight * 0.04),
                      SizedBox(height: screenHeight * 0.02),
                      _buildHelpText(screenWidth),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(double screenWidth) {
    return Container(
      width: screenWidth * 0.2,
      height: screenWidth * 0.2,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.cancel_outlined,
        size: screenWidth * 0.1,
        color: Colors.red,
      ),
    );
  }

  Widget _buildStatusTitle(double screenWidth) {
    return Text(
      'Application Rejected',
      style: TextStyle(
        fontSize: screenWidth * 0.06,
        fontWeight: FontWeight.bold,
        color: Colors.red[800],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatusMessage(double screenWidth) {
    return Text(
      'Unfortunately, your application has been rejected. Please see the details below ',
      style: TextStyle(
        fontSize: screenWidth * 0.04,
        color: Colors.grey[600],
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUserDetails(double screenWidth, double screenHeight) {
    if (userDetails == null) return const SizedBox();

    return Column(
      children: [
        _buildDetailCard(screenWidth, screenHeight),
        SizedBox(height: screenHeight * 0.03),
        _buildRejectionReason(screenWidth),
      ],
    );
  }

  Widget _buildDetailCard(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Details',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildDetailRow('Full Name', userDetails!['fullName'] ?? 'N/A', screenWidth),
          _buildDetailRow('Email', userDetails!['email'] ?? 'N/A', screenWidth),
          _buildDetailRow('Designation', userDetails!['designation'] ?? 'N/A', screenWidth),
          _buildDetailRow('Status', userDetails!['status'] ?? 'Rejected', screenWidth),
          if (userDetails!['rejectedAt'] != null)
            _buildDetailRow('Rejected On', _formatDate(userDetails!['rejectedAt']), screenWidth),
          if (userDetails!['createdAt'] != null)
            _buildDetailRow('Applied On', _formatDate(userDetails!['createdAt']), screenWidth),
        ],
      ),
    );
  }

  Widget _buildRejectionReason(double screenWidth) {
    final reason = userDetails!['rejectionReason'];
    if (reason != null && reason.toString().isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red[600], size: screenWidth * 0.05),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Rejection Reason',
                  style: TextStyle(
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              reason.toString(),
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.red[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.red[600], size: screenWidth * 0.05),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Text(
                'No specific reason provided. Please contact HR for more details.',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.25,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _buildHelpText(double screenWidth) {
    return Text(
      'You can reapply in the future if circumstances change.',
      style: TextStyle(
        fontSize: screenWidth * 0.035,
        color: Colors.grey[500],
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime date = timestamp is Timestamp ? timestamp.toDate() : DateTime.tryParse(timestamp.toString())!;
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  
}