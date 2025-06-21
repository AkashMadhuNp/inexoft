// import 'package:flutter/material.dart';
// import 'package:inexo/widgets/signUp/designation_dropdown.dart';
// import 'custom_text_field.dart';

// class SignupForm extends StatelessWidget {
//   final GlobalKey<FormState> formKey;
//   final TextEditingController nameController;
//   final TextEditingController emailController;
//   final TextEditingController passwordController;
//   final TextEditingController confirmPasswordController;
//   final String? selectedUserType;
//   final String? selectedDesignation;
//   final bool isPasswordVisible;
//   final bool isConfirmPasswordVisible;
//   final VoidCallback togglePasswordVisibility;
//   final VoidCallback toggleConfirmPasswordVisibility;
//   final void Function(String?) onDesignationChanged;

//   const SignupForm({
//     super.key,
//     required this.formKey,
//     required this.nameController,
//     required this.emailController,
//     required this.passwordController,
//     required this.confirmPasswordController,
//     required this.selectedUserType,
//     required this.selectedDesignation,
//     required this.isPasswordVisible,
//     required this.isConfirmPasswordVisible,
//     required this.togglePasswordVisibility,
//     required this.toggleConfirmPasswordVisibility,
//     required this.onDesignationChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final verticalPadding = screenHeight * 0.015;

//     return Form(
//       key: formKey,
//       child: Column(
//         children: [
//           CustomTextField(
//             controller: nameController,
//             label: 'Full Name',
//             icon: Icons.person,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter your name';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: verticalPadding * 0.8),
          
//           CustomTextField(
//             controller: emailController,
//             label: 'Email',
//             icon: Icons.email,
//             keyboardType: TextInputType.emailAddress,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter your email';
//               }
//               if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                 return 'Please enter a valid email';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: verticalPadding * 0.8),
          
//           // Designation dropdown for employees
//           if (selectedUserType == 'employee') ...[
//             CustomDropdown(
//               selectedValue: selectedDesignation,
//               label: 'Designation',
//               icon: Icons.work,
//               items: const [
//                 'Software Developer',
//                 'UI/UX Designer',
//                 'Project Manager',
//                 'Business Analyst',
//                 'Quality Assurance',
//                 'DevOps Engineer',
//                 'Data Scientist',
//                 'Marketing Specialist',
//                 'Sales Representative',
//                 'Customer Support',
//                 'Other',
//               ],
//               onChanged: onDesignationChanged,
//               validator: (value) {
//                 if (selectedUserType == 'employee' && (value == null || value.isEmpty)) {
//                   return 'Please select your designation';
//                 }
//                 return null;
//               },
//             ),
//             SizedBox(height: verticalPadding * 0.8),
//           ],
          
//           CustomTextField(
//             controller: passwordController,
//             label: 'Password',
//             icon: Icons.lock,
//             obscureText: !isPasswordVisible,
//             suffixIcon: IconButton(
//               icon: Icon(
//                 isPasswordVisible ? Icons.visibility_off : Icons.visibility,
//                 color: Colors.grey[600],
//               ),
//               onPressed: togglePasswordVisibility,
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter a password';
//               }
//               if (value.length < 6) {
//                 return 'Password must be at least 6 characters';
//               }
//               return null;
//             },
//           ),
//           SizedBox(height: verticalPadding * 0.8),
          
//           CustomTextField(
//             controller: confirmPasswordController,
//             label: 'Confirm Password',
//             icon: Icons.lock_outline,
//             obscureText: !isConfirmPasswordVisible,
//             suffixIcon: IconButton(
//               icon: Icon(
//                 isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
//                 color: Colors.grey[600],
//               ),
//               onPressed: toggleConfirmPasswordVisibility,
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please confirm your password';
//               }
//               if (value != passwordController.text) {
//                 return 'Passwords do not match';
//               }
//               return null;
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }