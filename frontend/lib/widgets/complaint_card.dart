import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/complaint.dart';
import '../constants/app_theme.dart';
import '../constants/api_constants.dart';
import '../services/location_service.dart';
import 'status_badge.dart';
import 'priority_badge.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onTap;
  final VoidCallback? onSupport;
  final bool showSupportButton;
  final double? userLat;
  final double? userLng;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
    this.onSupport,
    this.showSupportButton = true,
    this.userLat,
    this.userLng,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.getCategoryColor(complaint.category);
    final categoryIcon = AppTheme.getCategoryIcon(complaint.category);
    final reportPhoto = complaint.reportPhoto;

    String? distanceDisplay;
    if (userLat != null && userLng != null) {
      final meters = LocationService.distanceBetween(userLat!, userLng!, complaint.lat, complaint.lng);
      distanceDisplay = LocationService.formatDistance(meters);
    } else if (complaint.distanceMeters != null) {
      distanceDisplay = LocationService.formatDistance(complaint.distanceMeters!.toDouble());
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category, Dept, Time
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              complaint.category,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.bgCardHover,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                complaint.department,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _formatDate(complaint.createdAt),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            if (complaint.citizenName != null) ...[
                              const Text(' • ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              Text(
                                complaint.citizenName!,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (distanceDisplay != null) ...[
                              const Text(' • ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              Text(
                                '$distanceDisplay away',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: complaint.status, compact: true),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              // Optional photo preview
              if (reportPhoto != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    ApiConstants.resolveImageUrl(reportPhoto.url),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 80,
                      color: AppTheme.bgInput,
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_outlined, color: AppTheme.textMuted, size: 20),
                          SizedBox(width: 8),
                          Text('Photo on server', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(height: 1, color: AppTheme.border),
              const SizedBox(height: 12),

              // Footer: Priority badge, Support button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PriorityBadge(
                    priority: complaint.priority,
                    score: complaint.priorityScore,
                    compact: true,
                  ),
                  if (showSupportButton)
                    InkWell(
                      onTap: onSupport,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: complaint.hasSupported
                              ? AppTheme.primary.withOpacity(0.2)
                              : AppTheme.bgInput,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: complaint.hasSupported
                                ? AppTheme.primary
                                : AppTheme.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              complaint.hasSupported
                                  ? Icons.thumb_up_alt_rounded
                                  : Icons.thumb_up_alt_outlined,
                              size: 15,
                              color: complaint.hasSupported
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Support ${complaint.supportCount > 0 ? "(${complaint.supportCount})" : ""}',
                              style: TextStyle(
                                color: complaint.hasSupported
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
