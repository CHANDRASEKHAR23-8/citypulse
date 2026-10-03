import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../constants/app_theme.dart';
import '../../widgets/complaint_card.dart';
import 'update_status_sheet.dart';
import '../citizen/complaint_detail_screen.dart';

class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({super.key});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ComplaintProvider>(context, listen: false).fetchOfficerComplaints();
    });
  }

  void _openUpdateSheet(complaint) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateStatusSheet(complaint: complaint),
    );
    if (updated == true && mounted) {
      Provider.of<ComplaintProvider>(context, listen: false)
          .fetchOfficerComplaints(status: _selectedStatus == 'All' ? null : _selectedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<ComplaintProvider>(context);
    final user = auth.currentUser;
    final department = user?.department ?? 'General';
    final deptColor = AppTheme.getCategoryColor(
      department == 'Roads'
          ? 'Pothole'
          : (department == 'Electricity'
              ? 'Streetlight'
              : (department == 'Sanitation'
                  ? 'Garbage'
                  : (department == 'Water' ? 'Water Leakage' : 'Traffic'))),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? 'Field Officer',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: deptColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  '$department Department Console',
                  style: TextStyle(color: deptColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchOfficerComplaints(
              status: _selectedStatus == 'All' ? null : _selectedStatus,
            ),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.priorityHigh),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Department Banner & Priority Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.bgCard,
            child: Row(
              children: [
                Icon(Icons.sort_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sorted by Dynamic Priority Score (Urgent high-impact first)',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${provider.officerComplaints.length} Issues',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Status Filter Tabs
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final st = _statuses[index];
                final isSelected = _selectedStatus == st;
                final color = st == 'All' ? AppTheme.primary : AppTheme.getStatusColor(st);

                return ChoiceChip(
                  label: Text(st.replaceAll('_', ' ')),
                  selected: isSelected,
                  selectedColor: color.withOpacity(0.2),
                  backgroundColor: AppTheme.bgInput,
                  side: BorderSide(color: isSelected ? color : AppTheme.border),
                  labelStyle: TextStyle(
                    color: isSelected ? color : AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedStatus = st);
                      provider.fetchOfficerComplaints(status: st == 'All' ? null : st);
                    }
                  },
                );
              },
            ),
          ),

          // Complaints List
          Expanded(
            child: provider.isLoading && provider.officerComplaints.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.officerComplaints.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done_all_rounded, size: 56, color: AppTheme.statusResolved.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'No pending issues',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'All complaints in $department are currently resolved!',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchOfficerComplaints(
                          status: _selectedStatus == 'All' ? null : _selectedStatus,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: provider.officerComplaints.length,
                          itemBuilder: (context, index) {
                            final complaint = provider.officerComplaints[index];
                            return Column(
                              children: [
                                ComplaintCard(
                                  complaint: complaint,
                                  showSupportButton: false,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ComplaintDetailScreen(complaintId: complaint.id),
                                      ),
                                    );
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _openUpdateSheet(complaint),
                                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                                          label: Text(
                                            complaint.isResolved
                                                ? 'Update Resolution Note / Photo'
                                                : 'Update Status (Current: ${complaint.status})',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.getStatusColor(complaint.status).withOpacity(0.2),
                                            foregroundColor: AppTheme.getStatusColor(complaint.status),
                                            side: BorderSide(color: AppTheme.getStatusColor(complaint.status)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
