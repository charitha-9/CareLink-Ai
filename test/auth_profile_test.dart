import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carelink_mobile/main.dart';
import 'package:carelink_mobile/models/student_model.dart';
import 'package:carelink_mobile/screens/login_screen.dart';
import 'package:carelink_mobile/screens/profile_screen.dart';
import 'package:carelink_mobile/screens/signup_screen.dart';
import 'package:carelink_mobile/services/auth_service.dart';
import 'package:carelink_mobile/services/emergency_service.dart';

void main() {
  group('StudentModel Tests', () {
    test('StudentModel stores all required profile fields and compatibility getters', () {
      const student = StudentModel(
        studentId: 'STU-001',
        name: 'Jane Doe',
        phone: '+94 77 123 4567',
        email: 'jane@campus.edu',
        hostel: 'Lotus Hall',
        block: 'C',
        room: '204',
        parentName: 'John Doe',
        parentPhone: '+94 71 987 6543',
        roommate1Name: 'Alice',
        roommate1Phone: '+94 76 111 2233',
        roommate2Name: 'Beth',
        roommate2Phone: '+94 78 444 5566',
        wardenPhone: '+94 70 999 8877',
      );

      // Verify all required exposed fields
      expect(student.studentId, 'STU-001');
      expect(student.name, 'Jane Doe');
      expect(student.phone, '+94 77 123 4567');
      expect(student.email, 'jane@campus.edu');
      expect(student.hostel, 'Lotus Hall');
      expect(student.block, 'C');
      expect(student.room, '204');
      expect(student.parentName, 'John Doe');
      expect(student.parentPhone, '+94 71 987 6543');
      expect(student.roommate1Name, 'Alice');
      expect(student.roommate1Phone, '+94 76 111 2233');
      expect(student.roommate2Name, 'Beth');
      expect(student.roommate2Phone, '+94 78 444 5566');

      // Verify teammate compatibility getters
      expect(student.phoneNumber, '+94 77 123 4567');
      expect(student.roomNumber, '204');
      expect(student.hostelBlock, 'Lotus Hall - Block C');
    });

    test('StudentModel serialization to and from Map works (Firebase compatibility)', () {
      const original = StudentModel(
        studentId: 'STU-002',
        name: 'Alex Smith',
        phone: '+94 77 999 8888',
        email: 'alex@campus.edu',
        hostel: 'Oak Hall',
        block: 'A',
        room: '101',
        parentName: 'Mary Smith',
        parentPhone: '+94 71 222 3333',
        roommate1Name: 'Bob',
        roommate1Phone: '+94 76 333 4444',
      );

      final map = original.toMap();
      final restored = StudentModel.fromMap(map);

      expect(restored.studentId, original.studentId);
      expect(restored.name, original.name);
      expect(restored.phone, original.phone);
      expect(restored.email, original.email);
      expect(restored.hostel, original.hostel);
      expect(restored.block, original.block);
      expect(restored.room, original.room);
      expect(restored.parentName, original.parentName);
      expect(restored.parentPhone, original.parentPhone);
      expect(restored.roommate1Name, original.roommate1Name);
      expect(restored.roommate1Phone, original.roommate1Phone);
    });

    test('Teammate EmergencyService works seamlessly with StudentModel', () {
      final emergencyService = EmergencyService();
      const student = StudentModel(
        studentId: 'STU-999',
        name: 'Test Student',
        phone: '+94 77 000 1111',
        email: 'test@campus.edu',
        hostel: 'Cedar Hall',
        block: 'D',
        room: '405',
        parentName: 'Parent Test',
        parentPhone: '+94 71 000 2222',
      );

      final emergency = emergencyService.startEmergency(student);

      expect(emergency.studentId, 'STU-999');
      expect(emergency.roomNumber, '405');
      expect(emergency.hostelBlock, 'Cedar Hall - Block D');
    });
  });

  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService.forTesting();
    });

    test('signup creates account and sets active currentStudent', () async {
      const student = StudentModel(
        studentId: 'STU-101',
        name: 'Kasun Dias',
        phone: '+94 77 444 5555',
        email: 'kasun@carelink.edu',
        hostel: 'Nilwala',
        block: 'A',
        room: 'A-12',
        parentName: 'Sunil Dias',
        parentPhone: '+94 71 888 9999',
        roommate1Name: 'Nimal',
        roommate1Phone: '+94 76 222 3333',
      );

      final registered = await authService.signup(
        student: student,
        password: 'Password123!',
      );

      expect(registered.studentId, 'STU-101');
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentStudent?.name, 'Kasun Dias');

      // Test logging out
      await authService.logout();
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentStudent, isNull);

      // Test logging in again
      final loggedIn = await authService.login(
        email: 'kasun@carelink.edu',
        password: 'Password123!',
      );
      expect(loggedIn.email, 'kasun@carelink.edu');
      expect(authService.isAuthenticated, isTrue);
    });

    test('login with incorrect password throws AuthException', () async {
      const student = StudentModel(
        studentId: 'STU-102',
        name: 'Sarah Connor',
        phone: '+94 77 111 2222',
        email: 'sarah@carelink.edu',
        hostel: 'Victoria',
        block: '1',
        room: '102',
        parentName: 'John Connor',
        parentPhone: '+94 71 333 4444',
      );

      await authService.signup(student: student, password: 'SecurePassword123');

      expect(
        () => authService.login(
          email: 'sarah@carelink.edu',
          password: 'WrongPassword',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('UI & Navigation Widget Tests', () {
    testWidgets('CareLinkApp launches into LoginScreen by default', (tester) async {
      await tester.pumpWidget(const CareLinkApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to CareLink AI'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Campus Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('LoginScreen validates empty input fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      expect(signInButton, findsOneWidget);

      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Navigating from LoginScreen to SignupScreen displays form sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/home': (context) => const CareLinkHomePage(),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign Up link
      final signUpLink = find.text('Sign Up');
      expect(signUpLink, findsOneWidget);
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      // Verify SignupScreen is presented with all required sections
      expect(find.text('Student Registration'), findsOneWidget);
      expect(find.text('Student & Account Details'), findsOneWidget);
      expect(find.text('Campus Residence'), findsOneWidget);
      expect(find.text('Emergency Contacts'), findsOneWidget);
      expect(find.text('Register Profile'), findsOneWidget);
    });

    testWidgets('ProfileScreen displays student information and GPS notice', (tester) async {
      const student = StudentModel(
        studentId: 'STU-TEST-01',
        name: 'Kamal Bandara',
        phone: '+94 77 987 6543',
        email: 'kamal@carelink.edu',
        hostel: 'Mahaweli Hall',
        block: 'C',
        room: 'C-201',
        parentName: 'Sunimal Bandara',
        parentPhone: '+94 71 555 6666',
        roommate1Name: 'Rohan',
        roommate1Phone: '+94 76 777 8888',
        roommate2Name: 'Sahan',
        roommate2Phone: '+94 78 999 0000',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(student: student),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('Kamal Bandara'), findsOneWidget);
      expect(find.text('ID: STU-TEST-01'), findsOneWidget);
      expect(find.text('Mahaweli Hall'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('C-201'), findsOneWidget);
      expect(find.text('+94 77 987 6543'), findsOneWidget);
      expect(find.text('Sunimal Bandara (+94 71 555 6666)'), findsOneWidget);
      expect(find.text('Rohan (+94 76 777 8888)'), findsOneWidget);
      expect(find.text('Sahan (+94 78 999 0000)'), findsOneWidget);

      // Verify GPS notice
      expect(find.textContaining('Residence & GPS Dispatch'), findsOneWidget);

      // Verify Continue to CareLink Home button
      expect(find.text('Continue to CareLink Home'), findsOneWidget);
    });

    testWidgets('Existing CareLinkHomePage renders with Emergency button and Profile action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/profile': (context) => const ProfileScreen(),
          },
          home: const CareLinkHomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify original Home screen elements remain intact
      expect(find.text('CareLink AI'), findsNWidgets(2));
      expect(find.text('Hello! 👋'), findsOneWidget);
      expect(find.text('EMERGENCY'), findsOneWidget);
      expect(find.text('AI Health Check'), findsOneWidget);
      expect(find.text('Nearby Care'), findsOneWidget);

      // Verify Profile button in AppBar
      expect(find.byIcon(Icons.account_circle), findsOneWidget);
    });
  });
}
