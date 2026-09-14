import 'dart:async';
import '../models/care_facility_model.dart';
import 'campus_directory_care_service.dart';
import 'google_places_care_service.dart';

/// Error categories for nearby care navigation.
enum NearbyCareErrorType {
  apiKeyMissing,
  networkError,
  locationUnavailable,
  serverError,
  unknown,
}

/// Custom exception for care navigation errors.
class NearbyCareException implements Exception {
  final NearbyCareErrorType type;
  final String message;
  final dynamic cause;

  const NearbyCareException({
    required this.type,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'NearbyCareException($type): $message';
}

/// Abstract contract for healthcare facility providers.
abstract class NearbyCareRepository {
  /// Fetches facilities within [radiusKm] of [latitude] and [longitude].
  Future<List<CareFacility>> getNearbyFacilities({
    required double latitude,
    required double longitude,
    CareFacilityType? typeFilter,
    double radiusKm = 10.0,
  });

  /// Fetches in-depth details for a specific facility by ID.
  Future<CareFacility?> getFacilityDetails(String facilityId);
}

/// Orchestrator service for Nearby Care / Care Navigation.
/// Receives GPS coordinates from future GPS / Location services,
/// manages facility queries, filters, and coordinates with repository providers.
class NearbyCareService {
  static final NearbyCareService instance = NearbyCareService();

  final NearbyCareRepository _repository;

  // Cached GPS coordinates
  double? _latitude;
  double? _longitude;

  // Campus default coordinates (used when GPS is unavailable or campus mode is active)
  static const double defaultCampusLat = 28.5449;
  static const double defaultCampusLng = 77.3331;

  NearbyCareService({NearbyCareRepository? repository})
      : _repository = repository ?? _createDefaultRepository();

  /// Chooses Google Places provider if API key is supplied via dart-define,
  /// otherwise defaults to Campus Directory provider.
  static NearbyCareRepository _createDefaultRepository() {
    const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
    if (apiKey.isNotEmpty) {
      return GooglePlacesCareService(apiKey: apiKey);
    }
    return CampusDirectoryCareService();
  }

  // ------------------------------------------------------------
  // GPS COORDINATES INTERFACE (For future GPS / Location module)
  // ------------------------------------------------------------

  /// Updates the current user location coordinates.
  /// Called by future LocationService when GPS fixes are acquired.
  void updateCoordinates({required double latitude, required double longitude}) {
    _latitude = latitude;
    _longitude = longitude;
  }

  double? get currentLatitude => _latitude;
  double? get currentLongitude => _longitude;

  /// Effective latitude (falls back to default campus coordinates if not set)
  double get effectiveLatitude => _latitude ?? defaultCampusLat;

  /// Effective longitude (falls back to default campus coordinates if not set)
  double get effectiveLongitude => _longitude ?? defaultCampusLng;

  bool get hasLiveLocation => _latitude != null && _longitude != null;

  // ------------------------------------------------------------
  // FACILITY SEARCH & FILTERING
  // ------------------------------------------------------------

  /// Fetches nearby facilities using the active coordinates and applies filters.
  Future<List<CareFacility>> getFacilities({
    CareFacilityType? typeFilter,
    String? searchQuery,
    double radiusKm = 10.0,
  }) async {
    final rawFacilities = await _repository.getNearbyFacilities(
      latitude: effectiveLatitude,
      longitude: effectiveLongitude,
      typeFilter: typeFilter,
      radiusKm: radiusKm,
    );

    // Filter by text search query if provided
    var results = rawFacilities;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      results = results.where((f) {
        final matchesName = f.name.toLowerCase().contains(q);
        final matchesAddress = f.address.toLowerCase().contains(q);
        final matchesType = f.type.displayName.toLowerCase().contains(q);
        return matchesName || matchesAddress || matchesType;
      }).toList();
    }

    // Sort by calculated distance
    results.sort((a, b) {
      final distA = a.distanceKm ?? double.infinity;
      final distB = b.distanceKm ?? double.infinity;
      return distA.compareTo(distB);
    });

    return results;
  }

  /// Fetches details for a specific facility.
  Future<CareFacility?> getFacilityDetails(String facilityId) async {
    return _repository.getFacilityDetails(facilityId);
  }
}
