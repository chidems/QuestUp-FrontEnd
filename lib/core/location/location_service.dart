import 'package:geolocator/geolocator.dart';

/// Thrown when the current location cannot be obtained. The feed screen uses
/// [canOpenSettings] to decide whether to offer an "Open settings" action.
class LocationException implements Exception {
  final String message;
  final bool canOpenSettings;

  const LocationException(this.message, {this.canOpenSettings = false});

  @override
  String toString() => message;
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class LocationService {
  /// Returns the device's current location, requesting permission if needed.
  /// Throws [LocationException] for the disabled / denied / permanently-denied
  /// cases so the UI can show friendly, actionable messages.
  Future<LatLng> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Location services are off. Turn them on to find nearby quests.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission is needed to create nearby quests.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Enable it in settings.',
        canOpenSettings: true,
      );
    }

    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}
