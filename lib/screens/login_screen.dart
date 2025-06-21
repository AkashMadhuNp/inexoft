import 'package:flutter/material.dart';
import 'package:inexo/screens/pending_approval_screen.dart';
import 'package:inexo/screens/rejected_status_screen.dart';
import 'package:inexo/screens/sign_up.dart';
import 'package:inexo/screens/hr/hr_dashboard.dart';
import 'package:inexo/screens/employyee/employee_dashboard.dart';
import 'package:inexo/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String email = _emailController.text.trim();
        String password = _passwordController.text;

        // Call Firebase signin
        Map<String, dynamic> result = await _authService.signIn(
          email: email,
          password: password,
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          String userType = result['userType'];
          String status = result['status'];
          String userName = result['user']?.displayName ?? 'User';
          
          _showSnackBar(
            'Welcome back, $userName!',
            Colors.green,
            duration: 2,
          );

          // Navigate based on user type and status
          Future.delayed(const Duration(milliseconds: 800), () {
            _navigateBasedOnUserStatus(userType, status, result['user']);
          });
        } else {
          _showSnackBar(
            result['error'] ?? 'Login failed. Please try again.',
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

  void _navigateBasedOnUserStatus(String userType, String status, dynamic user) {
    if (userType == 'hr') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HrDashboard()),
        (route) => false,
      );
    } else if (userType == 'employee') {
      switch (status) {
        case 'approved':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => EmployeeDashboard()),
            (route) => false,
          );
          break;
          
        case 'pending':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PendingApprovalScreen(user: user),
            ),
            (route) => false,
          );
          break;
          
        case 'rejected':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => RejectedStatusScreen(user: user),
            ),
            (route) => false,
          );
          break;
          
        default:
          _showSnackBar(
            'Unable to determine account status. Please contact support.',
            Colors.red,
            duration: 4,
          );
          break;
      }
    } else {
      _showSnackBar(
        'Unable to determine user type. Please contact support.',
        Colors.red,
        duration: 4,
      );
    }
  }

  void _showSnackBar(String message, Color backgroundColor, {int duration = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isTablet = screenWidth > 600;

    final cardPadding = screenWidth * 0.06;
    final verticalPadding = screenHeight * 0.03;
    final cardMaxWidth = isTablet ? screenWidth * 0.5 : screenWidth * 0.9;
    final fontSizeTitle = isTablet ? screenWidth * 0.05 : screenWidth * 0.08;
    final fontSizeSubtitle = isTablet ? screenWidth * 0.03 : screenWidth * 0.045;
    final buttonHeight = screenHeight * 0.07;
    final iconSize = screenWidth * 0.06;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 144, 200, 245),
              Color(0xFF8E2DE2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(cardPadding),
              child: Card(
                elevation: screenWidth * 0.02,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                child: Container(
                  padding: EdgeInsets.all(cardPadding),
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: screenWidth * 0.05,
                        offset: Offset(0, screenHeight * 0.015),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF4A00E0),
                          ),
                        ),
                        SizedBox(height: verticalPadding * 0.5),
                        Text(
                          'Sign in to your account',
                          style: TextStyle(
                            fontSize: fontSizeSubtitle,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: verticalPadding * 2),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              size: iconSize,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        SizedBox(height: verticalPadding),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              size: iconSize,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: iconSize,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        SizedBox(height: verticalPadding * 1.5),
                        SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A00E0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              ),
                              elevation: screenWidth * 0.01,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: screenWidth * 0.05,
                                    width: screenWidth * 0.05,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: screenWidth * 0.005,
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: fontSizeSubtitle,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: verticalPadding),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Create an Account',
                            style: TextStyle(
                              fontSize: fontSizeSubtitle * 0.9,
                              color: const Color(0xFF4A00E0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}