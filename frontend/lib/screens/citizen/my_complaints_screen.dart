import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../constants/app_theme.dart';
import '../../widgets/complaint_card.dart';
import 'complaint_detail_screen.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ComplaintProvider>(context, listen: false).fetchMyComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reported Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchMyComplaints(),
          ),
        ],
      ),
      body: provider.isLoading && provider.myComplaints.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.myComplaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 56, color: AppTheme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No issues reported yet',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Help improve your city by reporting urban problems.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchMyComplaints(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.myComplaints.length,
                    itemBuilder: (context, index) {
                      final complaint = provider.myComplaints[index];
                      return ComplaintCard(
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
                      );
                    },
                  ),
                ),
    );
  }
}
