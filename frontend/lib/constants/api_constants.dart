import 'package:flutter/foundation.dart';

class ApiConstants {
  // If running in Android emulator use 10.0.2.2, for Chrome/Desktop/iOS use localhost
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    return 'http://127.0.0.1:3000';
  }

  // Auth endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';

  // Complaints endpoints
  static String get complaints => '$baseUrl/complaints';
  static String get myComplaints => '$baseUrl/complaints/mine';
  static String complaintDetail(int id) => '$baseUrl/complaints/$id';
  static String supportComplaint(int id) => '$baseUrl/complaints/$id/support';
  static String updateStatus(int id) => '$baseUrl/complaints/$id/status';

  // Officer endpoints
  static String get officerComplaints => '$baseUrl/officer/complaints';

  // Admin endpoints
  static String get adminComplaints => '$baseUrl/admin/complaints';
  static String adminAssign(int id) => '$baseUrl/admin/complaints/$id/assign';
  static String get adminUsers => '$baseUrl/admin/users';
  static String adminUpdateUser(int id) => '$baseUrl/admin/users/$id';
  static String get adminStats => '$baseUrl/admin/stats';

  // Notifications endpoints
  static String get notifications => '$baseUrl/notifications';
  static String readNotification(int id) => '$baseUrl/notifications/$id/read';
  static String get readAllNotifications => '$baseUrl/notifications/read-all';

  // Image URL resolver
  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }
}
