import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carelink_mobile/services/location_service.dart';

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission checkPermissionResult = LocationPermission.whileInUse;
  LocationPermission requestPermissionResult = LocationPermission.whileInUse;
  Position? currentPosition;
  Exception? positionException;
  final StreamController<Position> streamController =
      StreamController<Position>.broadcast();

  int requestPermissionCallCount = 0;

  @override
  Future<bool> isLocationServiceEnabled() async {
    return serviceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return checkPermissionResult;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCallCount++;
    return requestPermissionResult;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (positionException != null) {
      throw positionException!;
    }
    return currentPosition ?? _defaultPosition();
  }

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    return streamController.stream;
  }

  static Position _defaultPosition({
    double latitude = 12.9716,
    double longitude = 77.5946,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      accuracy: 5.0,
      altitude: 920.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }
}

void main() {
  late FakeGeolocatorPlatform fakePlatform;
  late LocationService locationService;

  setUp(() {
    fakePlatform = FakeGeolocatorPlatform();
    locationService = LocationService(geolocatorPlatform: fakePlatform);
  });

  tearDown(() {
    fakePlatform.streamController.close();
  });

  group('LocationService - Service Availability', () {
    test('isLocationServiceEnabled returns true when service is enabled', () async {
      fakePlatform.serviceEnabled = true;
      expect(await locationService.isLocationServiceEnabled(), isTrue);
    });

    test('isLocationServiceEnabled returns false when service is disabled', () async {
      fakePlatform.serviceEnabled = false;
      expect(await locationService.isLocationServiceEnabled(), isFalse);
    });
  });

  group('LocationService - Permissions', () {
    test('checkPermission returns current platform permission', () async {
      fakePlatform.checkPermissionResult = LocationPermission.denied;
      expect(await locationService.checkPermission(), LocationPermission.denied);

      fakePlatform.checkPermissionResult = LocationPermission.whileInUse;
      expect(await locationService.checkPermission(), LocationPermission.whileInUse);
    });

    test('requestPermission delegates to platform', () async {
      fakePlatform.requestPermissionResult = LocationPermission.whileInUse;
      final result = await locationService.requestPermission();
      expect(result, LocationPermission.whileInUse);
      expect(fakePlatform.requestPermissionCallCount, 1);
    });

    test('hasPermission returns true only for whileInUse or always', () async {
      fakePlatform.checkPermissionResult = LocationPermission.whileInUse;
      expect(await locationService.hasPermission(), isTrue);

      fakePlatform.checkPermissionResult = LocationPermission.always;
      expect(await locationService.hasPermission(), isTrue);

      fakePlatform.checkPermissionResult = LocationPermission.denied;
      expect(await locationService.hasPermission(), isFalse);

      fakePlatform.checkPermissionResult = LocationPermission.deniedForever;
      expect(await locationService.hasPermission(), isFalse);
    });

    test('requestAndCheckPermission requests when denied and succeeds', () async {
      fakePlatform.checkPermissionResult = LocationPermission.denied;
      fakePlatform.requestPermissionResult = LocationPermission.whileInUse;

      final result = await locationService.requestAndCheckPermission();
      expect(result, isTrue);
      expect(fakePlatform.requestPermissionCallCount, 1);
    });

    test('requestAndCheckPermission does not request when already granted', () async {
      fakePlatform.checkPermissionResult = LocationPermission.whileInUse;

      final result = await locationService.requestAndCheckPermission();
      expect(result, isTrue);
      expect(fakePlatform.requestPermissionCallCount, 0);
    });
  });

  group('LocationService - getCurrentPosition and error handling', () {
    test('successfully returns Position when service enabled and permission granted', () async {
      fakePlatform.serviceEnabled = true;
      fakePlatform.checkPermissionResult = LocationPermission.whileInUse;
      fakePlatform.currentPosition = FakeGeolocatorPlatform._defaultPosition(
        latitude: 13.0827,
        longitude: 80.2707,
      );

      final position = await locationService.getCurrentPosition();
      expect(position.latitude, 13.0827);
      expect(position.longitude, 80.2707);
    });

    test('throws LocationServiceException with serviceDisabled when GPS is off', () async {
      fakePlatform.serviceEnabled = false;

      expect(
        () => locationService.getCurrentPosition(),
        throwsA(
          isA<LocationServiceException>().having(
            (e) => e.reason,
            'reason',
            LocationFailureReason.serviceDisabled,
          ),
        ),
      );
    });

    test('throws LocationServiceException with permissionDenied if user denies request', () async {
      fakePlatform.serviceEnabled = true;
      fakePlatform.checkPermissionResult = LocationPermission.denied;
      fakePlatform.requestPermissionResult = LocationPermission.denied;

      expect(
        () => locationService.getCurrentPosition(),
        throwsA(
          isA<LocationServiceException>().having(
            (e) => e.reason,
            'reason',
            LocationFailureReason.permissionDenied,
          ),
        ),
      );
    });

    test('throws LocationServiceException with permissionDeniedForever when permanently denied', () async {
      fakePlatform.serviceEnabled = true;
      fakePlatform.checkPermissionResult = LocationPermission.deniedForever;

      expect(
        () => locationService.getCurrentPosition(),
        throwsA(
          isA<LocationServiceException>().having(
            (e) => e.reason,
            'reason',
            LocationFailureReason.permissionDeniedForever,
          ),
        ),
      );
    });

    test('throws LocationServiceException with locationUnavailable on timeout or hardware failure', () async {
      fakePlatform.serviceEnabled = true;
      fakePlatform.checkPermissionResult = LocationPermission.whileInUse;
      fakePlatform.positionException = TimeoutException('GPS timeout');

      expect(
        () => locationService.getCurrentPosition(),
        throwsA(
          isA<LocationServiceException>().having(
            (e) => e.reason,
            'reason',
            LocationFailureReason.locationUnavailable,
          ),
        ),
      );
    });
  });

  group('LocationService - Coordinates and Safe retrieval', () {
    test('getCurrentPositionOrNull returns null on failure without throwing', () async {
      fakePlatform.serviceEnabled = false;

      final position = await locationService.getCurrentPositionOrNull();
      expect(position, isNull);
    });

    test('getCurrentCoordinates returns valid LocationCoordinates on success', () async {
      fakePlatform.serviceEnabled = true;
      fakePlatform.checkPermissionResult = LocationPermission.whileInUse;
      fakePlatform.currentPosition = FakeGeolocatorPlatform._defaultPosition(
        latitude: 12.9716,
        longitude: 77.5946,
      );

      final coordinates = await locationService.getCurrentCoordinates();
      expect(coordinates, isNotNull);
      expect(coordinates!.latitude, 12.9716);
      expect(coordinates.longitude, 77.5946);
      expect(
        coordinates,
        equals(const LocationCoordinates(latitude: 12.9716, longitude: 77.5946)),
      );
    });

    test('getCurrentCoordinates returns null if position fails', () async {
      fakePlatform.serviceEnabled = false;

      final coordinates = await locationService.getCurrentCoordinates();
      expect(coordinates, isNull);
    });
  });

  group('LocationService - Continuous Location Stream', () {
    test('getPositionStream forwards updates for active emergency tracking', () async {
      final stream = locationService.getPositionStream();
      final emittedPositions = <Position>[];

      final subscription = stream.listen(emittedPositions.add);

      final pos1 = FakeGeolocatorPlatform._defaultPosition(latitude: 12.1, longitude: 77.1);
      final pos2 = FakeGeolocatorPlatform._defaultPosition(latitude: 12.2, longitude: 77.2);

      fakePlatform.streamController.add(pos1);
      fakePlatform.streamController.add(pos2);

      await pumpEventQueue();

      expect(emittedPositions.length, 2);
      expect(emittedPositions[0].latitude, 12.1);
      expect(emittedPositions[1].latitude, 12.2);

      await subscription.cancel();
    });
  });
}
