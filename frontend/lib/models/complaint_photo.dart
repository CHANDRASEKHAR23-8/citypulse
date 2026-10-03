class ComplaintPhoto {
  final int id;
  final int complaintId;
  final String url;
  final String type; // 'report' or 'resolution'

  ComplaintPhoto({
    required this.id,
    required this.complaintId,
    required this.url,
    required this.type,
  });

  bool get isResolution => type == 'resolution';
  bool get isReport => type == 'report';

  factory ComplaintPhoto.fromJson(Map<String, dynamic> json) {
    return ComplaintPhoto(
      id: json['id'] as int? ?? 0,
      complaintId: json['complaint_id'] as int? ?? 0,
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? 'report',
    );
  }
}
