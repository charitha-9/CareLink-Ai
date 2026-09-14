import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carelink_mobile/models/emergency_model.dart';
import 'package:carelink_mobile/services/campus_geofence_service.dart';
import 'package:carelink_mobile/services/location_service.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission checkPermissionResult = LocationPermission.whileInUse;
  Position? currentPosition;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => checkPermissionResult;

  @override
  Future<LocationPermission> requestPermission() async => checkPermissionResult;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    return currentPosition ?? _createPosition(13.2384, 77.7126);
  }

  static Position _createPosition(double lat, double lng) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      accuracy: 5.0,
      altitude: 900.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }
}

void main() {
  const testConfig = CampusGeofenceConfig(
    campusId: 'test_campus',
    campusName: 'Test University Campus',
    centerLatitude: 13.2384,
    centerLongitude: 77.7126,
    radiusInMeters: 1000.0, // 1 km
  );

  late CampusGeofenceService geofenceService;

  setUp(() {
    geofenceService = CampusGeofenceService(config: testConfig);
  });

  group('CampusGeofenceService - Inside Campus', () {
    test('returns insideCampus when exactly at campus center', () {
      final status = geofenceService.checkCoordinates(
        latitude: 13.2384,
        longitude: 77.7126,
      );
      expect(status, CampusStatus.insideCampus);

      final distance = geofenceService.calculateDistanceFromCenter(
        latitude: 13.2384,
        longitude: 77.7126,
      );
      expect(distance, closeTo(0.0, 0.01));
    });

    test('returns insideCampus when clearly inside radius (~200m away)', () {
      // Small delta in latitude: 0.0018 deg is roughly ~200 meters
      final status = geofenceService.checkCoordinates(
        latitude: 13.2402,
        longitude: 77.7126,
      );
      expect(status, CampusStatus.insideCampus);

      final distance = geofenceService.calculateDistanceFromCenter(
        latitude: 13.2402,
        longitude: 77.7126,
      );
      expect(distance, isNotNull);
      expect(distance!, lessThan(1000.0));
    });
  });

  group('CampusGeofenceService - Outside Campus', () {
    test('returns outsideCampus when clearly outside radius (~5km away)', () {
      // 0.05 deg latitude difference is ~5.5 km
      final status = geofenceService.checkCoordinates(
        latitude: 13.2900,
        longitude: 77.7126,
      );
      expect(status, CampusStatus.outsideCampus);

      final distance = geofenceService.calculateDistanceFromCenter(
        latitude: 13.2900,
        longitude: 77.7126,
      );
      expect(distance, isNotNull);
      expect(distance!, greaterThan(1000.0));
    });

    test('returns outsideCampus for coordinates in another city', () {
      // New Delhi coordinates
      final status = geofenceService.checkCoordinates(
        latitude: 28.6139,
        longitude: 77.2090,
      );
      expect(status, CampusStatus.outsideCampus);
    });
  });

  group('CampusGeofenceService - Boundary / Edge Cases', () {
    test('returns insideCampus on the exact perimeter boundary (distance == radius)', () {
      final boundaryService = CampusGeofenceService(
        config: testConfig,
        distanceCalculator: (lat1, lon1, lat2, lon2) => 1000.0,
      );

      final status = boundaryService.checkCoordinates(
        latitude: 13.2400,
        longitude: 77.7126,
      );
      expect(status, CampusStatus.insideCampus);
    });

    test('returns outsideCampus immediately outside boundary (distance == radius + 0.1m)', () {
      final boundaryService = CampusGeofenceService(
        config: testConfig,
        distanceCalculator: (lat1, lon1, lat2, lon2) => 1000.1,
      );

      final status = boundaryService.checkCoordinates(
        latitude: 13.2400,
        longitude: 77.7126,
      );
      expect(status, CampusStatus.outsideCampus);
    });
  });

  group('CampusGeofenceService - Invalid and Unavailable Coordinates', () {
    test('returns unknown for null latitude or longitude', () {
      expect(
        geofenceService.checkCoordinates(latitude: null, longitude: 77.7126),
        CampusStatus.unknown,
      );
      expect(
        geofenceService.checkCoordinates(latitude: 13.2384, longitude: null),
        CampusStatus.unknown,
      );
      expect(
        geofenceService.checkCoordinates(latitude: null, longitude: null),
        CampusStatus.unknown,
      );
    });

    test('returns unknown for NaN values', () {
      expect(
        geofenceService.checkCoordinates(
          latitude: double.nan,
          longitude: 77.7126,
        ),
        CampusStatus.unknown,
      );
      expect(
        geofenceService.checkCoordinates(
          latitude: 13.2384,
          longitude: double.nan,
        ),
        CampusStatus.unknown,
      );
    });

    test('returns unknown for Infinite values', () {
      expect(
        geofenceService.checkCoordinates(
          latitude: double.infinity,
          longitude: 77.7126,
        ),
        CampusStatus.unknown,
      );
      expect(
        geofenceService.checkCoordinates(
          latitude: 13.2384,
          longitude: double.negativeInfinity,
        ),
        CampusStatus.unknown,
      );
    });

    test('returns unknown for out-of-range coordinates', () {
      // Latitude out of [-90, 90]
      expect(
        geofenceService.checkCoordinates(latitude: 91.0, longitude: 77.7126),
        CampusStatus.unknown,
      );
      expect(
        geofenceService.checkCoordinates(latitude: -90.5, longitude: 77.7126),
        CampusStatus.unknown,
      );

      // Longitude out of [-180, 180]
      expect(
        geofenceService.checkCoordinates(latitude: 13.2384, longitude: 181.0),
        CampusStatus.unknown,
      );
      expect(
        geofenceService.checkCoordinates(latitude: 13.2384, longitude: -180.1),
        CampusStatus.unknown,
      );
    });

    test('isValidCoordinate returns false for invalid coordinates', () {
      expect(geofenceService.isValidCoordinate(null, 0.0), isFalse);
      expect(geofenceService.isValidCoordinate(0.0, null), isFalse);
      expect(geofenceService.isValidCoordinate(double.nan, 0.0), isFalse);
      expect(geofenceService.isValidCoordinate(100.0, 0.0), isFalse);
      expect(geofenceService.isValidCoordinate(0.0, 200.0), isFalse);
      expect(geofenceService.isValidCoordinate(13.2384, 77.7126), isTrue);
    });
  });

  group('CampusGeofenceService - Config Replaceability & Amity Bengaluru Placeholder', () {
    test('works with default amityBengaluruPlaceholder configuration', () {
      final amityService = CampusGeofenceService(
        config: CampusGeofenceConfig.amityBengaluruPlaceholder,
      );

      expect(amityService.config.campusName, 'Amity University Bengaluru');
      expect(amityService.config.radiusInMeters, 1000.0);

      // Check center
      final status = amityService.checkCoordinates(
        latitude: 13.2384,
        longitude: 77.7126,
      );
      expect(status, CampusStatus.insideCampus);
    });

    test('allows replacing configuration with custom surveyed bounds', () {
      const customConfig = CampusGeofenceConfig(
        campusId: 'amity_custom',
        campusName: 'Amity Bengaluru Surveyed',
        centerLatitude: 13.2400,
        centerLongitude: 77.7200,
        radiusInMeters: 500.0,
      );

      final service = CampusGeofenceService(config: customConfig);
      expect(service.config.radiusInMeters, 500.0);
      expect(service.config.centerLatitude, 13.2400);

      // Previous center (13.2384, 77.7126) is > 800m away, outside 500m radius
      final status = service.checkCoordinates(
        latitude: 13.2384,
        longitude: 77.7126,
      );
      expect(status, CampusStatus.outsideCampus);
    });
  });

  group('CampusGeofenceService - Integration with LocationService & Models', () {
    test('checkLocation evaluates LocationCoordinates properly', () {
      const insideCoords = LocationCoordinates(latitude: 13.2384, longitude: 77.7126);
      expect(geofenceService.checkLocation(insideCoords), CampusStatus.insideCampus);

      const outsideCoords = LocationCoordinates(latitude: 14.0, longitude: 78.0);
      expect(geofenceService.checkLocation(outsideCoords), CampusStatus.outsideCampus);

      expect(geofenceService.checkLocation(null), CampusStatus.unknown);
    });

    test('checkPosition evaluates Position properly', () {
      final insidePos = FakeGeolocatorPlatform._createPosition(13.2384, 77.7126);
      expect(geofenceService.checkPosition(insidePos), CampusStatus.insideCampus);

      final outsidePos = FakeGeolocatorPlatform._createPosition(14.0, 78.0);
      expect(geofenceService.checkPosition(outsidePos), CampusStatus.outsideCampus);

      expect(geofenceService.checkPosition(null), CampusStatus.unknown);
    });

    test('checkCurrentLocation fetches from LocationService and determines status', () async {
      final fakePlatform = FakeGeolocatorPlatform();
      fakePlatform.currentPosition = FakeGeolocatorPlatform._createPosition(13.2384, 77.7126);
      final locationService = LocationService(geolocatorPlatform: fakePlatform);

      final status = await geofenceService.checkCurrentLocation(locationService);
      expect(status, CampusStatus.insideCampus);
    });

    test('checkCurrentLocation returns unknown if LocationService returns null', () async {
      final fakePlatform = FakeGeolocatorPlatform();
      fakePlatform.serviceEnabled = false; // GPS disabled, returns null
      final locationService = LocationService(geolocatorPlatform: fakePlatform);

      final status = await geofenceService.checkCurrentLocation(locationService);
      expect(status, CampusStatus.unknown);
    });
  });
}
