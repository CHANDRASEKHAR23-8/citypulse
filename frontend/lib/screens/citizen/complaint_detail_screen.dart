import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/api_constants.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/timeline_widget.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final int complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ComplaintProvider>(context, listen: false)
          .fetchComplaintDetail(widget.complaintId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintProvider>(context);
    final complaint = provider.currentDetail;

    if (provider.isLoading && complaint == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (complaint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Complaint not found or error loading.', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => provider.fetchComplaintDetail(widget.complaintId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final categoryColor = AppTheme.getCategoryColor(complaint.category);
    final categoryIcon = AppTheme.getCategoryIcon(complaint.category);
    final reportPhoto = complaint.reportPhoto;
    final resolutionPhoto = complaint.resolutionPhoto;

    return Scaffold(
      appBar: AppBar(
        title: Text('Complaint #${complaint.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchComplaintDetail(widget.complaintId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card: Category, Department, Status, Priority
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(categoryIcon, color: categoryColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.category,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Department: ${complaint.department}',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: complaint.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PriorityBadge(
                        priority: complaint.priority,
                        score: complaint.priorityScore,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            '${complaint.supportCount} citizen supports',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Description Section
            const Text(
              'Description',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                complaint.description,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Priority Formula Engine Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgInput,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.insights_rounded, color: AppTheme.accent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Dynamic Prioritization Engine',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score = Base (${complaint.category}) + min(Supports, 10) + (0.5 × Days Open)',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Calculated Score: ${complaint.priorityScore.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Level: ${complaint.priority}',
                        style: TextStyle(
                          color: AppTheme.getPriorityColor(complaint.priority),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Photos Section (Report & Resolution)
            if (reportPhoto != null || resolutionPhoto != null) ...[
              const Text(
                'Visual Photo Evidence',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reportPhoto != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Citizen Report Photo', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              ApiConstants.resolveImageUrl(reportPhoto.url),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: AppTheme.bgInput,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined, color: AppTheme.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (reportPhoto != null && resolutionPhoto != null) const SizedBox(width: 12),
                  if (resolutionPhoto != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Resolution Photo Proof', style: TextStyle(color: AppTheme.statusResolved, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              ApiConstants.resolveImageUrl(resolutionPhoto.url),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: AppTheme.bgInput,
                                alignment: Alignment.center,
                                child: const Icon(Icons.check_circle_outline, color: AppTheme.statusResolved),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Support Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: complaint.hasSupported
                    ? null
                    : () async {
                        final ok = await provider.supportComplaint(complaint.id);
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thank you! Your support has boosted this issue\'s urgency.'),
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                        }
                      },
                icon: Icon(
                  complaint.hasSupported ? Icons.check_rounded : Icons.thumb_up_alt_rounded,
                  size: 18,
                ),
                label: Text(
                  complaint.hasSupported
                      ? 'You Have Supported This Issue (${complaint.supportCount})'
                      : 'Support This Complaint (+1) [Currently: ${complaint.supportCount}]',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: complaint.hasSupported ? AppTheme.bgInput : AppTheme.primary,
                  foregroundColor: complaint.hasSupported ? AppTheme.textMuted : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Audit Trail / Status History
            const Text(
              'Resolution Audit Trail & Timeline',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: TimelineWidget(history: complaint.history),
            ),
          ],
        ),
      ),
    );
  }
}
