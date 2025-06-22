import 'package:flutter/material.dart';

class PermissionsCard extends StatelessWidget {
  final Map<String, dynamic> employeeData;

  const PermissionsCard({
    super.key,
    required this.employeeData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.purple, size: 24),
                SizedBox(width: 8),
                Text(
                  "Permissions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (employeeData['permissions'] != null) ...[
              ...((employeeData['permissions'] as Map<String, dynamic>).entries.map((permission) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        permission.value == true ? Icons.check_circle : Icons.cancel,
                        color: permission.value == true ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatPermissionName(permission.key),
                        style: TextStyle(
                          fontSize: 14,
                          color: permission.value == true ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()),
            ] else ...[
              const Text(
                "No permissions data available",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPermissionName(String key) {
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceFirst('can', 'Can')
        .trim();
  }
}