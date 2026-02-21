import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  /// Get the current GPS position. Returns null if unavailable or denied.
  /// This method is designed to be non-blocking and optional —
  /// if location cannot be obtained, it returns null silently.
  static Future<Position?> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GPS: Location services are disabled');
        return null;
      }

      // 2. Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('GPS: Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('GPS: Location permission permanently denied');
        return null;
      }

      // 3. Get position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      debugPrint('GPS: Got location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('GPS: Error getting location: $e');
      return null;
    }
  }
}
