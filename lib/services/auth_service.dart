import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/student_model.dart';

/// Exception thrown when an authentication or registration error occurs.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Service managing student authentication state, registration, and active profile.
///
/// Designed to be decoupled from specific backends so that the backend teammate
/// can seamlessly connect Firebase Authentication and Cloud Firestore later
/// without modifying the UI layer.
class AuthService extends ChangeNotifier {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  AuthService._internal() {
    // Seed with a default student account for offline/testing convenience
    _seedInitialStudent();
  }

  /// Visible for testing to instantiate isolated auth service instances
  @visibleForTesting
  AuthService.forTesting();

  StudentModel? _currentStudent;
  final StreamController<StudentModel?> _authStateController =
      StreamController<StudentModel?>.broadcast();

  // In-memory credential and student store for local execution before Firebase is connected
  final Map<String, String> _credentialsByEmail = {};
  final Map<String, StudentModel> _studentsByEmail = {};

  /// Expose the current logged-in student's profile to other CareLink modules
  StudentModel? get currentStudent => _currentStudent;

  /// Whether a student is currently authenticated
  bool get isAuthenticated => _currentStudent != null;

  /// Stream of authentication state changes
  Stream<StudentModel?> get authStateChanges => _authStateController.stream;

  // ------------------------------------------------------------
  // INITIAL SEEDING (Local testing before Firebase setup)
  // ------------------------------------------------------------

  void _seedInitialStudent() {
    const demoStudent = StudentModel(
      studentId: 'STU-2024-089',
      name: 'Charitha Silva',
      phone: '+94 77 123 4567',
      email: 'student@carelink.edu',
      hostel: 'Emerald Hall',
      block: 'B',
      room: 'B-304',
      campusId: 'CAMPUS-MAIN',
      campusName: 'Main Campus',
      parentName: 'Sunil Silva',
      parentPhone: '+94 71 987 6543',
      roommate1Name: 'Kasun Perera',
      roommate1Phone: '+94 76 555 1234',
      roommate2Name: 'Nuwan Fernando',
      roommate2Phone: '+94 78 444 5678',
      wardenPhone: '+94 70 111 2233',
    );

    _studentsByEmail[demoStudent.email.toLowerCase().trim()] = demoStudent;
    _credentialsByEmail[demoStudent.email.toLowerCase().trim()] = 'CareLink@2024';
  }

  // ------------------------------------------------------------
  // FEATURE 1: LOGIN
  // ------------------------------------------------------------

  /// Authenticate a student with email and password.
  ///
  /// BACKEND NOTE:
  /// When Firebase is connected, replace or delegate this implementation with:
  /// ```dart
  /// final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  ///   email: email.trim(),
  ///   password: password,
  /// );
  /// final uid = credential.user!.uid;
  /// final doc = await FirebaseFirestore.instance.collection('students').doc(uid).get();
  /// final student = StudentModel.fromMap(doc.data()!);
  /// ```
  Future<StudentModel> login({
    required String email,
    required String password,
  }) async {
    final sanitizedEmail = email.trim().toLowerCase();

    // Basic validation
    if (sanitizedEmail.isEmpty) {
      throw const AuthException('Please enter your campus email address.');
    }
    if (password.isEmpty) {
      throw const AuthException('Please enter your password.');
    }

    // Simulated network latency for realistic UX & testing loading state
    await Future.delayed(const Duration(milliseconds: 600));

    // Verify student exists
    if (!_studentsByEmail.containsKey(sanitizedEmail)) {
      throw const AuthException(
        'No account found with this email. Please check your credentials or sign up.',
      );
    }

    // Verify password match
    final storedPassword = _credentialsByEmail[sanitizedEmail];
    if (storedPassword != password) {
      throw const AuthException('Incorrect password. Please try again.');
    }

    final student = _studentsByEmail[sanitizedEmail]!;
    _currentStudent = student;
    _authStateController.add(_currentStudent);
    notifyListeners();

    return student;
  }

  // ------------------------------------------------------------
  // FEATURE 2: SIGNUP
  // ------------------------------------------------------------

  /// Register a new student profile and credentials.
  ///
  /// Validates required fields, checks for duplicate accounts, and sets
  /// the active student profile.
  ///
  /// BACKEND NOTE:
  /// When Firebase is connected, replace or delegate this implementation with:
  /// ```dart
  /// final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  ///   email: student.email.trim(),
  ///   password: password,
  /// );
  /// final uid = credential.user!.uid;
  /// await FirebaseFirestore.instance.collection('students').doc(uid).set(student.toMap());
  /// ```
  Future<StudentModel> signup({
    required StudentModel student,
    required String password,
  }) async {
    final sanitizedEmail = student.email.trim().toLowerCase();

    // Validation
    if (student.name.trim().isEmpty) {
      throw const AuthException('Full name is required.');
    }
    if (student.studentId.trim().isEmpty) {
      throw const AuthException('Student ID is required.');
    }
    if (student.phone.trim().isEmpty) {
      throw const AuthException('Phone number is required.');
    }
    if (sanitizedEmail.isEmpty || !sanitizedEmail.contains('@')) {
      throw const AuthException('A valid email address is required.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters long.');
    }
    if (student.hostel.trim().isEmpty) {
      throw const AuthException('Hostel name is required.');
    }
    if (student.block.trim().isEmpty) {
      throw const AuthException('Block identifier is required.');
    }
    if (student.room.trim().isEmpty) {
      throw const AuthException('Room number is required.');
    }
    if (student.parentName.trim().isEmpty) {
      throw const AuthException('Parent / Guardian name is required.');
    }
    if (student.parentPhone.trim().isEmpty) {
      throw const AuthException('Parent / Guardian phone number is required.');
    }

    // Simulated network latency
    await Future.delayed(const Duration(milliseconds: 700));

    // Check duplicate
    if (_studentsByEmail.containsKey(sanitizedEmail)) {
      throw const AuthException(
        'An account with this email already exists. Please log in instead.',
      );
    }

    // Store student profile and credentials
    _studentsByEmail[sanitizedEmail] = student;
    _credentialsByEmail[sanitizedEmail] = password;

    _currentStudent = student;
    _authStateController.add(_currentStudent);
    notifyListeners();

    return student;
  }

  // ------------------------------------------------------------
  // PROFILE MANAGEMENT
  // ------------------------------------------------------------

  /// Update the active student profile details.
  Future<void> updateProfile(StudentModel updatedStudent) async {
    final sanitizedEmail = updatedStudent.email.trim().toLowerCase();
    _studentsByEmail[sanitizedEmail] = updatedStudent;
    _currentStudent = updatedStudent;
    _authStateController.add(_currentStudent);
    notifyListeners();
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------

  /// Log out the currently authenticated student.
  Future<void> logout() async {
    _currentStudent = null;
    _authStateController.add(null);
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}
