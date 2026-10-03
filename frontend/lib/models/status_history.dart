class StatusHistory {
  final int id;
  final int complaintId;
  final String status;
  final String? note;
  final int changedBy;
  final String? changedByName;
  final String? changedByRole;
  final DateTime changedAt;

  StatusHistory({
    required this.id,
    required this.complaintId,
    required this.status,
    this.note,
    required this.changedBy,
    this.changedByName,
    this.changedByRole,
    required this.changedAt,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      id: json['id'] as int? ?? 0,
      complaintId: json['complaint_id'] as int? ?? 0,
      status: json['status'] as String? ?? 'ASSIGNED',
      note: json['note'] as String?,
      changedBy: json['changed_by'] as int? ?? 0,
      changedByName: json['changed_by_name'] as String?,
      changedByRole: json['changed_by_role'] as String?,
      changedAt: json['changed_at'] != null
          ? DateTime.tryParse(json['changed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
