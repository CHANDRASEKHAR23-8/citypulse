import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../models/admin_stats.dart';
import '../../constants/app_theme.dart';
import '../../widgets/complaint_card.dart';
import 'assign_dialog.dart';
import 'user_management_screen.dart';
import '../citizen/complaint_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _tabIndex = 0;
  AdminStats? _stats;
  bool _loadingStats = true;

  String _filterDept = 'All';
  String _filterStatus = 'All';

  final List<String> _departments = ['All', 'Roads', 'Electricity', 'Sanitation', 'Water', 'Traffic'];
  final List<String> _statuses = ['All', 'SUBMITTED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    setState(() => _loadingStats = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);

    try {
      final stats = await auth.apiService.getAdminStats();
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (_) {
      setState(() => _loadingStats = false);
    }

    complaintProvider.fetchAdminComplaints(
      department: _filterDept == 'All' ? null : _filterDept,
      status: _filterStatus == 'All' ? null : _filterStatus,
    );
  }

  void _openAssignDialog(complaint) async {
    final reassigned = await showDialog<bool>(
      context: context,
      builder: (_) => AssignDialog(complaint: complaint),
    );
    if (reassigned == true && mounted) {
      _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppTheme.accent),
            const SizedBox(width: 8),
            const Text('CityPulse Admin'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('COMMAND CENTER', style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboard,
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.priorityHigh),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildAnalyticsTab(),
          _buildComplaintsMonitorTab(),
          const UserManagementScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (idx) => setState(() => _tabIndex = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart_outlined),
            activeIcon: Icon(Icons.table_chart),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined),
            activeIcon: Icon(Icons.manage_accounts),
            label: 'Users',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_loadingStats && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _stats;
    if (stats == null) {
      return const Center(child: Text('Failed to load municipal statistics.'));
    }

    final resolutionRate = stats.totalComplaints > 0
        ? ((stats.resolvedCount / stats.totalComplaints) * 100).toStringAsFixed(1)
        : '0.0';

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Grid
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildKpiCard(
                  title: 'Total Complaints',
                  value: '${stats.totalComplaints}',
                  icon: Icons.list_alt_rounded,
                  color: AppTheme.primary,
                ),
                _buildKpiCard(
                  title: 'Resolved Issues',
                  value: '${stats.resolvedCount} ($resolutionRate%)',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.statusResolved,
                ),
                _buildKpiCard(
                  title: 'Avg Resolution Time',
                  value: '${stats.avgResolutionHours} hrs',
                  icon: Icons.timer_outlined,
                  color: AppTheme.accent,
                ),
                _buildKpiCard(
                  title: 'Registered Users',
                  value: '${stats.totalUsers}',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Breakdown by Status
            _buildSectionHeader('Complaints by Status Lifecycle', Icons.donut_large_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildProgressBar('SUBMITTED', stats.byStatus['SUBMITTED'] ?? 0, stats.totalComplaints, AppTheme.statusSubmitted),
                  const SizedBox(height: 12),
                  _buildProgressBar('ASSIGNED', stats.byStatus['ASSIGNED'] ?? 0, stats.totalComplaints, AppTheme.statusAssigned),
                  const SizedBox(height: 12),
                  _buildProgressBar('IN_PROGRESS', stats.byStatus['IN_PROGRESS'] ?? 0, stats.totalComplaints, AppTheme.statusInProgress),
                  const SizedBox(height: 12),
                  _buildProgressBar('RESOLVED', stats.byStatus['RESOLVED'] ?? 0, stats.totalComplaints, AppTheme.statusResolved),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Breakdown by Department
            _buildSectionHeader('Workload by Municipal Department', Icons.business_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: stats.byDepartment.map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildProgressBar(
                      d.department,
                      d.count,
                      stats.totalComplaints,
                      AppTheme.getCategoryColor(
                        d.department == 'Roads'
                            ? 'Pothole'
                            : (d.department == 'Electricity'
                                ? 'Streetlight'
                                : (d.department == 'Sanitation'
                                    ? 'Garbage'
                                    : (d.department == 'Water' ? 'Water Leakage' : 'Traffic'))),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Breakdown by Category
            _buildSectionHeader('Reports by Issue Category', Icons.category_rounded),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: stats.byCategory.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildProgressBar(
                      c.category,
                      c.count,
                      stats.totalComplaints,
                      AppTheme.getCategoryColor(c.category),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsMonitorTab() {
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    return Column(
      children: [
        // Filter bar (Department & Status)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.bgCard,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterDept,
                  decoration: const InputDecoration(labelText: 'Department', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  dropdownColor: AppTheme.bgInput,
                  items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _filterDept = val);
                      complaintProvider.fetchAdminComplaints(
                        department: val == 'All' ? null : val,
                        status: _filterStatus == 'All' ? null : _filterStatus,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: const InputDecoration(labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  dropdownColor: AppTheme.bgInput,
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '), style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _filterStatus = val);
                      complaintProvider.fetchAdminComplaints(
                        department: _filterDept == 'All' ? null : _filterDept,
                        status: val == 'All' ? null : val,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: complaintProvider.isLoading && complaintProvider.adminComplaints.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : complaintProvider.adminComplaints.isEmpty
                  ? const Center(child: Text('No complaints matching criteria.'))
                  : RefreshIndicator(
                      onRefresh: () => complaintProvider.fetchAdminComplaints(
                        department: _filterDept == 'All' ? null : _filterDept,
                        status: _filterStatus == 'All' ? null : _filterStatus,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: complaintProvider.adminComplaints.length,
                        itemBuilder: (context, index) {
                          final complaint = complaintProvider.adminComplaints[index];
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
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openAssignDialog(complaint),
                                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                        label: Text('Reassign Dept / Officer (${complaint.department})'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          textStyle: const TextStyle(fontSize: 12),
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
    );
  }

  Widget _buildKpiCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('$count (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppTheme.bgInput,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
