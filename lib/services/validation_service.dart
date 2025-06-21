class ValidationService {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    
    value = value.trim();
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Name must contain at least one letter';
    }
    
    if (RegExp(r'\s{2,}').hasMatch(value)) {
      return 'Name cannot contain multiple consecutive spaces';
    }
    
    return null;
  }

  // Role-based email validation
  static String? validateEmail(String? value, String? userType) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  
  String emailLower = value.trim().toLowerCase();
  
  // Basic email format validation
  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(emailLower)) {
    return 'Please enter a valid email address';
  }
  
  if (userType == 'hr') {
    // HR users must use emails containing "hr" in various valid formats
    bool hasValidHRPattern = emailLower.contains('hr.') || 
                           emailLower.contains('hr@') || 
                           emailLower.contains('.hr@') ||
                           emailLower.contains('hr') && emailLower.contains('@');
    
    if (!hasValidHRPattern) {
      return 'HR emails must contain "hr" (e.g., hr@company.com, john.hr@company.com, hr.dept@company.com)';
    }
    
    // Additional check: HR emails should not use personal domains
    const personalDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
      'icloud.com',
      'protonmail.com',
      'aol.com',
      'live.com',
      'msn.com',
      'ymail.com',
      'rediffmail.com',
    ];
    
    bool isPersonalDomain = personalDomains.any((domain) => emailLower.endsWith(domain));
    if (isPersonalDomain) {
      return 'HR emails should use company domains, not personal email providers';
    }
    
  } else if (userType == 'employee') {
    // Employees cannot use emails that look like HR emails
    if (emailLower.contains('hr.') || 
        emailLower.contains('hr@') || 
        emailLower.contains('.hr@') ||
        emailLower.endsWith('hr.com')) {
      return 'Employees cannot use HR-related email addresses';
    }
    
    // Check for common personal email domains
    const personalDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
      'icloud.com',
      'protonmail.com',
      'aol.com',
      'live.com',
      'msn.com',
      'ymail.com',
      'rediffmail.com',
    ];
    
    bool isPersonalEmail = personalDomains.any((domain) => emailLower.endsWith(domain));
    if (!isPersonalEmail) {
      return 'Please use a personal email address (gmail, yahoo, outlook, etc.)';
    }
  }
  
  return null;
}

// Alternative more flexible HR validation approach:
static String? validateEmailAlternative(String? value, String? userType) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  
  String emailLower = value.trim().toLowerCase();
  
  // Basic email format validation
  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(emailLower)) {
    return 'Please enter a valid email address';
  }
  
  if (userType == 'hr') {
    // More flexible HR validation - checks for "hr" anywhere in the email
    if (!emailLower.contains('hr')) {
      return 'HR emails must contain "hr" somewhere in the email address';
    }
    
    // Ensure it's not just "hr" in a personal email
    const personalDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
      'icloud.com',
      'protonmail.com',
      'aol.com',
      'live.com',
      'msn.com',
      'ymail.com',
      'rediffmail.com',
    ];
    
    bool isPersonalDomain = personalDomains.any((domain) => emailLower.endsWith(domain));
    if (isPersonalDomain) {
      return 'HR emails should use company domains (e.g., hr@company.com)';
    }
    
  } else if (userType == 'employee') {
    // Employees must use personal email domains
    const personalDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
      'icloud.com',
      'protonmail.com',
      'aol.com',
      'live.com',
      'msn.com',
      'ymail.com',
      'rediffmail.com',
    ];
    
    bool isPersonalEmail = personalDomains.any((domain) => emailLower.endsWith(domain));
    if (!isPersonalEmail) {
      return 'Please use a personal email address (gmail, yahoo, outlook, etc.)';
    }
    
    // Prevent employees from using HR-looking emails even with personal domains
    if (emailLower.contains('hr@') || emailLower.contains('.hr@')) {
      return 'Employee emails should not contain HR-related patterns';
    }
  }
  
  return null;
}


  // Enhanced password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)';
    }
    
    const commonPasswords = [
      'password',
      '12345678',
      'qwerty123',
      'abc12345',
      'password123',
      '123456789',
      'welcome123',
    ];
    
    if (commonPasswords.contains(value.toLowerCase())) {
      return 'This password is too common. Please choose a stronger password';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Designation validation for employees
  static String? validateDesignation(String? userType, String? selectedDesignation) {
    if (userType == 'employee' && selectedDesignation == null) {
      return 'Please select your designation';
    }
    return null;
  }

  // Format name with proper capitalization
  static String formatName(String name) {
    return name
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }

  // Password strength calculation
  static PasswordStrength calculatePasswordStrength(String password) {
    int strength = 0;
    List<String> criteria = [];
    
    if (password.length >= 8) {
      strength++;
      criteria.add('Length ✓');
    } else {
      criteria.add('Length ✗');
    }
    
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      strength++;
      criteria.add('Uppercase ✓');
    } else {
      criteria.add('Uppercase ✗');
    }
    
    if (RegExp(r'[a-z]').hasMatch(password)) {
      strength++;
      criteria.add('Lowercase ✓');
    } else {
      criteria.add('Lowercase ✗');
    }
    
    if (RegExp(r'[0-9]').hasMatch(password)) {
      strength++;
      criteria.add('Number ✓');
    } else {
      criteria.add('Number ✗');
    }
    
    if (RegExp(r'[!@#$%^&*(),.?":{"}|<>]').hasMatch(password)) {
      strength++;
      criteria.add('Special char ✓');
    } else {
      criteria.add('Special char ✗');
    }
    
    PasswordStrengthLevel strengthLevel;
    String strengthText;
    
    switch (strength) {
      case 0:
      case 1:
      case 2:
        strengthLevel = PasswordStrengthLevel.weak;
        strengthText = 'Weak';
        break;
      case 3:
        strengthLevel = PasswordStrengthLevel.fair;
        strengthText = 'Fair';
        break;
      case 4:
        strengthLevel = PasswordStrengthLevel.good;
        strengthText = 'Good';
        break;
      default:
        strengthLevel = PasswordStrengthLevel.strong;
        strengthText = 'Strong';
    }
    
    return PasswordStrength(
      level: strengthLevel,
      text: strengthText,
      score: strength,
      maxScore: 5,
      criteria: criteria,
    );
  }

  // Get personal email domains
  static List<String> getPersonalEmailDomains() {
    return const [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
      'icloud.com',
      'protonmail.com',
      'aol.com',
      'live.com',
      'msn.com',
      'ymail.com',
      'rediffmail.com',
    ];
  }

  // Get common passwords list
  static List<String> getCommonPasswords() {
    return const [
      'password',
      '12345678',
      'qwerty123',
      'abc12345',
      'password123',
      '123456789',
      'welcome123',
    ];
  }
}

// Supporting classes for password strength
enum PasswordStrengthLevel {
  weak,
  fair,
  good,
  strong,
}

class PasswordStrength {
  final PasswordStrengthLevel level;
  final String text;
  final int score;
  final int maxScore;
  final List<String> criteria;

  const PasswordStrength({
    required this.level,
    required this.text,
    required this.score,
    required this.maxScore,
    required this.criteria,
  });

  double get percentage => score / maxScore;
}