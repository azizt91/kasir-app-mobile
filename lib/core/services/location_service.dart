import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  /// Get the current GPS position with high accuracy.
  /// Returns null if unavailable or denied.
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

      // 3. Get current position with longer timeout for satellite fix
      //    Short timeout (5s) gives cell-tower location (~500m accuracy)
      //    Longer timeout (15s) allows GPS satellite fix (~5-10m accuracy)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, // Use best accuracy
          timeLimit: Duration(seconds: 15), // Allow enough time for GPS fix
        ),
      );

      debugPrint('GPS: Got location: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
      return position;
    } catch (e) {
      debugPrint('GPS: Error getting location: $e');
      return null;
    }
  }
}
