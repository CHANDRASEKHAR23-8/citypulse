import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';
import '../../constants/app_theme.dart';
import '../citizen/complaint_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (provider.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton.icon(
              onPressed: () => provider.markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchNotifications(),
          ),
        ],
      ),
      body: provider.isLoading && provider.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 56, color: AppTheme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'You will receive updates whenever the status of your complaints changes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchNotifications(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: provider.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notif = provider.notifications[index];
                      final categoryColor = notif.category != null
                          ? AppTheme.getCategoryColor(notif.category!)
                          : AppTheme.primary;

                      return InkWell(
                        onTap: () {
                          if (!notif.isRead) {
                            provider.markAsRead(notif.id);
                          }
                          if (notif.complaintId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ComplaintDetailScreen(complaintId: notif.complaintId!),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: notif.isRead ? AppTheme.bgCard : AppTheme.bgCardHover.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: notif.isRead ? AppTheme.border : AppTheme.primary.withOpacity(0.5),
                              width: notif.isRead ? 1 : 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  notif.category != null
                                      ? AppTheme.getCategoryIcon(notif.category!)
                                      : Icons.notifications_rounded,
                                  color: categoryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (notif.category != null)
                                          Text(
                                            notif.category!,
                                            style: TextStyle(
                                              color: categoryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        else
                                          const Text(
                                            'City Notification',
                                            style: TextStyle(
                                              color: AppTheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        Text(
                                          DateFormat('MMM d • h:mm a').format(notif.createdAt),
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      notif.message,
                                      style: TextStyle(
                                        color: notif.isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                                        fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!notif.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
