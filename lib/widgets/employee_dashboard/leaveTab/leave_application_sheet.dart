import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaveApplicationSheet {
  static void show({
    required BuildContext context,
    required GlobalKey<FormState> leaveFormKey,
    required List<String> leaveTypes,
    required String? selectedLeaveType,
    required TextEditingController reasonController,
    required TextEditingController descriptionController,
    required TextEditingController startDateController,
    required TextEditingController endDateController,
    required TextEditingController workingDaysController,
    required DateTime? startDate,
    required DateTime? endDate,
    required Function(String?) onLeaveTypeChanged,
    required Function(DateTime, bool) onDateSelected,
    required Future<void> Function() onSubmit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Form(
              key: leaveFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leave Application',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: selectedLeaveType,
                    decoration: _getInputDecoration('Leave Type', Icons.category),
                    items: leaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: onLeaveTypeChanged,
                    validator: (value) => value == null ? 'Please select leave type' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    decoration: _getInputDecoration('Reason', Icons.lightbulb_outline),
                    validator: (value) => value!.isEmpty ? 'Please enter reason' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: _getInputDecoration('Description (Optional)', Icons.description),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: startDateController,
                          decoration: _getInputDecoration('Start Date', Icons.calendar_today),
                          readOnly: true,
                          onTap: () => _selectDate(context, true, onDateSelected),
                          validator: (value) => value!.isEmpty ? 'Select start date' : null,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: endDateController,
                          decoration: _getInputDecoration('End Date', Icons.event),
                          readOnly: true,
                          onTap: () => _selectDate(context, false, onDateSelected),
                          validator: (value) => value!.isEmpty ? 'Select end date' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: workingDaysController,
                    decoration: _getInputDecoration('Number of Working Days', Icons.work),
                    readOnly: true,
                    validator: (value) => value!.isEmpty ? 'Working days not calculated' : null,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1976D2),
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Submit Application',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static InputDecoration _getInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: Color(0xFF1976D2)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  static Future<void> _selectDate(BuildContext context, bool isStartDate, Function(DateTime, bool) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xFF1976D2),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      onDateSelected(picked, isStartDate);
    }
  }
}