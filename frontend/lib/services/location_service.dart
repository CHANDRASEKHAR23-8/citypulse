import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_theme.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final bool isDefaultFallback;
  final String? errorMessage;

  LocationResult({
    required this.latitude,
    required this.longitude,
    this.isDefaultFallback = false,
    this.errorMessage,
  });
}

class LocationService {
  // Default fallback coordinates if GPS fails (as specified: 16.5062, 80.6480)
  static const double defaultLat = 16.5062;
  static const double defaultLng = 80.6480;
  static const String defaultCityName = 'Vijayawada Central';

  /// Obtains current GPS position with permission checks and a 10-second timeout.
  /// If context is provided, shows appropriate friendly SnackBars for permission states.
  static Future<LocationResult> getCurrentLocation({BuildContext? context}) async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services are turned off. Using default city center (16.5062, 80.6480).'),
              backgroundColor: AppTheme.priorityMedium,
              action: SnackBarAction(
                label: 'Open Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return LocationResult(
          latitude: defaultLat,
          longitude: defaultLng,
          isDefaultFallback: true,
          errorMessage: 'Location services disabled',
        );
      }

      // 2. Check and request permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied. Using default city center (16.5062, 80.6480).'),
                backgroundColor: AppTheme.priorityMedium,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return LocationResult(
            latitude: defaultLat,
            longitude: defaultLng,
            isDefaultFallback: true,
            errorMessage: 'Location permission denied',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permissions permanently denied. Using default center (16.5062, 80.6480).'),
              backgroundColor: AppTheme.priorityHigh,
              action: SnackBarAction(
                label: 'Open Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return LocationResult(
          latitude: defaultLat,
          longitude: defaultLng,
          isDefaultFallback: true,
          errorMessage: 'Location permission denied forever',
        );
      }

      // 3. Obtain position with 10-second timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        isDefaultFallback: false,
      );
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS signal unavailable ($e). Centering on default location (16.5062, 80.6480).'),
            backgroundColor: AppTheme.priorityMedium,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return LocationResult(
        latitude: defaultLat,
        longitude: defaultLng,
        isDefaultFallback: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// Calculates geodesic distance in meters between two lat/lng pairs
  static double distanceBetween(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Formats meters into human-readable string ("120 m" or "2.4 km")
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}
