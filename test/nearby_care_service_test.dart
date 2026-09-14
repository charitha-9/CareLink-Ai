import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_mobile/models/care_facility_model.dart';
import 'package:carelink_mobile/services/campus_directory_care_service.dart';
import 'package:carelink_mobile/services/google_places_care_service.dart';
import 'package:carelink_mobile/services/nearby_care_service.dart';

class MockFailingRepository implements NearbyCareRepository {
  @override
  Future<List<CareFacility>> getNearbyFacilities({
    required double latitude,
    required double longitude,
    CareFacilityType? typeFilter,
    double radiusKm = 10.0,
  }) async {
    throw const NearbyCareException(
      type: NearbyCareErrorType.networkError,
      message: 'Network connection unavailable',
    );
  }

  @override
  Future<CareFacility?> getFacilityDetails(String facilityId) async {
    throw const NearbyCareException(
      type: NearbyCareErrorType.networkError,
      message: 'Network connection unavailable',
    );
  }
}

void main() {
  group('CampusDirectoryCareService Tests', () {
    late CampusDirectoryCareService directoryService;

    setUp(() {
      directoryService = CampusDirectoryCareService();
    });

    test('getNearbyFacilities returns non-empty list with calculated distance', () async {
      final facilities = await directoryService.getNearbyFacilities(
        latitude: 28.5449,
        longitude: 77.3331,
      );

      expect(facilities, isNotEmpty);
      for (final f in facilities) {
        expect(f.distanceKm, isNotNull);
      }
    });

    test('getNearbyFacilities correctly filters by hospital type', () async {
      final hospitals = await directoryService.getNearbyFacilities(
        latitude: 28.5449,
        longitude: 77.3331,
        typeFilter: CareFacilityType.hospital,
      );

      expect(hospitals, isNotEmpty);
      for (final h in hospitals) {
        expect(h.type, equals(CareFacilityType.hospital));
      }
    });

    test('getNearbyFacilities correctly filters by clinic type', () async {
      final clinics = await directoryService.getNearbyFacilities(
        latitude: 28.5449,
        longitude: 77.3331,
        typeFilter: CareFacilityType.clinic,
      );

      expect(clinics, isNotEmpty);
      for (final c in clinics) {
        expect(
          c.type == CareFacilityType.clinic ||
              c.type == CareFacilityType.campusHealthCenter,
          isTrue,
        );
      }
    });

    test('getFacilityDetails returns matching facility or null', () async {
      final facility = await directoryService.getFacilityDetails('fac-campus-health');
      expect(facility, isNotNull);
      expect(facility!.name, contains('Amity University'));

      final missing = await directoryService.getFacilityDetails('unknown-id');
      expect(missing, isNull);
    });
  });

  group('NearbyCareService Orchestrator Tests', () {
    test('updateCoordinates updates coordinates and hasLiveLocation', () {
      final service = NearbyCareService(repository: CampusDirectoryCareService());

      expect(service.hasLiveLocation, isFalse);
      expect(service.effectiveLatitude, equals(NearbyCareService.defaultCampusLat));

      service.updateCoordinates(latitude: 28.6000, longitude: 77.4000);

      expect(service.hasLiveLocation, isTrue);
      expect(service.currentLatitude, equals(28.6000));
      expect(service.currentLongitude, equals(77.4000));
      expect(service.effectiveLatitude, equals(28.6000));
    });

    test('search query filters facility list by text', () async {
      final service = NearbyCareService(repository: CampusDirectoryCareService());

      final results = await service.getFacilities(searchQuery: 'Jaypee');
      expect(results, isNotEmpty);
      expect(results.every((f) => f.name.contains('Jaypee')), isTrue);
    });

    test('failing repository gracefully propagates NearbyCareException', () async {
      final service = NearbyCareService(repository: MockFailingRepository());

      expect(
        () => service.getFacilities(),
        throwsA(isA<NearbyCareException>()),
      );
    });
  });

  group('GooglePlacesCareService Error & Config Tests', () {
    test('throws apiKeyMissing exception when API key is empty', () async {
      final placesService = GooglePlacesCareService(apiKey: '');

      expect(
        () => placesService.getNearbyFacilities(
          latitude: 28.5449,
          longitude: 77.3331,
        ),
        throwsA(
          predicate<NearbyCareException>(
            (e) => e.type == NearbyCareErrorType.apiKeyMissing,
          ),
        ),
      );
    });
  });
}
