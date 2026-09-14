import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_mobile/models/emergency_model.dart';
import 'package:carelink_mobile/models/student_model.dart';
import 'package:carelink_mobile/screens/emergency_screen.dart';
import 'package:carelink_mobile/services/emergency_service.dart';

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

  group('EmergencyScreen Widget Tests', () {
    testWidgets('displays countdown screen with visible Cancel button', (tester) async {
      final emergencyService = EmergencyService();
      emergencyService.startEmergency(sampleStudent);

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyScreen(
            student: sampleStudent,
            emergencyService: emergencyService,
            autoStartAutopilot: false,
          ),
        ),
      );

      expect(find.text('EMERGENCY INITIATED'), findsOneWidget);
      expect(find.text('CANCEL EMERGENCY'), findsOneWidget);
      expect(find.byKey(const Key('cancelCountdownButton')), findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.byKey(const Key('cancelCountdownButton')));
      await tester.pumpAndSettle();

      expect(emergencyService.currentEmergency?.status, EmergencyStatus.cancelled);
      expect(find.text('Emergency Cancelled'), findsOneWidget);
    });

    testWidgets('displays active emergency with room number from student profile', (tester) async {
      final emergencyService = EmergencyService();
      emergencyService.startEmergency(sampleStudent);
      emergencyService.updateCampusStatus(CampusStatus.insideCampus);
      emergencyService.setLiveTracking(true);

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyScreen(
            student: sampleStudent,
            emergencyService: emergencyService,
            autoStartAutopilot: false,
          ),
        ),
      );

      expect(find.text('Active Emergency'), findsWidgets);
      expect(find.text('Charitha V'), findsOneWidget);
      expect(find.text('Block B'), findsOneWidget);
      expect(find.text('304'), findsOneWidget);
      expect(find.text('📍 Room verified from Student Profile (not GPS)'), findsOneWidget);
      expect(find.text('Inside Campus Perimeter'), findsOneWidget);
      expect(find.text('RESOLVE EMERGENCY'), findsOneWidget);
    });

    testWidgets('displays 112 approval card when waiting for 112 approval', (tester) async {
      final emergencyService = EmergencyService();
      emergencyService.startEmergency(sampleStudent);
      emergencyService.updateCampusStatus(CampusStatus.outsideCampus);
      emergencyService.set112Approval(false);

      // Set state to waitingFor112Approval manually
      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyScreen(
            student: sampleStudent,
            emergencyService: emergencyService,
            autoStartAutopilot: false,
          ),
        ),
      );

      // Trigger outside campus waiting state
      emergencyService.markParentNotified();
      emergencyService.markWardenNotified();

      await tester.pumpAndSettle();
      expect(find.text('Outside Campus Perimeter'), findsOneWidget);
      expect(find.text('112 Emergency Services'), findsOneWidget);
    });

    testWidgets('restricts access for unauthorized viewer', (tester) async {
      final emergencyService = EmergencyService();
      emergencyService.startEmergency(sampleStudent);

      await tester.pumpWidget(
        MaterialApp(
          home: EmergencyScreen(
            student: sampleStudent,
            emergencyService: emergencyService,
            viewerId: 'UNAUTHORIZED_STRANGER',
            autoStartAutopilot: false,
          ),
        ),
      );

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.textContaining('You are not authorized to view this emergency session.'), findsOneWidget);
      expect(find.text('CANCEL EMERGENCY'), findsNothing);
    });
  });
}
