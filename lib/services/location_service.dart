import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Structured enum representing reasons for location failures.
enum LocationFailureReason {
  /// Device GPS / location services are disabled in system settings.
  serviceDisabled,

  /// Location permission was denied by the user.
  permissionDenied,

  /// Location permission was permanently denied by the user ("Don't ask again").
  permissionDeniedForever,

  /// GPS signal or location is unavailable (e.g. timeout or hardware failure).
  locationUnavailable,

  /// An unexpected or unknown error occurred.
  unknown,
}

/// Custom exception thrown by [LocationService] with a clear [LocationFailureReason].
class LocationServiceException implements Exception {
  final LocationFailureReason reason;
  final String message;

  const LocationServiceException(this.reason, this.message);

  @override
  String toString() => 'LocationServiceException($reason): $message';
}

/// A lightweight coordinate model representing latitude and longitude.
class LocationCoordinates {
  final double latitude;
  final double longitude;

  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationCoordinates &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'LocationCoordinates(lat: $latitude, lng: $longitude)';
}

/// Modular service responsible for device GPS location retrieval and tracking
/// during emergency situations.
class LocationService {
  final GeolocatorPlatform _geolocatorPlatform;

  /// Creates a [LocationService]. Allows passing an optional [GeolocatorPlatform]
  /// for hermetic unit testing.
  LocationService({GeolocatorPlatform? geolocatorPlatform})
      : _geolocatorPlatform = geolocatorPlatform ?? GeolocatorPlatform.instance;

  /// 1. Check whether device location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await _geolocatorPlatform.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  /// 2. Check current location permission.
  Future<LocationPermission> checkPermission() async {
    return await _geolocatorPlatform.checkPermission();
  }

  /// 3. Request location permission when required.
  Future<LocationPermission> requestPermission() async {
    return await _geolocatorPlatform.requestPermission();
  }

  /// Checks if location permission is already granted.
  Future<bool> hasPermission() async {
    final permission = await checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Helper to ensure permission is requested if denied.
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> requestAndCheckPermission() async {
    var permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Verifies both service enablement and permissions before retrieving location.
  /// Throws [LocationServiceException] on failure.
  Future<void> ensureLocationReady() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        LocationFailureReason.serviceDisabled,
        'Device location services are disabled.',
      );
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationServiceException(
          LocationFailureReason.permissionDenied,
          'Location permission was denied by the user.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        LocationFailureReason.permissionDeniedForever,
        'Location permission is permanently denied. Please enable it in system settings.',
      );
    }
  }

  /// 4. Get the device's current GPS position.
  /// Throws [LocationServiceException] if disabled, denied, or unavailable.
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    Duration? timeLimit = const Duration(seconds: 15),
  }) async {
    await ensureLocationReady();

    try {
      final settings = LocationSettings(
        accuracy: desiredAccuracy,
        timeLimit: timeLimit,
      );
      return await _geolocatorPlatform.getCurrentPosition(
        locationSettings: settings,
      );
    } on TimeoutException {
      throw const LocationServiceException(
        LocationFailureReason.locationUnavailable,
        'Timed out waiting for GPS position.',
      );
    } on LocationServiceException {
      rethrow;
    } catch (e) {
      throw LocationServiceException(
        LocationFailureReason.locationUnavailable,
        'Failed to obtain GPS position: $e',
      );
    }
  }

  /// Safe helper that returns `null` instead of throwing if location cannot be retrieved.
  Future<Position?> getCurrentPositionOrNull({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    Duration? timeLimit = const Duration(seconds: 15),
  }) async {
    try {
      return await getCurrentPosition(
        desiredAccuracy: desiredAccuracy,
        timeLimit: timeLimit,
      );
    } catch (_) {
      return null;
    }
  }

  /// 5. Provide latitude and longitude directly.
  /// Returns a clean [LocationCoordinates] or `null` if unavailable.
  Future<LocationCoordinates?> getCurrentCoordinates({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    Duration? timeLimit = const Duration(seconds: 15),
  }) async {
    final position = await getCurrentPositionOrNull(
      desiredAccuracy: desiredAccuracy,
      timeLimit: timeLimit,
    );
    if (position == null) return null;
    return LocationCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// 6. Provide a location stream for continuous updates during an active emergency.
  /// High accuracy stream for live tracking.
  Stream<Position> getPositionStream({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    int distanceFilter = 5,
  }) {
    final locationSettings = LocationSettings(
      accuracy: desiredAccuracy,
      distanceFilter: distanceFilter,
    );

    return _geolocatorPlatform.getPositionStream(
      locationSettings: locationSettings,
    );
  }
}
