// lib/widgets/designation_dropdown.dart
import 'package:flutter/material.dart';
import 'package:inexo/services/validation_service.dart';

class DesignationDropdown extends StatelessWidget {
  final String? selectedDesignation;
  final void Function(String?) onChanged;
  final String? userType;

  const DesignationDropdown({
    super.key,
    required this.selectedDesignation,
    required this.onChanged,
    this.userType,
  });

  static const List<String> _designationOptions = [
    'Software Developer',
    'UI/UX Designer',
    'Project Manager',
    'Business Analyst',
    'Quality Assurance',
    'DevOps Engineer',
    'Data Scientist',
    'Marketing Specialist',
    'Sales Representative',
    'Customer Support',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final fontSizeSubtitle = isTablet ? screenWidth * 0.025 : screenWidth * 0.04;
    
    return DropdownButtonFormField<String>(
      value: selectedDesignation,
      onChanged: onChanged,
      validator: (value) => ValidationService.validateDesignation(userType, value),
      decoration: InputDecoration(
        labelText: 'Designation',
        helperText: 'Select your job role/position',
        helperStyle: TextStyle(
          fontSize: fontSizeSubtitle * 0.8,
          color: Colors.grey[600],
        ),
        prefixIcon: const Icon(Icons.work, color: Color(0xFF4A00E0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.035,
        ),
      ),
      items: _designationOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(fontSize: fontSizeSubtitle),
          ),
        );
      }).toList(),
    );
  }
}