import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';
import '../models/user.dart';
import '../models/complaint.dart';
import '../models/notification_item.dart';
import '../models/admin_stats.dart';

class DuplicateException implements Exception {
  final String message;
  final Complaint duplicate;

  DuplicateException(this.message, this.duplicate);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, [this.statusCode = 0]);

  @override
  String toString() => message;
}

class ApiService {
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  // --- AUTH ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      setToken(token);
      return {'token': token, 'user': user};
    } else {
      throw ApiException(data['error'] ?? 'Login failed', response.statusCode);
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'citizen',
    String? department,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'department': department,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      setToken(token);
      return {'token': token, 'user': user};
    } else {
      throw ApiException(data['error'] ?? 'Registration failed', response.statusCode);
    }
  }

  // --- COMPLAINTS ---

  Future<List<Complaint>> getComplaints({
    double? lat,
    double? lng,
    double? radius,
    String? category,
    String? status,
    String? department,
  }) async {
    final queryParams = <String, String>{};
    if (lat != null && lng != null && radius != null) {
      queryParams['lat'] = lat.toString();
      queryParams['lng'] = lng.toString();
      queryParams['radius'] = radius.toString();
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams['status'] = status;
    }
    if (department != null && department.isNotEmpty && department != 'All') {
      queryParams['department'] = department;
    }

    final uri = Uri.parse(ApiConstants.complaints).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: _headers);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['complaints'] as List).map((c) => Complaint.fromJson(c as Map<String, dynamic>)).toList();
    } else {
      throw ApiException(data['error'] ?? 'Failed to load complaints', response.statusCode);
    }
  }

  Future<List<Complaint>> getMyComplaints() async {
    final response = await http.get(
      Uri.parse(ApiConstants.myComplaints),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['complaints'] as List).map((c) => Complaint.fromJson(c as Map<String, dynamic>)).toList();
    } else {
      throw ApiException(data['error'] ?? 'Failed to load my complaints', response.statusCode);
    }
  }

  Future<Complaint> getComplaint(int id) async {
    final response = await http.get(
      Uri.parse(ApiConstants.complaintDetail(id)),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Complaint.fromJson(data['complaint'] as Map<String, dynamic>);
    } else {
      throw ApiException(data['error'] ?? 'Failed to load complaint details', response.statusCode);
    }
  }

  Future<Complaint> reportComplaint({
    required String category,
    required String description,
    required double lat,
    required double lng,
    Uint8List? imageBytes,
    String? imageName,
    bool force = false,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.complaints));
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.fields['category'] = category;
    request.fields['description'] = description;
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    if (force) {
      request.fields['force'] = 'true';
    }

    if (imageBytes != null && imageBytes.isNotEmpty) {
      final multipartFile = http.MultipartFile.fromBytes(
        'photo',
        imageBytes,
        filename: imageName ?? 'report_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 409 && data['duplicateFound'] == true) {
      final duplicate = Complaint.fromJson(data['duplicate'] as Map<String, dynamic>);
      throw DuplicateException(data['error'] ?? 'Potential duplicate issue found', duplicate);
    }

    if (response.statusCode == 201 && data['success'] == true) {
      return Complaint.fromJson(data['complaint'] as Map<String, dynamic>);
    } else {
      throw ApiException(data['error'] ?? 'Failed to submit complaint', response.statusCode);
    }
  }

  Future<Complaint> supportComplaint(int id) async {
    final response = await http.post(
      Uri.parse(ApiConstants.supportComplaint(id)),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Complaint.fromJson(data['complaint'] as Map<String, dynamic>);
    } else {
      throw ApiException(data['error'] ?? 'Failed to support complaint', response.statusCode);
    }
  }

  Future<Complaint> updateStatus(
    int id, {
    required String status,
    String? note,
    Uint8List? resolutionImageBytes,
    String? resolutionImageName,
  }) async {
    final request = http.MultipartRequest('PATCH', Uri.parse(ApiConstants.updateStatus(id)));
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.fields['status'] = status;
    if (note != null && note.isNotEmpty) {
      request.fields['note'] = note;
    }

    if (resolutionImageBytes != null && resolutionImageBytes.isNotEmpty) {
      final multipartFile = http.MultipartFile.fromBytes(
        'photo',
        resolutionImageBytes,
        filename: resolutionImageName ?? 'resolution_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Complaint.fromJson(data['complaint'] as Map<String, dynamic>);
    } else {
      throw ApiException(data['error'] ?? 'Failed to update status', response.statusCode);
    }
  }

  // --- OFFICER ---

  Future<List<Complaint>> getOfficerComplaints({String? status, bool onlyMine = false}) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams['status'] = status;
    }
    if (onlyMine) {
      queryParams['onlyMine'] = 'true';
    }

    final uri = Uri.parse(ApiConstants.officerComplaints).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: _headers);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['complaints'] as List).map((c) => Complaint.fromJson(c as Map<String, dynamic>)).toList();
    } else {
      throw ApiException(data['error'] ?? 'Failed to load officer complaints', response.statusCode);
    }
  }

  // --- ADMIN ---

  Future<List<Complaint>> getAdminComplaints({String? department, String? category, String? status}) async {
    final queryParams = <String, String>{};
    if (department != null && department.isNotEmpty && department != 'All') {
      queryParams['department'] = department;
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams['status'] = status;
    }

    final uri = Uri.parse(ApiConstants.adminComplaints).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: _headers);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['complaints'] as List).map((c) => Complaint.fromJson(c as Map<String, dynamic>)).toList();
    } else {
      throw ApiException(data['error'] ?? 'Failed to load admin complaints', response.statusCode);
    }
  }

  Future<Complaint> adminAssign(int id, {String? department, int? officerId}) async {
    final body = <String, dynamic>{};
    if (department != null) body['department'] = department;
    if (officerId != null) body['officer_id'] = officerId;

    final response = await http.patch(
      Uri.parse(ApiConstants.adminAssign(id)),
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Complaint.fromJson(data['complaint'] as Map<String, dynamic>);
    } else {
      throw ApiException(data['error'] ?? 'Failed to assign complaint', response.statusCode);
    }
  }

  Future<List<User>> getAdminUsers() async {
    final response = await http.get(
      Uri.parse(ApiConstants.adminUsers),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['users'] as List).map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
    } else {
      throw ApiException(data['error'] ?? 'Failed to load users', response.statusCode);
    }
  }

  Future<User> adminUpdateUser(int id, {String? role, String? department}) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.adminUpdateUser(id)),
      headers: _headers,
      body: jsonEncode({'role': role, 'department': department}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return User.fromJson(data['user'] as Map<String, dynamic>);
    } else {
      throw ApiException(data['error'] ?? 'Failed to update user', response.statusCode);
    }
  }

  Future<AdminStats> getAdminStats() async {
    final response = await http.get(
      Uri.parse(ApiConstants.adminStats),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return AdminStats.fromJson(data['stats'] as Map<String, dynamic>);
    } else {
      throw ApiException(data['error'] ?? 'Failed to load stats', response.statusCode);
    }
  }

  // --- NOTIFICATIONS ---

  Future<Map<String, dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse(ApiConstants.notifications),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final list = (data['notifications'] as List)
          .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
          .toList();
      return {
        'unreadCount': data['unreadCount'] as int? ?? 0,
        'notifications': list,
      };
    } else {
      throw ApiException(data['error'] ?? 'Failed to load notifications', response.statusCode);
    }
  }

  Future<void> readNotification(int id) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.readNotification(id)),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['error'] ?? 'Failed to mark notification read', response.statusCode);
    }
  }

  Future<void> readAllNotifications() async {
    final response = await http.patch(
      Uri.parse(ApiConstants.readAllNotifications),
      headers: _headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw ApiException(data['error'] ?? 'Failed to mark all read', response.statusCode);
    }
  }
}
