import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaveCard extends StatelessWidget {
  final Map<String, dynamic> leave;

  const LeaveCard({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
    final startDate = (leave['startDate'] as Timestamp).toDate();
    final endDate = (leave['endDate'] as Timestamp).toDate();
    final appliedAt = leave['appliedAt'] != null
        ? (leave['appliedAt'] as Timestamp).toDate()
        : DateTime.now();

    Color statusColor;
    IconData statusIcon;

    switch (leave['status']) {
      case 'Pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'Approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status at the top
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    leave['status'] ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Leave Type
            Text(
              leave['leaveType'] ?? 'Unknown',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 12),
            // Start and End Date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF718096),
                ),
                const SizedBox(width: 8),
                Text(
                  '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF718096),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Working Days
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Color(0xFF718096),
                ),
                const SizedBox(width: 8),
                Text(
                  '${leave['numberOfWorkingDays'] ?? leave['numberOfDays'] ?? 0} working days',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF718096),
                  ),
                ),
              ],
            ),
            // Description
            if (leave['description'] != null && leave['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Description:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                leave['description'],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF4A5568),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Applied Date and Leave ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Applied: ${appliedAt.day}/${appliedAt.month}/${appliedAt.year}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFA0AEC0),
                  ),
                ),
                if (leave['leaveId'] != null)
                  Text(
                    'ID: ${leave['leaveId']}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFA0AEC0),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}