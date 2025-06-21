import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate Employee ID
  static String _generateEmployeeId() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2); // Last 2 digits of year
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    
    return 'EMP$year$month$day$hour$minute';
  }

  // Get department based on designation
  static String _getDepartmentByDesignation(String designation) {
    const Map<String, String> designationToDepartment = {
      'Software Developer': 'IT',
      'Senior Software Developer': 'IT',
      'Frontend Developer': 'IT',
      'Backend Developer': 'IT',
      'Full Stack Developer': 'IT',
      'Mobile Developer': 'IT',
      'DevOps Engineer': 'IT',
      'QA Engineer': 'IT',
      'System Administrator': 'IT',
      'Data Analyst': 'IT',
      'UI/UX Designer': 'Design',
      'Graphic Designer': 'Design',
      'Product Designer': 'Design',
      'Marketing Manager': 'Marketing',
      'Digital Marketing Specialist': 'Marketing',
      'Content Writer': 'Marketing',
      'Sales Executive': 'Sales',
      'Sales Manager': 'Sales',
      'Business Development': 'Sales',
      'HR Manager': 'HR',
      'HR Executive': 'HR',
      'Recruiter': 'HR',
      'Finance Manager': 'Finance',
      'Accountant': 'Finance',
      'Operations Manager': 'Operations',
      'Project Manager': 'Operations',
      'Customer Support': 'Support',
      'Technical Support': 'Support',
    };

    return designationToDepartment[designation] ?? 'General';
  }

  // Add employee to approved_employee collection
  static Future<Map<String, dynamic>> addApprovedEmployee({
    required String fullName,
    required String email,
    required String password,
    required String designation,
  }) async {
    try {
      // Create Firebase Auth user first
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      String employeeId = _generateEmployeeId();
      String department = _getDepartmentByDesignation(designation);
      
      final now = Timestamp.now();

      // Create employee document
      Map<String, dynamic> employeeData = {
        'approvedAt': now,
        'createdAt': now,
        'department': department,
        'designation': designation,
        'email': email,
        'employeeId': employeeId,
        'fullName': fullName,
        'isActive': true,
        'joiningDate': now,
        'leaveQuota': 24,
        'leaveTaken': 0,
        'permissions': {
          'canApplyLeave': true,
          'canViewAttendance': true,
          'canViewPayslip': true,
          'canViewProfile': true,
        },
        'processedAt': now,
        'status': 'Approved',
        'uid': uid,
        'updatedAt': now,
        'userType': 'employee',
      };

      // Add to approved_employee collection
      await _firestore.collection('approved_employee').doc(uid).set(employeeData);

      // Update user profile with display name
      await userCredential.user!.updateDisplayName(fullName);

      // Add additional user info to users collection (if you have one)
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'userType': 'employee',
        'employeeId': employeeId,
        'designation': designation,
        'department': department,
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      });

      return {
        'success': true,
        'employeeId': employeeId,
        'uid': uid,
        'message': 'Employee added successfully',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } on FirebaseException catch (e) {
      return {
        'success': false,
        'error': 'Database error: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  // Get all approved employees
  static Future<List<Map<String, dynamic>>> getAllApprovedEmployees() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('approved_employee')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['documentId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch employees: ${e.toString()}');
    }
  }

  // Update employee status
  static Future<bool> updateEmployeeStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection('approved_employee').doc(uid).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete employee
  static Future<bool> deleteEmployee(String uid) async {
    try {
      // Delete from approved_employee collection
      await _firestore.collection('approved_employee').doc(uid).delete();
      
      // Delete from users collection if exists
      await _firestore.collection('users').doc(uid).delete();
      
      // Note: This doesn't delete the Firebase Auth user
      // You may want to implement that separately with admin privileges
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get employee by ID
  static Future<Map<String, dynamic>?> getEmployeeById(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('approved_employee')
          .doc(uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['documentId'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update employee leave quota
  static Future<bool> updateLeaveQuota(String uid, int newQuota) async {
    try {
      await _firestore.collection('approved_employee').doc(uid).update({
        'leaveQuota': newQuota,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update employee permissions
  static Future<bool> updateEmployeePermissions(
    String uid,
    Map<String, bool> permissions,
  ) async {
    try {
      await _firestore.collection('approved_employee').doc(uid).update({
        'permissions': permissions,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get employees by department
  static Future<List<Map<String, dynamic>>> getEmployeesByDepartment(
    String department,
  ) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('approved_employee')
          .where('department', isEqualTo: department)
          .where('isActive', isEqualTo: true)
          .orderBy('fullName')
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['documentId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch employees by department: ${e.toString()}');
    }
  }

  // Search employees by name or email
  static Future<List<Map<String, dynamic>>> searchEmployees(String query) async {
    try {
      String searchQuery = query.toLowerCase();
      
      QuerySnapshot querySnapshot = await _firestore
          .collection('approved_employee')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> results = [];
      
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String fullName = (data['fullName'] ?? '').toLowerCase();
        String email = (data['email'] ?? '').toLowerCase();
        String employeeId = (data['employeeId'] ?? '').toLowerCase();
        
        if (fullName.contains(searchQuery) || 
            email.contains(searchQuery) || 
            employeeId.contains(searchQuery)) {
          data['documentId'] = doc.id;
          results.add(data);
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to search employees: ${e.toString()}');
    }
  }
}