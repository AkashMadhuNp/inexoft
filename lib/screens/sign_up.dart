import 'package:flutter/material.dart';
import 'package:inexo/screens/employyee/employee_dashboard.dart';
import 'package:inexo/screens/hr/hr_dashboard.dart';
import 'package:inexo/services/auth_service.dart';
import 'package:inexo/services/validation_service.dart';
import 'package:inexo/widgets/signUp/custom_button.dart';
import 'package:inexo/widgets/signUp/custom_text_field.dart';
import 'package:inexo/widgets/signUp/designation_dropdown.dart';
import 'package:inexo/widgets/signUp/password_strength_indicator.dart';
import 'package:inexo/widgets/signUp/user_type.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _selectedUserType;
  String? _selectedDesignation;
  PasswordStrength? _passwordStrength;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onUserTypeSelected(String userType) {
    setState(() {
      _selectedUserType = userType;
      if (userType == 'hr') {
        _selectedDesignation = null;
      }
      _emailController.clear();
    });
  }

  void _onDesignationChanged(String? newValue) {
    setState(() {
      _selectedDesignation = newValue;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _onPasswordChanged(String password) {
    setState(() {
      if (password.isNotEmpty) {
        _passwordStrength = ValidationService.calculatePasswordStrength(password);
      } else {
        _passwordStrength = null;
      }
    });
  }

  Future<void> _handleSignUp() async {
    if (_selectedUserType == null) {
      _showSnackBar('Please select your account type', Colors.red);
      return;
    }

    String? designationError = ValidationService.validateDesignation(_selectedUserType, _selectedDesignation);
    if (designationError != null) {
      _showSnackBar(designationError, Colors.red);
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String formattedName = ValidationService.formatName(_nameController.text.trim());
        String email = _emailController.text.trim();
        String password = _passwordController.text;

        // Call Firebase signup
        Map<String, dynamic> result = await _authService.signUp(
          email: email,
          password: password,
          fullName: formattedName,
          userType: _selectedUserType!,
          designation: _selectedDesignation,
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          _showSnackBar(
            'Account created successfully as ${_selectedUserType == 'hr' ? 'HR Manager' : 'Employee'}!\nWelcome, $formattedName!',
            Colors.green,
            duration: 3,
          );

          // Navigate to appropriate dashboard after a short delay
          Future.delayed(const Duration(milliseconds: 1500), () {
            _navigateToDashboard();
          });
        } else {
          _showSnackBar(
            result['error'] ?? 'Failed to create account. Please try again.',
            Colors.red,
            duration: 4,
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          'An unexpected error occurred. Please try again.',
          Colors.red,
          duration: 3,
        );
      }
    }
  }


  void _showSnackBar(String message, Color backgroundColor, {int duration = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: duration),
      ),
    );
  }

  void _navigateToDashboard() {
    if (_selectedUserType == 'hr') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HrDashboard()),
      );
    } else if (_selectedUserType == 'employee') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EmployeeDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isTablet = screenWidth > 600;

    final cardPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.015;
    final fontSizeTitle = isTablet ? screenWidth * 0.04 : screenWidth * 0.065;
    final fontSizeSubtitle = isTablet ? screenWidth * 0.025 : screenWidth * 0.04;
    final buttonHeight = screenHeight * 0.055;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header Section
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: fontSizeTitle,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A00E0),
                  ),
                ),
                SizedBox(height: verticalPadding * 0.5),
                
                // User Type Selection
                UserTypeSelector(
                  selectedUserType: _selectedUserType,
                  onUserTypeSelected: _onUserTypeSelected,
                ),
                
                SizedBox(height: verticalPadding * 1.2),
                
                // Form Fields Section
                Expanded(
                  child: _selectedUserType == null 
                      ? _buildPlaceholderContent(screenWidth, verticalPadding, fontSizeSubtitle)
                      : _buildFormFields(verticalPadding),
                ),
                
                // Bottom Actions
                if (_selectedUserType != null) ...[
                  SizedBox(height: verticalPadding),
                  CustomButton(
                    text: 'Create Account',
                    onPressed: _isLoading ? null : _handleSignUp,
                    isLoading: _isLoading,
                    height: buttonHeight,
                  ),
                  SizedBox(height: verticalPadding * 0.6),
                  TextButton(
                    onPressed: () {
                      // Navigate to login screen
                    },
                    child: Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        fontSize: fontSizeSubtitle * 0.85,
                        color: const Color(0xFF4A00E0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderContent(double screenWidth, double verticalPadding, double fontSizeSubtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_upward,
            size: screenWidth * 0.08,
            color: Colors.grey[400],
          ),
          SizedBox(height: verticalPadding),
          Text(
            'Please select your account type above',
            style: TextStyle(
              fontSize: fontSizeSubtitle,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(double verticalPadding) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Full Name field
          CustomTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person,
            validator: (value) => ValidationService.validateName(value),
          ),
          SizedBox(height: verticalPadding * 0.8),
          
          // Email field
          CustomTextField(
            controller: _emailController,
            label: _selectedUserType == 'hr' 
                ? 'HR Email (must contain "hr")' 
                : 'Personal Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => ValidationService.validateEmail(value, _selectedUserType),
            helperText: _selectedUserType == 'hr' 
                ? 'Use an email address containing "hr"'
                : 'Use personal email (gmail, yahoo, outlook, etc.)',
          ),
          SizedBox(height: verticalPadding * 0.8),
          
          // Designation dropdown for employees
          if (_selectedUserType == 'employee') ...[
            DesignationDropdown(
              selectedDesignation: _selectedDesignation,
              onChanged: _onDesignationChanged,
              userType: _selectedUserType,
            ),
            SizedBox(height: verticalPadding * 0.8),
          ],
          
          // Password field
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock,
            obscureText: !_isPasswordVisible,
            onChanged: _onPasswordChanged,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: _togglePasswordVisibility,
            ),
            validator: (value) => ValidationService.validatePassword(value),
          ),
          
          // Password strength indicator
          if (_passwordStrength != null) ...[
            SizedBox(height: verticalPadding * 0.4),
            PasswordStrengthIndicator(passwordStrength: _passwordStrength!),
          ],
          
          SizedBox(height: verticalPadding * 0.8),
          
          // Confirm Password field
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: !_isConfirmPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: _toggleConfirmPasswordVisibility,
            ),
            validator: (value) => ValidationService.validateConfirmPassword(value, _passwordController.text),
          ),
        ],
      ),
    );
  }
}