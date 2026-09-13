import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_mobile/models/student_model.dart';
import 'package:carelink_mobile/models/emergency_model.dart';
import 'package:carelink_mobile/models/emergency_contact_model.dart';
import 'package:carelink_mobile/models/parent_guardian_link_model.dart';
import 'package:carelink_mobile/models/emergency_history_model.dart';

void main() {
  group('StudentModel Tests', () {
    test('StudentModel serialize and deserialize with fromMap and toMap', () {
      final student = StudentModel(
        studentId: 'std-123',
        name: 'Alex Johnson',
        phoneNumber: '+1234567890',
        campusId: 'campus-main',
        campusName: 'Central Campus',
        hostelBlock: 'Block-A',
        roomNumber: '302',
        roommate1Phone: '+1111111111',
        roommate2Phone: '+2222222222',
        wardenPhone: '+3333333333',
        parentPhone: '+4444444444',
        email: 'alex@carelink.ai',
        fcmToken: 'fcm-token-123',
      );

      final map = student.toMap();
      expect(map['studentId'], 'std-123');
      expect(map['name'], 'Alex Johnson');
      expect(map['email'], 'alex@carelink.ai');
      expect(map['fcmToken'], 'fcm-token-123');

      final fromMap = StudentModel.fromMap(map, 'std-123');
      expect(fromMap.studentId, 'std-123');
      expect(fromMap.name, 'Alex Johnson');
      expect(fromMap.hostelBlock, 'Block-A');
      expect(fromMap.email, 'alex@carelink.ai');
      expect(fromMap.fcmToken, 'fcm-token-123');
    });

    test('StudentModel copyWith behaves correctly', () {
      const student = StudentModel(
        studentId: 'std-1',
        name: 'Alex',
        phoneNumber: '123',
        campusId: 'c1',
        campusName: 'Camp',
      );

      final updated = student.copyWith(name: 'Alexander', email: 'a@c.ai');
      expect(updated.name, 'Alexander');
      expect(updated.email, 'a@c.ai');
      expect(updated.studentId, 'std-1');
    });
  });

  group('EmergencyModel Tests', () {
    test('EmergencyModel serialize and deserialize', () {
      final now = DateTime.now();
      final emergency = EmergencyModel(
        emergencyId: 'emg-001',
        studentId: 'std-123',
        createdAt: now,
        latitude: 12.9716,
        longitude: 77.5946,
        campusStatus: CampusStatus.insideCampus,
        status: EmergencyStatus.active,
        hostelBlock: 'Block-B',
        roomNumber: '104',
        roommateNotified: true,
        wardenNotified: true,
        doctorNotified: false,
        parentNotified: true,
        approvalFor112: true,
        liveTrackingActive: true,
      );

      final map = emergency.toMap();
      expect(map['emergencyId'], 'emg-001');
      expect(map['campusStatus'], 'insideCampus');
      expect(map['status'], 'active');
      expect(map['latitude'], 12.9716);

      final reconstructed = EmergencyModel.fromMap(map, 'emg-001');
      expect(reconstructed.emergencyId, 'emg-001');
      expect(reconstructed.studentId, 'std-123');
      expect(reconstructed.campusStatus, CampusStatus.insideCampus);
      expect(reconstructed.status, EmergencyStatus.active);
      expect(reconstructed.roommateNotified, true);
      expect(reconstructed.approvalFor112, true);
    });
  });

  group('EmergencyContactModel Tests', () {
    test('EmergencyContactModel serialization and copyWith', () {
      final now = DateTime.now();
      final contact = EmergencyContactModel(
        contactId: 'ct-1',
        studentId: 'std-123',
        name: 'Jane Doe',
        phoneNumber: '+9876543210',
        relationship: 'Roommate',
        isPrimary: true,
        createdAt: now,
      );

      final map = contact.toMap();
      expect(map['name'], 'Jane Doe');
      expect(map['relationship'], 'Roommate');
      expect(map['isPrimary'], true);

      final fromMap = EmergencyContactModel.fromMap(map);
      expect(fromMap.contactId, 'ct-1');
      expect(fromMap.studentId, 'std-123');
      expect(fromMap.isPrimary, true);
    });
  });

  group('ParentGuardianLinkModel Tests', () {
    test('ParentGuardianLinkModel serialization and status handling', () {
      final now = DateTime.now();
      final link = ParentGuardianLinkModel(
        linkId: 'link-1',
        studentId: 'std-123',
        parentName: 'Robert Johnson',
        parentPhone: '+1999888777',
        parentEmail: 'robert@parent.org',
        relationship: 'Father',
        status: ParentLinkStatus.approved,
        linkedAt: now,
        studentName: 'Alex Johnson',
      );

      final map = link.toMap();
      expect(map['parentName'], 'Robert Johnson');
      expect(map['status'], 'approved');
      expect(map['relationship'], 'Father');

      final reconstructed = ParentGuardianLinkModel.fromMap(map);
      expect(reconstructed.linkId, 'link-1');
      expect(reconstructed.status, ParentLinkStatus.approved);
      expect(reconstructed.parentEmail, 'robert@parent.org');
    });
  });

  group('EmergencyHistoryModel Tests', () {
    test('EmergencyHistoryModel serialization and notified parties', () {
      final started = DateTime.now().subtract(const Duration(minutes: 30));
      final resolved = DateTime.now();
      final history = EmergencyHistoryModel(
        historyId: 'hist-1',
        emergencyId: 'emg-001',
        studentId: 'std-123',
        startedAt: started,
        resolvedAt: resolved,
        resolutionStatus: 'resolved',
        incidentType: 'medical',
        summary: 'Asthma inhaler assistance required and provided.',
        latitude: 12.9716,
        longitude: 77.5946,
        notifiedParties: const ['Roommate', 'Warden', 'Campus Clinic'],
      );

      final map = history.toMap();
      expect(map['historyId'], 'hist-1');
      expect(map['resolutionStatus'], 'resolved');
      expect(map['notifiedParties'], ['Roommate', 'Warden', 'Campus Clinic']);

      final reconstructed = EmergencyHistoryModel.fromMap(map);
      expect(reconstructed.historyId, 'hist-1');
      expect(reconstructed.summary, 'Asthma inhaler assistance required and provided.');
      expect(reconstructed.notifiedParties.length, 3);
      expect(reconstructed.notifiedParties[2], 'Campus Clinic');
    });
  });
}