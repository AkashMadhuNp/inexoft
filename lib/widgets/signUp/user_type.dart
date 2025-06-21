// lib/widgets/user_type_selector.dart
import 'package:flutter/material.dart';

class UserTypeSelector extends StatelessWidget {
  final String? selectedUserType;
  final Function(String) onUserTypeSelected;

  const UserTypeSelector({
    super.key,
    required this.selectedUserType,
    required this.onUserTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final verticalPadding = screenHeight * 0.015;
    final fontSizeSubtitle = isTablet ? screenWidth * 0.025 : screenWidth * 0.04;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: verticalPadding * 0.8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: const Color(0xFF4A00E0),
                size: screenWidth * 0.05,
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                'Account Type:',
                style: TextStyle(
                  fontSize: fontSizeSubtitle,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: verticalPadding * 0.5),
          Row(
            children: [
              Expanded(
                child: _UserTypeOption(
                  text: 'Employee',
                  isSelected: selectedUserType == 'employee',
                  onTap: () => onUserTypeSelected('employee'),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: _UserTypeOption(
                  text: 'HR Manager',
                  isSelected: selectedUserType == 'hr',
                  onTap: () => onUserTypeSelected('hr'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserTypeOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeOption({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final verticalPadding = screenHeight * 0.015;
    final fontSizeSubtitle = isTablet ? screenWidth * 0.025 : screenWidth * 0.04;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding * 0.6,
          horizontal: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A00E0) : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A00E0) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSizeSubtitle * 0.9,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}