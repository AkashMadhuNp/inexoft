import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceDetailsCard extends StatelessWidget {
  final Map<String, dynamic>? record;
  final String formattedDate;
  final bool isToday;

  const AttendanceDetailsCard({
    super.key,
    required this.record,
    required this.formattedDate,
    required this.isToday,
  });

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'clocked_in':
        color = Colors.orange;
        text = 'In Progress';
        icon = Icons.play_circle_filled;
        break;
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Attendance Details',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (record != null) ...[
              _buildDetailRow('Date', formattedDate),
              if (record!['clockInTime'] != null)
                _buildDetailRow('Clock In', record!['clockInTime'].toString().split('.')[0]),
              if (record!['clockOutTime'] != null)
                _buildDetailRow('Clock Out', record!['clockOutTime'].toString().split('.')[0]),
              if (record!['totalHours'] != null)
                _buildDetailRow('Total Hours', record!['totalHours']),
              if (record!['clockInAddress'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Location:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record!['clockInAddress'],
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildStatusChip(record!['status']),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      isToday
                          ? 'No attendance recorded for today'
                          : 'No attendance data for selected date',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}