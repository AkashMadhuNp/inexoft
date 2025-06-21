import 'package:flutter/material.dart';
import 'package:inexo/services/validation_service.dart';
import 'package:inexo/services/employee_service.dart';
import 'package:inexo/widgets/signUp/custom_text_field.dart';
import 'package:inexo/widgets/signUp/designation_dropdown.dart';
import 'package:inexo/widgets/signUp/password_strength_indicator.dart';

class AddEmployeeBottomSheet extends StatefulWidget {
  const AddEmployeeBottomSheet({super.key});

  @override
  State<AddEmployeeBottomSheet> createState() => _AddEmployeeBottomSheetState();
}

class _AddEmployeeBottomSheetState extends State<AddEmployeeBottomSheet> {
  String? _selectedUserType = 'employee'; 
  String? _selectedDesignation;  
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  PasswordStrength? _passwordStrength;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _designationController.dispose();
    _emailController.dispose();
    super.dispose();
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

  void _onPasswordChanged(String password) {
    setState(() {
      if (password.isNotEmpty) {
        _passwordStrength = ValidationService.calculatePasswordStrength(password);
      } else {
        _passwordStrength = null;
      }
    });
  }

    bool _validateForm() {
  // Check if form is valid
  if (!_formKey.currentState!.validate()) {
    return false;
  }

  // Check designation selection
  String? designationError = ValidationService.validateDesignation(_selectedUserType, _selectedDesignation);
  if (designationError != null) {
    _showSnackBar(designationError, Colors.red);
    return false;
  }

  // Check password strength - FIXED LINE
  if (_passwordStrength == null || _passwordStrength!.level == PasswordStrengthLevel.weak) {
    _showSnackBar('Please choose a stronger password (minimum: medium strength)', Colors.red);
    return false;
  }

  return true;
}

  Future<void> _addEmployee() async {
    // Validate all form fields
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String formattedName = ValidationService.formatName(_nameController.text.trim());
      String email = _emailController.text.trim().toLowerCase();
      String password = _passwordController.text;
      String designation = _selectedDesignation ?? _designationController.text.trim();

      // Create approved employee with Firebase Auth account
      Map<String, dynamic> result = await EmployeeService.addApprovedEmployee(
        fullName: formattedName,
        email: email,
        password: password,
        designation: designation,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Clear form on success
          _clearForm();
          
          Navigator.pop(context, true); // Return true to indicate success
          
          _showSnackBar(
            'Employee "${formattedName}" created successfully!\n'
            'Employee ID: ${result['employeeId']}\n'
            'Login credentials are ready for use.',
            Colors.green,
          );
        } else {
          _showSnackBar(
            result['error'] ?? 'Failed to create employee. Please try again.',
            Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to create employee: ${e.toString()}', Colors.red);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _designationController.clear();
    setState(() {
      _selectedDesignation = null;
      _passwordStrength = null;
      _isPasswordVisible = false;
    });
  }




  


  

  

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with drag indicator
              Column(
                children: [
                  // Drag indicator
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add New Employee',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Employee Name Field with validation
                      CustomTextField(
                        controller: _nameController,
                        label: "Employee Name",
                        icon: Icons.person,
                        validator: (value) => ValidationService.validateName(value),
                      ),

                      SizedBox(height: 20),

                      // Employee Email Field with validation
                      CustomTextField(
                        controller: _emailController,
                        label: "Employee's Email",
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => ValidationService.validateEmail(value, 'employee'),
                        helperText: 'Use personal email (gmail, yahoo, outlook, etc.)',
                      ),

                      SizedBox(height: 20),

                      // Designation Dropdown
                      DesignationDropdown(
                        selectedDesignation: _selectedDesignation,
                        onChanged: _onDesignationChanged,
                        userType: _selectedUserType,
                      ),

                      SizedBox(height: 20),

                      // Password Field with validation and strength indicator
                      CustomTextField(
                        controller: _passwordController,
                        label: "Employee Password",
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
                        SizedBox(height: 12),
                        PasswordStrengthIndicator(passwordStrength: _passwordStrength!),
                      ],
                      
                      SizedBox(height: 32),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _addEmployee,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1976D2),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Add Employee',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}