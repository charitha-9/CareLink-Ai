import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_mobile/models/care_facility_model.dart';
import 'package:carelink_mobile/models/emergency_history_model.dart';

void main() {
  group('CareFacilityModel Tests', () {
    test('CareFacility formats distance in meters when under 1.0 km', () {
      const facility = CareFacility(
        id: 'test-1',
        name: 'Campus Infirmary',
        type: CareFacilityType.campusHealthCenter,
        address: 'Sector 125, Noida',
        distanceKm: 0.45,
      );

      expect(facility.formattedDistance, equals('450 m'));
    });

    test('CareFacility formats distance in km when at or over 1.0 km', () {
      const facility = CareFacility(
        id: 'test-2',
        name: 'City General Hospital',
        type: CareFacilityType.hospital,
        address: 'Sector 62, Noida',
        distanceKm: 3.42,
      );

      expect(facility.formattedDistance, equals('3.4 km'));
    });

    test('CareFacility withCalculatedDistance computes realistic geodesic distance', () {
      // Coordinates near Amity Campus (28.5449, 77.3331)
      const facility = CareFacility(
        id: 'test-3',
        name: 'Jaypee Hospital',
        type: CareFacilityType.hospital,
        address: 'Sector 128, Noida',
        latitude: 28.5173,
        longitude: 77.3687,
      );

      final withDist = facility.withCalculatedDistance(28.5449, 77.3331);
      expect(withDist.distanceKm, isNotNull);
      // Distance between (28.5449, 77.3331) and (28.5173, 77.3687) is roughly 4.6 km
      expect(withDist.distanceKm!, greaterThan(4.0));
      expect(withDist.distanceKm!, lessThan(6.0));
    });

    test('CareFacilityType.fromString handles case-insensitivity and campus types', () {
      expect(CareFacilityType.fromString('hospital'), equals(CareFacilityType.hospital));
      expect(CareFacilityType.fromString('HOSPITAL'), equals(CareFacilityType.hospital));
      expect(CareFacilityType.fromString('Campus Health Center'), equals(CareFacilityType.campusHealthCenter));
      expect(CareFacilityType.fromString('Infirmary'), equals(CareFacilityType.campusHealthCenter));
      expect(CareFacilityType.fromString('Urgent Care Clinic'), equals(CareFacilityType.urgentCare));
      expect(CareFacilityType.fromString('dental clinic'), equals(CareFacilityType.clinic));
      expect(CareFacilityType.fromString(null), equals(CareFacilityType.clinic));
    });

    test('CareFacility serialization toMap and fromMap preserves all fields', () {
      const original = CareFacility(
        id: 'fac-100',
        name: 'Metro Hospital',
        type: CareFacilityType.hospital,
        address: 'Sector 11, Noida',
        phone: '+91 120 123 4567',
        latitude: 28.5800,
        longitude: 77.3300,
        distanceKm: 2.1,
        isOpen: true,
        operatingHours: '24 Hours',
        emergencyServicesAvailable: true,
        website: 'https://metro.org',
        rating: 4.5,
      );

      final map = original.toMap();
      final restored = CareFacility.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.type, equals(original.type));
      expect(restored.address, equals(original.address));
      expect(restored.phone, equals(original.phone));
      expect(restored.latitude, equals(original.latitude));
      expect(restored.longitude, equals(original.longitude));
      expect(restored.distanceKm, equals(original.distanceKm));
      expect(restored.isOpen, isTrue);
      expect(restored.emergencyServicesAvailable, isTrue);
      expect(restored.rating, equals(4.5));
    });
  });

  group('EmergencyHistoryModel Tests', () {
    test('EmergencyHistoryModel serializes and deserializes correctly', () {
      final now = DateTime.now();
      final history = EmergencyHistoryModel(
        historyId: 'HIST-001',
        emergencyId: 'EMG-12345',
        studentId: 'STU-999',
        startedAt: now,
        resolvedAt: now.add(const Duration(minutes: 15)),
        resolutionStatus: 'resolved',
        incidentType: 'Severe Asthma',
        summary: 'Administered inhaler and accompanied to health room.',
        notifiedParties: const ['Warden', 'Roommate'],
      );

      final map = history.toMap();
      final restored = EmergencyHistoryModel.fromMap(map);

      expect(restored.historyId, equals(history.historyId));
      expect(restored.emergencyId, equals(history.emergencyId));
      expect(restored.studentId, equals(history.studentId));
      expect(restored.resolutionStatus, equals('resolved'));
      expect(restored.incidentType, equals('Severe Asthma'));
      expect(restored.notifiedParties, contains('Warden'));
    });
  });
}
