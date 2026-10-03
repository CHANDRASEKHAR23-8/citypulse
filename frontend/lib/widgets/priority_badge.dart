import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final double? score;
  final bool compact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.score,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getPriorityColor(priority);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priority.toUpperCase() == 'HIGH'
                ? Icons.local_fire_department_rounded
                : (priority.toUpperCase() == 'MEDIUM'
                    ? Icons.trending_up_rounded
                    : Icons.low_priority_rounded),
            size: compact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: compact ? 3 : 5),
          Text(
            score != null
                ? '$priority (${score!.toStringAsFixed(1)})'
                : priority,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
