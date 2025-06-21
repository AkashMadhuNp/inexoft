import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String hrCollection = 'hrlogin';
  static const String employeeCollection = 'employee_login';
  static const String approvedEmployeeCollection = "approved_employee";
  static const String rejectedEmployeeCollection = "rejected_employees";

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up method
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String userType,
    String? designation,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(fullName);

        if (userType == 'hr') {
          await _createHRDocument(user.uid, fullName, email);
        } else if (userType == 'employee') {
          await _createEmployeeDocument(user.uid, fullName, email, designation);
        }

        return {
          'success': true,
          'user': user,
          'userType': userType,
          'message': 'Account created successfully!'
        };
      }
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
    
    return {
      'success': false,
      'error': 'Failed to create account.',
    };
  }

  // Sign in method
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        Map<String, dynamic> userInfo = await _getUserTypeAndStatus(user.uid);
        
        return {
          'success': true,
          'user': user,
          'userType': userInfo['userType'],
          'status': userInfo['status'],
          'message': 'Login successful!'
        };
      }
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
    
    return {
      'success': false,
      'error': 'Failed to sign in.',
    };
  }

  // Sign out method
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create HR document in Firestore
  Future<void> _createHRDocument(String uid, String fullName, String email) async {
    await _firestore.collection(hrCollection).doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'userType': 'hr',
      'role': 'HR Manager',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  // Create Employee document in Firestore
  Future<void> _createEmployeeDocument(String uid, String fullName, String email, String? designation) async {
    await _firestore.collection(employeeCollection).doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'userType': 'employee',
      'designation': designation ?? 'Not Specified',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'status': "pending",
    });
  }

  // Get user type and status from Firestore
  Future<Map<String, dynamic>> _getUserTypeAndStatus(String uid) async {
    try {
      // Check HR collection first
      DocumentSnapshot hrDoc = await _firestore.collection(hrCollection).doc(uid).get();
      if (hrDoc.exists) {
        return {
          'userType': 'hr',
          'status': 'active'
        };
      }

      // Check approved employee collection
      DocumentSnapshot approvedDoc = await _firestore.collection(approvedEmployeeCollection).doc(uid).get();
      if (approvedDoc.exists) {
        return {
          'userType': 'employee',
          'status': 'approved'
        };
      }

      // Check rejected employee collection
      DocumentSnapshot rejectedDoc = await _firestore.collection(rejectedEmployeeCollection).doc(uid).get();
      if (rejectedDoc.exists) {
        return {
          'userType': 'employee',
          'status': 'rejected'
        };
      }

      // Check pending employee collection (original employee_login)
      DocumentSnapshot pendingDoc = await _firestore.collection(employeeCollection).doc(uid).get();
      if (pendingDoc.exists) {
        return {
          'userType': 'employee',
          'status': 'pending'
        };
      }

      return {
        'userType': 'unknown',
        'status': 'unknown'
      };
    } catch (e) {
      print('Error getting user type and status: $e');
      return {
        'userType': 'unknown',
        'status': 'error'
      };
    }
  }

  // Backward compatibility - Get user type only
  Future<String> _getUserType(String uid) async {
    Map<String, dynamic> userInfo = await _getUserTypeAndStatus(uid);
    return userInfo['userType'];
  }

  // Get user status only
  Future<String> getUserStatus(String uid) async {
    Map<String, dynamic> userInfo = await _getUserTypeAndStatus(uid);
    return userInfo['status'];
  }

  // Get authentication error message
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}