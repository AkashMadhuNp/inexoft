import 'package:flutter/material.dart';

class RegistrationHeader extends StatelessWidget {
  final String? selectedUserType;
  final VoidCallback onChangeAccountType;

  const RegistrationHeader({
    super.key,
    required this.selectedUserType,
    required this.onChangeAccountType,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;
    final fontSize = isTablet ? screenWidth * 0.04 : screenWidth * 0.06;

    String headerText = '';
    IconData headerIcon = Icons.person;
    
    if (selectedUserType == 'hr') {
      headerText = 'HR Registration';
      headerIcon = Icons.admin_panel_settings;
    } else if (selectedUserType == 'employee') {
      headerText = 'Employee Registration';
      headerIcon = Icons.person;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              headerIcon,
              size: fontSize * 0.8,
              color: Color(0xFF4A00E0),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              headerText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A00E0),
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.02),
        TextButton(
          onPressed: onChangeAccountType,
          child: Text(
            'Change account type',
            style: TextStyle(
              fontSize: fontSize * 0.6,
              color: Colors.grey[600],
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}