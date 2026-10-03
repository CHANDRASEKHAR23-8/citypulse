import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/status_history.dart';
import '../constants/app_theme.dart';
import 'status_badge.dart';

class TimelineWidget extends StatelessWidget {
  final List<StatusHistory> history;

  const TimelineWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Text(
            'No status history recorded yet.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(history.length, (index) {
        final item = history[index];
        final isLast = index == history.length - 1;
        final statusColor = AppTheme.getStatusColor(item.status);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and dot
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppTheme.border,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(status: item.status, compact: true),
                          const Spacer(),
                          Text(
                            DateFormat('MMM d, y • h:mm a').format(item.changedAt),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (item.note != null && item.note!.isNotEmpty)
                        Text(
                          item.note!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      if (item.changedByName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Updated by ${item.changedByName} (${item.changedByRole ?? "Staff"})',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
