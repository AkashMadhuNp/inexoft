// lib/widgets/password_strength_indicator.dart
import 'package:flutter/material.dart';
import 'package:inexo/services/validation_service.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength passwordStrength;

  const PasswordStrengthIndicator({
    super.key,
    required this.passwordStrength,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final fontSizeSmall = isTablet ? screenWidth * 0.02 : screenWidth * 0.032;
    
    Color strengthColor = _getStrengthColor();
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: strengthColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(color: strengthColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStrengthHeader(fontSizeSmall, strengthColor),
          SizedBox(height: screenWidth * 0.015),
          _buildProgressBar(strengthColor),
          SizedBox(height: screenWidth * 0.015),
          _buildCriteriaList(fontSizeSmall, screenWidth),
        ],
      ),
    );
  }

  Color _getStrengthColor() {
    switch (passwordStrength.level) {
      case PasswordStrengthLevel.weak:
        return Colors.red;
      case PasswordStrengthLevel.fair:
        return Colors.orange;
      case PasswordStrengthLevel.good:
        return Colors.blue;
      case PasswordStrengthLevel.strong:
        return Colors.green;
    }
  }

  Widget _buildStrengthHeader(double fontSizeSmall, Color strengthColor) {
    return Row(
      children: [
        Text(
          'Password Strength: ',
          style: TextStyle(
            fontSize: fontSizeSmall,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          passwordStrength.text,
          style: TextStyle(
            fontSize: fontSizeSmall,
            fontWeight: FontWeight.bold,
            color: strengthColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(Color strengthColor) {
    return LinearProgressIndicator(
      value: passwordStrength.percentage,
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
    );
  }

  Widget _buildCriteriaList(double fontSizeSmall, double screenWidth) {
    return Wrap(
      spacing: screenWidth * 0.02,
      runSpacing: screenWidth * 0.01,
      children: passwordStrength.criteria.map((criterion) {
        bool isValid = criterion.contains('✓');
        return Text(
          criterion,
          style: TextStyle(
            fontSize: fontSizeSmall * 0.9,
            color: isValid ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}