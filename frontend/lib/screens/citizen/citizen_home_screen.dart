import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/notification_provider.dart';
import '../../constants/app_theme.dart';
import '../../services/location_service.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/city_map_view.dart';
import 'report_screen.dart';
import 'complaint_detail_screen.dart';
import 'my_complaints_screen.dart';
import '../notifications/notifications_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _currentIndex = 0;
  bool _isMapView = false;
  double? _userLat;
  double? _userLng;

  final List<String> _categories = ['All', 'Pothole', 'Streetlight', 'Garbage', 'Water Leakage', 'Traffic'];
  final List<String> _statuses = ['All', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ComplaintProvider>(context, listen: false).fetchComplaints();
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
      _fetchUserLocation();
    });
  }

  Future<void> _fetchUserLocation() async {
    final res = await LocationService.getCurrentLocation(context: context);
    if (mounted) {
      setState(() {
        _userLat = res.latitude;
        _userLng = res.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);

    final pages = [
      _buildExploreView(),
      const MyComplaintsScreen(),
      const NotificationsScreen(),
      _buildProfileView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'My Reports',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (notifProvider.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.priorityHigh,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportScreen()),
                );
              },
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildExploreView() {
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.location_city_rounded, color: AppTheme.primary, size: 24),
            const SizedBox(width: 8),
            const Text('CityPulse'),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Live', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          // Toggle Map / List
          IconButton(
            tooltip: _isMapView ? 'Switch to List View' : 'Switch to City Map View',
            icon: Icon(_isMapView ? Icons.view_list_rounded : Icons.map_rounded),
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => complaintProvider.fetchComplaints(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bars (Categories)
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = complaintProvider.selectedCategory == cat;
                final catColor = cat == 'All' ? AppTheme.primary : AppTheme.getCategoryColor(cat);

                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: catColor.withOpacity(0.2),
                  backgroundColor: AppTheme.bgCard,
                  side: BorderSide(
                    color: isSelected ? catColor : AppTheme.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? catColor : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                  onSelected: (_) => complaintProvider.setFilterCategory(cat),
                );
              },
            ),
          ),

          // Status Filter Strip
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final st = _statuses[index];
                final isSelected = complaintProvider.selectedStatus == st;
                final stColor = st == 'All' ? AppTheme.textSecondary : AppTheme.getStatusColor(st);

                return ActionChip(
                  label: Text(st.replaceAll('_', ' ')),
                  backgroundColor: isSelected ? stColor.withOpacity(0.2) : AppTheme.bgInput,
                  side: BorderSide(
                    color: isSelected ? stColor : Colors.transparent,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? stColor : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onPressed: () => complaintProvider.setFilterStatus(st),
                );
              },
            ),
          ),

          // Main View Area: List or Vector City Map
          Expanded(
            child: _isMapView
                ? CityMapView(
                    complaints: complaintProvider.complaints,
                    userLat: _userLat,
                    userLng: _userLng,
                    onRecenter: _fetchUserLocation,
                    onComplaintSelected: (complaint) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComplaintDetailScreen(complaintId: complaint.id),
                        ),
                      );
                    },
                  )
                : complaintProvider.isLoading && complaintProvider.complaints.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : complaintProvider.complaints.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 52, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No open issues matching filter',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              final sortedComplaints = List<Complaint>.from(complaintProvider.complaints);
                              final uLat = _userLat;
                              final uLng = _userLng;
                              if (uLat != null && uLng != null) {
                                sortedComplaints.sort((Complaint a, Complaint b) {
                                  final distA = LocationService.distanceBetween(uLat, uLng, a.lat, a.lng);
                                  final distB = LocationService.distanceBetween(uLat, uLng, b.lat, b.lng);
                                  return distA.compareTo(distB);
                                });
                              }

                              return RefreshIndicator(
                                onRefresh: () => complaintProvider.fetchComplaints(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 80),
                                  itemCount: sortedComplaints.length,
                                  itemBuilder: (context, index) {
                                    final complaint = sortedComplaints[index];
                                    return ComplaintCard(
                                      complaint: complaint,
                                      userLat: _userLat,
                                      userLng: _userLng,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ComplaintDetailScreen(complaintId: complaint.id),
                                          ),
                                        );
                                      },
                                      onSupport: () async {
                                        final ok = await complaintProvider.supportComplaint(complaint.id);
                                        if (ok && mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Supported complaint #${complaint.id}! Priority boosted.'),
                                              backgroundColor: AppTheme.primary,
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Citizen Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Citizen',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ROLE: ${user?.role.toUpperCase() ?? "CITIZEN"}',
                            style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => auth.logout(),
                icon: const Icon(Icons.logout_rounded, color: AppTheme.priorityHigh),
                label: const Text('Sign Out', style: TextStyle(color: AppTheme.priorityHigh)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.priorityHigh),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
