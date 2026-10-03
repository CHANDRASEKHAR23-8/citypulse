import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _role = 'citizen';
  String _department = 'Roads';
  bool _obscurePassword = true;

  final List<String> _departments = ['Roads', 'Electricity', 'Sanitation', 'Water', 'Traffic'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _role,
      department: _role == 'officer' ? _department : null,
    );

    if (success && mounted) {
      Navigator.pop(context);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: AppTheme.priorityHigh,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Join CityPulse',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Empower your neighborhood with real-time issue reporting.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                    ),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password (min 6 characters)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                  ),
                  const SizedBox(height: 20),

                  // Role Selection
                  const Text(
                    'Account Role',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRoleOption('citizen', 'Citizen', Icons.person_rounded),
                      const SizedBox(width: 8),
                      _buildRoleOption('officer', 'Officer', Icons.engineering_rounded),
                      const SizedBox(width: 8),
                      _buildRoleOption('admin', 'Admin', Icons.admin_panel_settings_rounded),
                    ],
                  ),

                  // Department selection if officer
                  if (_role == 'officer') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _department,
                      decoration: const InputDecoration(
                        labelText: 'Designated Department',
                        prefixIcon: Icon(Icons.business_rounded, color: AppTheme.textMuted),
                      ),
                      dropdownColor: AppTheme.bgCard,
                      items: _departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(dept, style: const TextStyle(color: AppTheme.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _department = val);
                      },
                    ),
                  ],

                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Complete Registration'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String roleVal, String label, IconData icon) {
    final isSelected = _role == roleVal;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _role = roleVal),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.18) : AppTheme.bgInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
