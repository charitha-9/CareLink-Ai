import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

import '../models/emergency_model.dart';
import 'location_service.dart';

/// Configuration specifying the center point and radius of a campus geofence.
class CampusGeofenceConfig {
  final String campusId;
  final String campusName;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusInMeters;

  const CampusGeofenceConfig({
    required this.campusId,
    required this.campusName,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusInMeters,
  });

  /// Configurable template / placeholder for Amity University Bengaluru.
  /// Replace these default coordinates and radius once official surveyed boundaries are finalized.
  static const CampusGeofenceConfig amityBengaluruPlaceholder =
      CampusGeofenceConfig(
    campusId: 'amity_bengaluru',
    campusName: 'Amity University Bengaluru',
    centerLatitude: 13.2384,
    centerLongitude: 77.7126,
    radiusInMeters: 1000.0,
  );

  CampusGeofenceConfig copyWith({
    String? campusId,
    String? campusName,
    double? centerLatitude,
    double? centerLongitude,
    double? radiusInMeters,
  }) {
    return CampusGeofenceConfig(
      campusId: campusId ?? this.campusId,
      campusName: campusName ?? this.campusName,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      radiusInMeters: radiusInMeters ?? this.radiusInMeters,
    );
  }
}

/// Modular service responsible for determining whether a user's location
/// falls within the campus geofence perimeter.
class CampusGeofenceService {
  /// Current campus geofence configuration.
  final CampusGeofenceConfig config;

  /// Optional distance calculator function to allow custom calculation in tests or algorithms.
  final double Function(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  )? distanceCalculator;

  CampusGeofenceService({
    required this.config,
    this.distanceCalculator,
  });

  /// Validates whether a coordinate pair is numerically valid and within global GPS bounds.
  bool isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude.isInfinite || longitude.isInfinite) return false;
    if (latitude < -90.0 || latitude > 90.0) return false;
    if (longitude < -180.0 || longitude > 180.0) return false;
    return true;
  }

  /// Calculates the geodesic distance in meters from the campus center.
  /// Returns `null` if the provided coordinates are invalid or unavailable.
  double? calculateDistanceFromCenter({
    required double? latitude,
    required double? longitude,
  }) {
    if (latitude == null || longitude == null) return null;
    if (!isValidCoordinate(latitude, longitude)) return null;

    if (distanceCalculator != null) {
      return distanceCalculator!(
        config.centerLatitude,
        config.centerLongitude,
        latitude,
        longitude,
      );
    }

    return _haversineDistance(
      config.centerLatitude,
      config.centerLongitude,
      latitude,
      longitude,
    );
  }

  /// Evaluates latitude and longitude coordinates and returns [CampusStatus].
  ///
  /// Returns:
  /// - [CampusStatus.insideCampus] if distance <= [config.radiusInMeters].
  /// - [CampusStatus.outsideCampus] if distance > [config.radiusInMeters].
  /// - [CampusStatus.unknown] if coordinates are null, NaN, or invalid.
  CampusStatus checkCoordinates({
    required double? latitude,
    required double? longitude,
  }) {
    final distance = calculateDistanceFromCenter(
      latitude: latitude,
      longitude: longitude,
    );

    if (distance == null) {
      return CampusStatus.unknown;
    }

    if (distance <= config.radiusInMeters) {
      return CampusStatus.insideCampus;
    } else {
      return CampusStatus.outsideCampus;
    }
  }

  /// Evaluates [LocationCoordinates] provided by [LocationService].
  CampusStatus checkLocation(LocationCoordinates? coordinates) {
    if (coordinates == null) return CampusStatus.unknown;
    return checkCoordinates(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
  }

  /// Evaluates [Position] provided by Geolocator or [LocationService].
  CampusStatus checkPosition(Position? position) {
    if (position == null) return CampusStatus.unknown;
    return checkCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Fetches the current coordinates from [LocationService] and evaluates
  /// the campus geofence status.
  Future<CampusStatus> checkCurrentLocation(LocationService locationService) async {
    final coordinates = await locationService.getCurrentCoordinates();
    return checkLocation(coordinates);
  }

  /// Pure Dart Haversine formula to compute great-circle distance between two points in meters.
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0; // Mean earth radius in meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
