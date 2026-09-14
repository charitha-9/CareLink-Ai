import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carelink_mobile/models/care_facility_model.dart';
import 'package:carelink_mobile/screens/emergency_history_screen.dart';
import 'package:carelink_mobile/screens/facility_details_screen.dart';
import 'package:carelink_mobile/screens/home_screen.dart';
import 'package:carelink_mobile/screens/nearby_care_screen.dart';
import 'package:carelink_mobile/services/campus_directory_care_service.dart';
import 'package:carelink_mobile/services/nearby_care_service.dart';
import 'package:carelink_mobile/theme/app_theme.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('HomeScreen renders brand title, Emergency SOS, and navigation cards', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('CareLink AI'), findsOneWidget);
      expect(find.text('EMERGENCY SOS'), findsOneWidget);
      expect(find.text('AI Health Check'), findsOneWidget);
      expect(find.text('Nearby Care'), findsOneWidget);
      expect(find.text('Emergency Logs'), findsOneWidget);
      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('Direct Emergency Hotlines'), findsOneWidget);
    });

    testWidgets('Tapping Emergency SOS displays safety confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('EMERGENCY SOS'));
      await tester.pump();

      expect(find.text('Emergency SOS'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm Now'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Now'), findsNothing);
    });
  });

  group('NearbyCareScreen Widget Tests', () {
    late NearbyCareService testService;

    setUp(() {
      testService = NearbyCareService(repository: CampusDirectoryCareService());
    });

    testWidgets('NearbyCareScreen renders tabs, search bar, and facility cards', (tester) async {
      await tester.pumpWidget(createTestWidget(
        NearbyCareScreen(service: testService),
      ));

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete async fetch
      await tester.pumpAndSettle();

      expect(find.text('Nearby Care Navigation'), findsOneWidget);
      expect(find.text('All Facilities'), findsOneWidget);
      expect(find.text('Hospitals'), findsOneWidget);
      expect(find.text('Clinics'), findsOneWidget);

      // Verified facilities should be visible
      expect(find.text('Amity University Campus Health Center'), findsOneWidget);
      expect(find.text('Directions'), findsWidgets);
    });

    testWidgets('NearbyCareScreen hospital tab filters list', (tester) async {
      await tester.pumpWidget(createTestWidget(
        NearbyCareScreen(service: testService),
      ));
      await tester.pumpAndSettle();

      // Tap Hospitals tab
      await tester.tap(find.text('Hospitals'));
      await tester.pumpAndSettle();

      // Jaypee Hospital or Fortis Hospital should be in the list
      expect(find.text('Jaypee Hospital'), findsOneWidget);
    });
  });

  group('FacilityDetailsScreen Widget Tests', () {
    const testFacility = CareFacility(
      id: 'test-fac',
      name: 'Amity University Campus Health Center',
      type: CareFacilityType.campusHealthCenter,
      address: 'Student Centre, Sector 125, Noida',
      phone: '+91 120 439 2000',
      isOpen: true,
      operatingHours: '24 Hours Emergency Service',
      emergencyServicesAvailable: true,
      distanceKm: 0.1,
    );

    testWidgets('FacilityDetailsScreen renders facility data, action buttons, and disclaimer', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const FacilityDetailsScreen(facility: testFacility),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Amity University Campus Health Center'), findsWidgets);
      expect(find.text('Student Centre, Sector 125, Noida'), findsOneWidget);
      expect(find.text('Call Facility'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
      expect(find.text('Verified Healthcare Directory'), findsOneWidget);
    });
  });

  group('EmergencyHistoryScreen Widget Tests', () {
    testWidgets('EmergencyHistoryScreen renders empty state when no incidents recorded', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const EmergencyHistoryScreen(initialHistory: []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Emergency History'), findsOneWidget);
      expect(find.text('No Emergency Incidents'), findsOneWidget);
    });
  });
}
