import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/complaint.dart';
import '../services/api_service.dart';

class ComplaintProvider with ChangeNotifier {
  final ApiService apiService;

  List<Complaint> _complaints = [];
  List<Complaint> _myComplaints = [];
  List<Complaint> _officerComplaints = [];
  List<Complaint> _adminComplaints = [];
  Complaint? _currentDetail;

  bool _isLoading = false;
  String? _errorMessage;

  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  ComplaintProvider({required this.apiService});

  List<Complaint> get complaints => _complaints;
  List<Complaint> get myComplaints => _myComplaints;
  List<Complaint> get officerComplaints => _officerComplaints;
  List<Complaint> get adminComplaints => _adminComplaints;
  Complaint? get currentDetail => _currentDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedCategory => _selectedCategory;
  String get selectedStatus => _selectedStatus;

  void setFilterCategory(String category) {
    _selectedCategory = category;
    fetchComplaints();
  }

  void setFilterStatus(String status) {
    _selectedStatus = status;
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _complaints = await apiService.getComplaints(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        status: _selectedStatus == 'All' ? null : _selectedStatus,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchMyComplaints() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myComplaints = await apiService.getMyComplaints();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchComplaintDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDetail = await apiService.getComplaint(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<Complaint?> submitComplaint({
    required String category,
    required String description,
    required double lat,
    required double lng,
    Uint8List? imageBytes,
    String? imageName,
    bool force = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final complaint = await apiService.reportComplaint(
        category: category,
        description: description,
        lat: lat,
        lng: lng,
        imageBytes: imageBytes,
        imageName: imageName,
        force: force,
      );

      _complaints.insert(0, complaint);
      _myComplaints.insert(0, complaint);
      _isLoading = false;
      notifyListeners();
      return complaint;
    } on DuplicateException {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> supportComplaint(int id) async {
    try {
      final updated = await apiService.supportComplaint(id);

      // Update in main list
      final index = _complaints.indexWhere((c) => c.id == id);
      if (index != -1) {
        _complaints[index] = updated;
      }

      // Update in detail if viewed
      if (_currentDetail?.id == id) {
        _currentDetail = updated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(
    int id, {
    required String status,
    String? note,
    Uint8List? resolutionImageBytes,
    String? resolutionImageName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await apiService.updateStatus(
        id,
        status: status,
        note: note,
        resolutionImageBytes: resolutionImageBytes,
        resolutionImageName: resolutionImageName,
      );

      // Update in officer complaints
      final offIdx = _officerComplaints.indexWhere((c) => c.id == id);
      if (offIdx != -1) {
        _officerComplaints[offIdx] = updated;
      }

      // Update in general list
      final gIdx = _complaints.indexWhere((c) => c.id == id);
      if (gIdx != -1) {
        _complaints[gIdx] = updated;
      }

      if (_currentDetail?.id == id) {
        _currentDetail = updated;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchOfficerComplaints({String? status, bool onlyMine = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _officerComplaints = await apiService.getOfficerComplaints(status: status, onlyMine: onlyMine);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAdminComplaints({String? department, String? category, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _adminComplaints = await apiService.getAdminComplaints(
        department: department,
        category: category,
        status: status,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> assignComplaint(int id, {String? department, int? officerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await apiService.adminAssign(id, department: department, officerId: officerId);
      final index = _adminComplaints.indexWhere((c) => c.id == id);
      if (index != -1) {
        _adminComplaints[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
