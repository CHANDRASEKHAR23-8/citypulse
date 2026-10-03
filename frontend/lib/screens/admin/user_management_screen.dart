import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final list = await auth.apiService.getAdminUsers();
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _editUser(User user) {
    String selectedRole = user.role;
    String? selectedDept = user.department ?? 'Roads';
    final departments = ['Roads', 'Electricity', 'Sanitation', 'Water', 'Traffic'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.border),
            ),
            title: Text(
              'Edit User: ${user.name}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 16),
                const Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: AppTheme.bgInput,
                  items: const [
                    DropdownMenuItem(value: 'citizen', child: Text('Citizen')),
                    DropdownMenuItem(value: 'officer', child: Text('Officer')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedRole = val);
                    }
                  },
                ),
                if (selectedRole == 'officer') ...[
                  const SizedBox(height: 14),
                  const Text('Assigned Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    dropdownColor: AppTheme.bgInput,
                    items: departments.map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedDept = val);
                      }
                    },
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  try {
                    await auth.apiService.adminUpdateUser(
                      user.id,
                      role: selectedRole,
                      department: selectedRole == 'officer' ? selectedDept : null,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Updated ${user.name} successfully!'),
                        backgroundColor: AppTheme.statusResolved,
                      ),
                    );
                    _fetchUsers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.priorityHigh),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final u = _users[index];
                final roleColor = u.isAdmin
                    ? AppTheme.priorityHigh
                    : (u.isOfficer ? AppTheme.accent : AppTheme.textSecondary);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: roleColor.withOpacity(0.18),
                        child: Text(
                          u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                          style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              u.email,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    u.role.toUpperCase(),
                                    style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (u.department != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgInput,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      u.department!,
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                        onPressed: () => _editUser(u),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
