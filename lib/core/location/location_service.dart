import 'dart:async';

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

    // A best-accuracy fix can take a long time indoors — or never arrive — and
    // both the quest feed and the map block on this call, so an uncapped wait
    // means an endless spinner. Cap it, then fall back to the last known fix
    // before giving up: a slightly stale position still finds nearby quests.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LatLng(last.latitude, last.longitude);
      throw const LocationException(
        'Could not get a location fix. Try moving somewhere with a clearer '
        'view of the sky.',
      );
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}
