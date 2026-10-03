import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint.dart';
import '../../models/user.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_theme.dart';

class AssignDialog extends StatefulWidget {
  final Complaint complaint;

  const AssignDialog({super.key, required this.complaint});

  @override
  State<AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<AssignDialog> {
  late String _selectedDept;
  int? _selectedOfficerId;
  List<User> _officers = [];
  bool _loadingOfficers = true;

  final List<String> _departments = ['Roads', 'Electricity', 'Sanitation', 'Water', 'Traffic'];

  @override
  void initState() {
    super.initState();
    _selectedDept = widget.complaint.department;
    _selectedOfficerId = widget.complaint.officerId;
    _loadOfficers();
  }

  Future<void> _loadOfficers() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final allUsers = await auth.apiService.getAdminUsers();
      setState(() {
        _officers = allUsers.where((u) => u.isOfficer || u.isAdmin).toList();
        _loadingOfficers = false;
      });
    } catch (_) {
      setState(() => _loadingOfficers = false);
    }
  }

  Future<void> _submit() async {
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    final ok = await complaintProvider.assignComplaint(
      widget.complaint.id,
      department: _selectedDept,
      officerId: _selectedOfficerId,
    );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint #${widget.complaint.id} reassigned to $_selectedDept!'),
          backgroundColor: AppTheme.statusResolved,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter officers matching current department
    final matchingOfficers = _officers.where((o) => o.department == _selectedDept || o.isAdmin).toList();

    return AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border),
      ),
      title: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(
            'Reassign Issue #${widget.complaint.id}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Category: ${widget.complaint.category}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Department Dropdown
            const Text(
              'Target Department',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedDept,
              dropdownColor: AppTheme.bgInput,
              decoration: const InputDecoration(),
              items: _departments.map((d) {
                return DropdownMenuItem(value: d, child: Text(d));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDept = val;
                    _selectedOfficerId = null; // reset officer when department changes
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Designated Officer Dropdown
            const Text(
              'Designated Officer',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (_loadingOfficers)
              const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
            else
              DropdownButtonFormField<int?>(
                value: matchingOfficers.any((o) => o.id == _selectedOfficerId) ? _selectedOfficerId : null,
                dropdownColor: AppTheme.bgInput,
                decoration: const InputDecoration(
                  hintText: 'Select field officer (optional)',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Unassigned / Department Pool', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                  ...matchingOfficers.map((o) {
                    return DropdownMenuItem<int?>(
                      value: o.id,
                      child: Text('${o.name} (${o.role})'),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedOfficerId = val);
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save Assignment'),
        ),
      ],
    );
  }
}
