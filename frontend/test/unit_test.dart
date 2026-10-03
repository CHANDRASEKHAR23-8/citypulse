import 'package:flutter_test/flutter_test.dart';
import 'package:citypulse/services/location_service.dart';
import 'package:citypulse/models/complaint.dart';

void main() {
  group('LocationService tests', () {
    test('Default fallback coordinates are set to Vijayawada Central', () {
      expect(LocationService.defaultLat, 16.5062);
      expect(LocationService.defaultLng, 80.6480);
    });

    test('Distance formatting formats meters and kilometers properly', () {
      expect(LocationService.formatDistance(50), '50 m');
      expect(LocationService.formatDistance(999), '999 m');
      expect(LocationService.formatDistance(1000), '1.0 km');
      expect(LocationService.formatDistance(2450), '2.5 km');
      expect(LocationService.formatDistance(15300), '15.3 km');
    });

    test('Haversine distance calculation produces accurate geodesic distance', () {
      // Distance between 16.5062, 80.6480 and 16.5162, 80.6480 (~1.1 km)
      final meters = LocationService.distanceBetween(16.5062, 80.6480, 16.5162, 80.6480);
      expect(meters, greaterThan(1000));
      expect(meters, lessThan(1200));
    });
  });

  group('Complaint Model tests', () {
    test('Complaint parses from JSON correctly', () {
      final json = {
        'id': 101,
        'citizen_id': 5,
        'citizen_name': 'Test Citizen',
        'citizen_email': 'citizen@example.com',
        'category': 'Pothole',
        'description': 'Test crater on road',
        'lat': 16.5062,
        'lng': 80.6480,
        'status': 'ASSIGNED',
        'priority': 'HIGH',
        'priority_score': 8.5,
        'department': 'Roads',
        'support_count': 3,
        'has_supported': false,
        'created_at': DateTime.now().toIso8601String(),
        'photos': [],
        'history': [],
      };

      final complaint = Complaint.fromJson(json);
      expect(complaint.id, 101);
      expect(complaint.category, 'Pothole');
      expect(complaint.department, 'Roads');
      expect(complaint.priority, 'HIGH');
      expect(complaint.priorityScore, 8.5);
      expect(complaint.lat, 16.5062);
      expect(complaint.lng, 80.6480);
      expect(complaint.isResolved, false);
    });
  });
}
