import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../constants/app_theme.dart';
import '../constants/api_constants.dart';
import 'status_badge.dart';

class DuplicateDialog extends StatelessWidget {
  final Complaint duplicate;
  final VoidCallback onSupport;
  final VoidCallback onForceSubmit;

  const DuplicateDialog({
    super.key,
    required this.duplicate,
    required this.onSupport,
    required this.onForceSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final photo = duplicate.reportPhoto;

    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Warning
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.priorityMedium.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.copy_all_rounded,
                    color: AppTheme.priorityMedium,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Similar Issue Detected',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Within 50 meters of your report',
                        style: TextStyle(
                          color: AppTheme.priorityMedium,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Card preview of existing issue
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgInput,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        duplicate.category,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      StatusBadge(status: duplicate.status, compact: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    duplicate.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (duplicate.distanceMeters != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${duplicate.distanceMeters}m away from your selected pin',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (photo != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ApiConstants.resolveImageUrl(photo.url),
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Supporting an existing complaint increases its priority score so municipal crews resolve it faster!',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),

            // Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onSupport();
                  },
                  icon: const Icon(Icons.thumb_up_alt_rounded, size: 18),
                  label: Text('Support This Issue (+1) [Total: ${duplicate.supportCount}]'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onForceSubmit();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('No, Submit As Distinct Problem'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
