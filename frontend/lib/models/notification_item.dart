class NotificationItem {
  final int id;
  final int userId;
  final int? complaintId;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? category;
  final String? complaintStatus;

  NotificationItem({
    required this.id,
    required this.userId,
    this.complaintId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.category,
    this.complaintStatus,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      complaintId: json['complaint_id'] as int?,
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      category: json['category'] as String?,
      complaintStatus: json['complaint_status'] as String?,
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      userId: userId,
      complaintId: complaintId,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      category: category,
      complaintStatus: complaintStatus,
    );
  }
}
