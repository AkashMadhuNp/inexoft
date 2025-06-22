import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> fetchLeaveStats() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final DocumentSnapshot docSnapshot = await _firestore
          .collection('leave_approved')
          .doc(currentUser.uid)
          .get();

      if (!docSnapshot.exists) return [];

      final data = docSnapshot.data() as Map<String, dynamic>?;
      if (data == null) return [];

      final int totalQuota = data['leaveQuota'] ?? 0;
      final int leaveTaken = data['totalLeaveTaken'] ?? 0;
      final int leaveLeft = data['leaveLeft'] ?? (totalQuota - leaveTaken);

      return [
        {
          'title': 'Leave Quota',
          'value': totalQuota.toString(),
          'color': const Color(0xFFFF9800),
          'icon': Icons.calendar_month,
          'gradient': [const Color(0xFFFF9800), const Color(0xFFF57C00)]
        },
        {
          'title': 'Total Leave Taken',
          'value': leaveTaken.toString(),
          'color': const Color(0xFF2196F3),
          'icon': Icons.event_busy,
          'gradient': [const Color(0xFF2196F3), const Color(0xFF1976D2)]
        },
        {
          'title': 'Total Leaves Left',
          'value': leaveLeft.toString(),
          'color': const Color(0xFF4CAF50),
          'icon': Icons.event_available,
          'gradient': [const Color(0xFF4CAF50), const Color(0xFF388E3C)]
        },
      ];
    } catch (e) {
      return [];
    }
  }
}