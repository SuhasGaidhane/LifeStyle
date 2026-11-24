import 'package:geolocator/geolocator.dart';

/// Result of a location detection attempt.
class DetectedLocation {
  final double latitude;
  final double longitude;
  const DetectedLocation(this.latitude, this.longitude);
}

/// Detects the device's current GPS position.
///
/// Handles: location-services-off, permission-denied, and
/// permanently-denied. Throws a [LocationException] with a friendly
/// message the caller can show; returns the coordinates on success.
Future<DetectedLocation> detectCurrentLocation() async {
  // 1. Location services enabled?
  final serviceOn = await Geolocator.isLocationServiceEnabled();
  if (!serviceOn) {
    throw const LocationException(
        'Location is turned off. Please enable GPS and try again.');
  }

  // 2. Permission.
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw const LocationException('Location permission was denied.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationException(
        'Location permission is permanently denied. Enable it in app settings.');
  }

  // 3. Fetch position.
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
  return DetectedLocation(pos.latitude, pos.longitude);
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
  @override
  String toString() => message;
}
