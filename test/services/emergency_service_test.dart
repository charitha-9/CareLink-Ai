import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carelink_mobile/models/emergency_model.dart';
import 'package:carelink_mobile/models/student_model.dart';
import 'package:carelink_mobile/services/campus_geofence_service.dart';
import 'package:carelink_mobile/services/emergency_service.dart';
import 'package:carelink_mobile/services/location_service.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  Position? position;
  final StreamController<Position> streamController =
      StreamController<Position>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    return position ?? _createPosition(13.2384, 77.7126);
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return streamController.stream;
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
  const sampleStudent = StudentModel(
    studentId: 'STU-101',
    name: 'Charitha V',
    phoneNumber: '+91 98765 00001',
    campusId: 'amity_bengaluru',
    campusName: 'Amity University Bengaluru',
    hostelBlock: 'Block B',
    roomNumber: '304',
    roommate1Phone: '+91 98765 00002',
    wardenPhone: '+91 98765 00003',
    parentPhone: '+91 98765 00004',
  );

  late MockGeolocatorPlatform mockPlatform;
  late LocationService locationService;
  late CampusGeofenceService geofenceService;
  late EmergencyService emergencyService;

  setUp(() {
    mockPlatform = MockGeolocatorPlatform();
    locationService = LocationService(geolocatorPlatform: mockPlatform);
    geofenceService = CampusGeofenceService(
      config: CampusGeofenceConfig.amityBengaluruPlaceholder,
    );
    emergencyService = EmergencyService();
  });

  tearDown(() {
    emergencyService.dispose();
    mockPlatform.streamController.close();
  });

  group('EmergencyService - Countdown & Cancellation', () {
    test('startEmergency initializes countdown state and student info', () {
      final emergency = emergencyService.startEmergency(sampleStudent);

      expect(emergency.status, EmergencyStatus.countdown);
      expect(emergency.studentId, sampleStudent.studentId);
      expect(emergency.hostelBlock, 'Block B');
      expect(emergency.roomNumber, '304');
      expect(emergencyService.countdownSeconds, 3);
      expect(emergencyService.hasActiveEmergency, isTrue);
    });

    test('cancelEmergency sets status to cancelled and clears timers', () {
      emergencyService.startEmergency(sampleStudent);
      emergencyService.cancelEmergency();

      expect(emergencyService.currentEmergency?.status, EmergencyStatus.cancelled);
      expect(emergencyService.hasActiveEmergency, isFalse);
    });
  });

  group('EmergencyService - Inside Campus Autopilot Flow', () {
    test('executes inside campus sequence: roommate -> warden -> doctor -> parent -> active', () async {
      // Inside campus position
      mockPlatform.position = MockGeolocatorPlatform._createPosition(13.2384, 77.7126);

      // Run autopilot with zero step delay for fast unit test
      final autopilotFuture = emergencyService.startEmergencyAutopilot(
        student: sampleStudent,
        locationService: locationService,
        geofenceService: geofenceService,
        stepDelay: Duration.zero,
      );

      // Fast-forward countdown timer
      await Future<void>.delayed(const Duration(seconds: 4));
      await autopilotFuture;

      final emergency = emergencyService.currentEmergency;
      expect(emergency, isNotNull);
      expect(emergency!.campusStatus, CampusStatus.insideCampus);
      expect(emergency.status, EmergencyStatus.active);

      // Room strictly from StudentModel, not GPS
      expect(emergency.hostelBlock, 'Block B');
      expect(emergency.roomNumber, '304');

      // Inside campus escalation checks
      expect(emergency.roommateNotified, isTrue);
      expect(emergency.wardenNotified, isTrue);
      expect(emergency.doctorNotified, isTrue);
      expect(emergency.parentNotified, isTrue);

      // Live tracking should be active
      expect(emergency.liveTrackingActive, isTrue);
    });
  });

  group('EmergencyService - Outside Campus Autopilot Flow & 112 Approval', () {
    test('executes outside campus sequence: parent -> warden -> waitingFor112Approval', () async {
      // Outside campus position (~5km away)
      mockPlatform.position = MockGeolocatorPlatform._createPosition(13.3000, 77.7126);

      final autopilotFuture = emergencyService.startEmergencyAutopilot(
        student: sampleStudent,
        locationService: locationService,
        geofenceService: geofenceService,
        stepDelay: Duration.zero,
      );

      await Future<void>.delayed(const Duration(seconds: 4));
      await autopilotFuture;

      final emergency = emergencyService.currentEmergency;
      expect(emergency, isNotNull);
      expect(emergency!.campusStatus, CampusStatus.outsideCampus);
      expect(emergency.status, EmergencyStatus.waitingFor112Approval);

      // Outside campus escalation checks
      expect(emergency.parentNotified, isTrue);
      expect(emergency.wardenNotified, isTrue);
      expect(emergency.roommateNotified, isFalse);
      expect(emergency.doctorNotified, isFalse);
      expect(emergency.approvalFor112, isFalse);
    });

    test('approving 112 facilitates dialer without auto-calling and activates tracking', () async {
      mockPlatform.position = MockGeolocatorPlatform._createPosition(13.3000, 77.7126);

      final autopilotFuture = emergencyService.startEmergencyAutopilot(
        student: sampleStudent,
        locationService: locationService,
        geofenceService: geofenceService,
        stepDelay: Duration.zero,
      );

      await Future<void>.delayed(const Duration(seconds: 4));
      await autopilotFuture;

      expect(emergencyService.currentEmergency?.status, EmergencyStatus.waitingFor112Approval);

      String? dialedNumber;
      final approved = await emergencyService.approve112(
        locationService: locationService,
        dialerLauncher: (number) async {
          dialedNumber = number;
          return true;
        },
      );

      expect(approved, isTrue);
      expect(dialedNumber, '112');
      expect(emergencyService.currentEmergency?.approvalFor112, isTrue);
      expect(emergencyService.currentEmergency?.status, EmergencyStatus.active);
      expect(emergencyService.currentEmergency?.liveTrackingActive, isTrue);
    });

    test('dismissing 112 keeps campus emergency active without opening dialer', () async {
      mockPlatform.position = MockGeolocatorPlatform._createPosition(13.3000, 77.7126);

      final autopilotFuture = emergencyService.startEmergencyAutopilot(
        student: sampleStudent,
        locationService: locationService,
        geofenceService: geofenceService,
        stepDelay: Duration.zero,
      );

      await Future<void>.delayed(const Duration(seconds: 4));
      await autopilotFuture;

      emergencyService.dismiss112Approval(locationService: locationService);

      expect(emergencyService.currentEmergency?.approvalFor112, isFalse);
      expect(emergencyService.currentEmergency?.status, EmergencyStatus.active);
      expect(emergencyService.currentEmergency?.liveTrackingActive, isTrue);
    });
  });

  group('EmergencyService - Live Tracking Lifecycle & Resolution', () {
    test('live tracking updates coordinates and terminates on resolve', () async {
      emergencyService.startEmergency(sampleStudent);
      emergencyService.updateLocation(latitude: 13.0, longitude: 77.0);
      emergencyService.startLiveTracking(locationService);

      expect(emergencyService.currentEmergency?.liveTrackingActive, isTrue);

      // Emit new position update
      mockPlatform.streamController.add(
        MockGeolocatorPlatform._createPosition(13.1234, 77.5678),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emergencyService.currentEmergency?.latitude, 13.1234);
      expect(emergencyService.currentEmergency?.longitude, 77.5678);

      // Resolve emergency
      emergencyService.resolveEmergency();

      expect(emergencyService.currentEmergency?.status, EmergencyStatus.resolved);
      expect(emergencyService.currentEmergency?.liveTrackingActive, isFalse);

      // Additional position update after resolve should not modify status
      mockPlatform.streamController.add(
        MockGeolocatorPlatform._createPosition(14.0, 78.0),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emergencyService.currentEmergency?.status, EmergencyStatus.resolved);
    });
  });

  group('EmergencyService - Authorization & Privacy', () {
    test('authorizes student, registered roommate, warden, parent, and doctor', () {
      expect(
        emergencyService.isAuthorizedViewer(
          viewerId: sampleStudent.studentId,
          student: sampleStudent,
        ),
        isTrue,
      );
      expect(
        emergencyService.isAuthorizedViewer(
          viewerId: sampleStudent.roommate1Phone!,
          student: sampleStudent,
        ),
        isTrue,
      );
      expect(
        emergencyService.isAuthorizedViewer(
          viewerId: sampleStudent.wardenPhone!,
          student: sampleStudent,
        ),
        isTrue,
      );
      expect(
        emergencyService.isAuthorizedViewer(
          viewerId: sampleStudent.parentPhone!,
          student: sampleStudent,
        ),
        isTrue,
      );
      expect(
        emergencyService.isAuthorizedViewer(
          viewerId: 'DOCTOR_ON_CALL',
          student: sampleStudent,
        ),
        isTrue,
      );
    });

    test('rejects unauthorized third parties and empty IDs', () {
      expect(
        emergencyService.isAuthorizedViewer(
          viewerId: 'UNKNOWN_USER',
          student: sampleStudent,
        ),
        isFalse,
      );
      expect(
        emergencyService.isAuthorizedViewer(
          viewerId: '',
          student: sampleStudent,
        ),
        isFalse,
      );
    });
  });
}
