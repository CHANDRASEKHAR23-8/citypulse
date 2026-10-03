class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'citizen', 'officer', 'admin'
  final String? department;
  final String? createdAt;
  final int complaintsReported;
  final int complaintsAssigned;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.createdAt,
    this.complaintsReported = 0,
    this.complaintsAssigned = 0,
  });

  bool get isCitizen => role == 'citizen';
  bool get isOfficer => role == 'officer';
  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'citizen',
      department: json['department'] as String?,
      createdAt: json['created_at'] as String?,
      complaintsReported: (json['complaints_reported'] as num?)?.toInt() ?? 0,
      complaintsAssigned: (json['complaints_assigned'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'created_at': createdAt,
    };
  }
}
