import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButtons extends StatelessWidget {
  final bool canClockIn;
  final bool canClockOut;
  final bool isLocationLoading;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;

  const ActionButtons({
    super.key,
    required this.canClockIn,
    required this.canClockOut,
    required this.isLocationLoading,
    required this.onClockIn,
    required this.onClockOut,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canClockIn && !isLocationLoading ? onClockIn : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: canClockIn ? 4 : 0,
            ),
            icon: isLocationLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(
              isLocationLoading ? 'Getting Location...' : 'Clock In',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canClockOut ? onClockOut : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canClockOut ? const Color(0xFFF44336) : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: canClockOut ? 4 : 0,
            ),
            icon: const Icon(Icons.logout),
            label: Text(
              'Clock Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}