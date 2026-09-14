import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/student_model.dart';

/// Exception thrown when an authentication or registration error occurs.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Unified Service managing student authentication state, registration, active profile,
/// and Firebase Authentication integration.
class AuthService extends ChangeNotifier {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  final FirebaseAuth? _injectedAuth;
  final bool _isTestMode;

  /// Default constructor supporting dependency injection for [FirebaseAuth].
  AuthService({FirebaseAuth? auth})
      : _injectedAuth = auth,
        _isTestMode = false {
    _seedInitialStudent();
  }

  AuthService._internal()
      : _injectedAuth = null,
        _isTestMode = false {
    _seedInitialStudent();
  }

  /// Visible for testing to instantiate isolated auth service instances without Firebase.
  @visibleForTesting
  AuthService.forTesting()
      : _injectedAuth = null,
        _isTestMode = true;

  StudentModel? _currentStudent;
  final StreamController<StudentModel?> _authStateController =
      StreamController<StudentModel?>.broadcast();

  // In-memory credential and student store for local execution / offline testing
  final Map<String, String> _credentialsByEmail = {};
  final Map<String, StudentModel> _studentsByEmail = {};

  /// Safe accessor for [FirebaseAuth] that avoids throwing when Firebase is not initialized.
  FirebaseAuth? get _auth {
    if (_injectedAuth != null) return _injectedAuth;
    if (_isTestMode) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Expose the current logged-in student's profile to other CareLink modules
  StudentModel? get currentStudent => _currentStudent;

  /// Current Firebase User if authenticated via Firebase
  User? get currentUser => _auth?.currentUser;

  /// Current user ID (Firebase UID if available, else studentId)
  String? get currentUserId =>
      _auth?.currentUser?.uid ?? _currentStudent?.studentId;

  /// Whether a student is currently authenticated
  bool get isAuthenticated =>
      (_auth?.currentUser != null) || (_currentStudent != null);

  /// Stream of student profile authentication state changes
  Stream<StudentModel?> get studentAuthStateChanges =>
      _authStateController.stream;

  /// Stream of Firebase Authentication state changes
  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

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
    _credentialsByEmail[demoStudent.email.toLowerCase().trim()] =
        'CareLink@2024';
  }

  // ------------------------------------------------------------
  // FEATURE 1: LOGIN
  // ------------------------------------------------------------

  /// Authenticate a student with email and password.
  ///
  /// Supports in-memory test/demo accounts and seamlessly delegates
  /// to Firebase Authentication when connected.
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

    if (!_isTestMode) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Check in-memory store first
    if (_studentsByEmail.containsKey(sanitizedEmail)) {
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

    // Firebase Authentication fallback if available
    final fb = _auth;
    if (fb != null && !_isTestMode) {
      try {
        final credential = await fb.signInWithEmailAndPassword(
          email: sanitizedEmail,
          password: password,
        );

        final uid = credential.user?.uid;
        if (uid != null) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get();
            if (doc.exists && doc.data() != null) {
              final student = StudentModel.fromMap(doc.data()!, doc.id);
              _currentStudent = student;
              _authStateController.add(_currentStudent);
              notifyListeners();
              return student;
            }
          } catch (_) {}
        }

        final fallbackStudent = StudentModel(
          studentId: uid ?? 'STU-${DateTime.now().millisecondsSinceEpoch}',
          name: credential.user?.displayName ?? 'Student',
          email: sanitizedEmail,
          phone: credential.user?.phoneNumber ?? '',
        );
        _currentStudent = fallbackStudent;
        _authStateController.add(_currentStudent);
        notifyListeners();
        return fallbackStudent;
      } on FirebaseAuthException catch (e) {
        throw AuthException(e.message ?? 'Sign in failed.');
      } catch (e) {
        throw AuthException(e.toString());
      }
    }

    throw const AuthException(
      'No account found with this email. Please check your credentials or sign up.',
    );
  }

  // ------------------------------------------------------------
  // FEATURE 2: SIGNUP
  // ------------------------------------------------------------

  /// Register a new student profile and credentials.
  ///
  /// Validates required fields, checks for duplicate accounts, and sets
  /// the active student profile locally and in Firebase when connected.
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

    if (!_isTestMode) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Check duplicate
    if (_studentsByEmail.containsKey(sanitizedEmail)) {
      throw const AuthException(
        'An account with this email already exists. Please log in instead.',
      );
    }

    // Try Firebase registration if available
    final fb = _auth;
    if (fb != null && !_isTestMode) {
      try {
        final credential = await fb.createUserWithEmailAndPassword(
          email: sanitizedEmail,
          password: password,
        );
        final uid = credential.user?.uid ?? student.studentId;
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set(student.toMap(), SetOptions(merge: true));
        } catch (_) {}
      } on FirebaseAuthException catch (e) {
        throw AuthException(e.message ?? 'Registration failed.');
      }
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
  // FIREBASE AUTHENTICATION API (Manoj Implementation)
  // ------------------------------------------------------------

  /// Sign in with Firebase email and password directly.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final fb = _auth;
    if (fb == null) {
      throw const AuthException('Firebase Authentication is not available.');
    }
    try {
      final credential = await fb.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          if (doc.exists && doc.data() != null) {
            final student = StudentModel.fromMap(doc.data()!, doc.id);
            _currentStudent = student;
            _authStateController.add(_currentStudent);
            notifyListeners();
          }
        } catch (_) {}
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign in failed.');
    }
  }

  /// Register user with Firebase email and password directly.
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final fb = _auth;
    if (fb == null) {
      throw const AuthException('Firebase Authentication is not available.');
    }
    try {
      return await fb.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Registration failed.');
    }
  }

  /// Send a password reset email via Firebase.
  Future<void> sendPasswordResetEmail(String email) async {
    final fb = _auth;
    if (fb != null) {
      await fb.sendPasswordResetEmail(email: email.trim());
    }
  }

  /// Sign out from Firebase and clear the local student session.
  Future<void> signOut() async {
    await logout();
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

    final fb = _auth;
    if (fb != null && !_isTestMode) {
      final uid = fb.currentUser?.uid ?? updatedStudent.studentId;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(updatedStudent.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------

  /// Log out the currently authenticated student and Firebase session.
  Future<void> logout() async {
    final fb = _auth;
    if (fb != null) {
      try {
        await fb.signOut();
      } catch (_) {}
    }
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
