import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    // Check whether GPS/location service is enabled
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();

    // Ask the user for permission if not already granted
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
    }

    // User permanently denied permission
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Please enable it from app settings.',
      );
    }

    // Get current GPS position
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
