import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService apiService;

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  NotificationProvider({required this.apiService});

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await apiService.getNotifications();
      _unreadCount = res['unreadCount'] as int;
      _notifications = res['notifications'] as List<NotificationItem>;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await apiService.readNotification(id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !_notifications[idx].isRead) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await apiService.readAllNotifications();
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
