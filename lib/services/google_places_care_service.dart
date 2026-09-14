import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/care_facility_model.dart';
import 'nearby_care_service.dart';

/// Provider connecting directly to the Google Places API (New)
/// for real-time live nearby healthcare search.
///
/// Authentication:
/// API key MUST be provided at compile-time via:
/// `--dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY`
/// or passed explicitly to the constructor.
/// API keys are NEVER hard-coded in the repository.
class GooglePlacesCareService implements NearbyCareRepository {
  final String apiKey;
  final http.Client _client;

  static const String _searchNearbyEndpoint =
      'https://places.googleapis.com/v1/places:searchNearby';
  static const String _placeDetailsEndpoint =
      'https://places.googleapis.com/v1/places/';

  GooglePlacesCareService({
    String? apiKey,
    http.Client? client,
  })  : apiKey = apiKey ??
            const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: ''),
        _client = client ?? http.Client();

  @override
  Future<List<CareFacility>> getNearbyFacilities({
    required double latitude,
    required double longitude,
    CareFacilityType? typeFilter,
    double radiusKm = 10.0,
  }) async {
    if (apiKey.isEmpty) {
      throw const NearbyCareException(
        type: NearbyCareErrorType.apiKeyMissing,
        message: 'Google Places API key is not configured. Supply via '
            '--dart-define=GOOGLE_MAPS_API_KEY=... or use the Campus Directory provider.',
      );
    }

    // Determine target Place types based on filter
    List<String> includedTypes = ['hospital', 'medical_clinic'];
    if (typeFilter == CareFacilityType.hospital) {
      includedTypes = ['hospital'];
    } else if (typeFilter == CareFacilityType.clinic ||
        typeFilter == CareFacilityType.campusHealthCenter) {
      includedTypes = ['medical_clinic'];
    }

    final requestBody = jsonEncode({
      'includedTypes': includedTypes,
      'maxResultCount': 20,
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': (radiusKm * 1000.0).clamp(500.0, 50000.0),
        },
      },
    });

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask':
          'places.id,places.displayName,places.formattedAddress,'
          'places.location,places.currentOpeningHours,'
          'places.internationalPhoneNumber,places.nationalPhoneNumber,'
          'places.rating,places.websiteUri,places.types',
    };

    try {
      final response = await _client
          .post(
            Uri.parse(_searchNearbyEndpoint),
            headers: headers,
            body: requestBody,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final places = (data['places'] as List?) ?? [];

        return places.map((placeJson) {
          final facility = CareFacility.fromGooglePlacesNew(
            placeJson as Map<String, dynamic>,
          );
          return facility.withCalculatedDistance(latitude, longitude);
        }).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw NearbyCareException(
          type: NearbyCareErrorType.apiKeyMissing,
          message: 'Google Places API key authentication failed (${response.statusCode}).',
        );
      } else {
        throw NearbyCareException(
          type: NearbyCareErrorType.serverError,
          message: 'Google Places API error: ${response.statusCode}',
        );
      }
    } on NearbyCareException {
      rethrow;
    } catch (e) {
      throw NearbyCareException(
        type: NearbyCareErrorType.networkError,
        message: 'Failed to reach Google Places API: $e',
        cause: e,
      );
    }
  }

  @override
  Future<CareFacility?> getFacilityDetails(String facilityId) async {
    if (apiKey.isEmpty) {
      throw const NearbyCareException(
        type: NearbyCareErrorType.apiKeyMissing,
        message: 'Google Places API key is not configured.',
      );
    }

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask':
          'id,displayName,formattedAddress,location,currentOpeningHours,'
          'internationalPhoneNumber,nationalPhoneNumber,rating,websiteUri,types',
    };

    try {
      final response = await _client
          .get(
            Uri.parse('$_placeDetailsEndpoint$facilityId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CareFacility.fromGooglePlacesNew(data);
      }
      return null;
    } catch (e) {
      throw NearbyCareException(
        type: NearbyCareErrorType.networkError,
        message: 'Failed to load facility details: $e',
        cause: e,
      );
    }
  }
}
