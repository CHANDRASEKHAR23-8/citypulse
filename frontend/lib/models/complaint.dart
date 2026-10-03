import 'complaint_photo.dart';
import 'status_history.dart';

class Complaint {
  final int id;
  final int citizenId;
  final String? citizenName;
  final String? citizenEmail;
  final String category;
  final String description;
  final double lat;
  final double lng;
  final String status; // SUBMITTED, ASSIGNED, IN_PROGRESS, RESOLVED
  final String priority; // LOW, MEDIUM, HIGH
  final double priorityScore;
  final String department;
  final int? officerId;
  final String? officerName;
  final int supportCount;
  final bool hasSupported;
  final DateTime createdAt;
  final int? distanceMeters;
  final List<ComplaintPhoto> photos;
  final List<StatusHistory> history;

  Complaint({
    required this.id,
    required this.citizenId,
    this.citizenName,
    this.citizenEmail,
    required this.category,
    required this.description,
    required this.lat,
    required this.lng,
    required this.status,
    required this.priority,
    required this.priorityScore,
    required this.department,
    this.officerId,
    this.officerName,
    required this.supportCount,
    this.hasSupported = false,
    required this.createdAt,
    this.distanceMeters,
    this.photos = const [],
    this.history = const [],
  });

  bool get isResolved => status == 'RESOLVED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isAssigned => status == 'ASSIGNED';

  ComplaintPhoto? get reportPhoto {
    final list = photos.where((p) => p.isReport).toList();
    return list.isNotEmpty ? list.first : null;
  }

  ComplaintPhoto? get resolutionPhoto {
    final list = photos.where((p) => p.isResolution).toList();
    return list.isNotEmpty ? list.first : null;
  }

  factory Complaint.fromJson(Map<String, dynamic> json) {
    List<ComplaintPhoto> parsedPhotos = [];
    if (json['photos'] != null && json['photos'] is List) {
      parsedPhotos = (json['photos'] as List)
          .map((p) => ComplaintPhoto.fromJson(p as Map<String, dynamic>))
          .toList();
    } else if (json['photo_url'] != null) {
      parsedPhotos.add(ComplaintPhoto(
        id: 0,
        complaintId: json['id'] as int? ?? 0,
        url: json['photo_url'] as String,
        type: 'report',
      ));
    }

    List<StatusHistory> parsedHistory = [];
    if (json['history'] != null && json['history'] is List) {
      parsedHistory = (json['history'] as List)
          .map((h) => StatusHistory.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    return Complaint(
      id: json['id'] as int? ?? 0,
      citizenId: json['citizen_id'] as int? ?? 0,
      citizenName: json['citizen_name'] as String?,
      citizenEmail: json['citizen_email'] as String?,
      category: json['category'] as String? ?? 'Other',
      description: json['description'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ASSIGNED',
      priority: json['priority'] as String? ?? 'LOW',
      priorityScore: (json['priority_score'] as num?)?.toDouble() ?? 0.0,
      department: json['department'] as String? ?? 'General',
      officerId: json['officer_id'] as int?,
      officerName: json['officer_name'] as String?,
      supportCount: (json['support_count'] as num?)?.toInt() ?? 0,
      hasSupported: json['has_supported'] == true || json['has_supported'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      distanceMeters: (json['distance_meters'] as num?)?.toInt() ?? (json['distanceMeters'] as num?)?.toInt(),
      photos: parsedPhotos,
      history: parsedHistory,
    );
  }

  Complaint copyWith({
    int? supportCount,
    bool? hasSupported,
    double? priorityScore,
    String? priority,
    String? status,
    List<ComplaintPhoto>? photos,
    List<StatusHistory>? history,
  }) {
    return Complaint(
      id: id,
      citizenId: citizenId,
      citizenName: citizenName,
      citizenEmail: citizenEmail,
      category: category,
      description: description,
      lat: lat,
      lng: lng,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      priorityScore: priorityScore ?? this.priorityScore,
      department: department,
      officerId: officerId,
      officerName: officerName,
      supportCount: supportCount ?? this.supportCount,
      hasSupported: hasSupported ?? this.hasSupported,
      createdAt: createdAt,
      distanceMeters: distanceMeters,
      photos: photos ?? this.photos,
      history: history ?? this.history,
    );
  }
}
