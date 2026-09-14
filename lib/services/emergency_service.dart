import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_model.dart';
import '../models/student_model.dart';
import 'campus_geofence_service.dart';
import 'location_service.dart';

/// Function signature for phone dialer launcher to enable testability.
typedef DialerLauncher = Future<bool> Function(String phoneNumber);

class EmergencyService extends ChangeNotifier {
  EmergencyModel? _currentEmergency;
  Timer? _countdownTimer;
  StreamSubscription<Position>? _trackingSubscription;
  Completer<bool>? _countdownCompleter;
  int _countdownSeconds = 3;

  // ------------------------------------------------------------
  // CURRENT EMERGENCY
  // ------------------------------------------------------------

  EmergencyModel? get currentEmergency => _currentEmergency;
  int get countdownSeconds => _countdownSeconds;

  bool get hasActiveEmergency {
    return _currentEmergency != null &&
        _currentEmergency!.status != EmergencyStatus.resolved &&
        _currentEmergency!.status != EmergencyStatus.cancelled;
  }

  // ------------------------------------------------------------
  // AUTHORIZATION / PRIVACY
  // ------------------------------------------------------------

  /// Verifies whether the viewer is authorized to inspect emergency records.
  bool isAuthorizedViewer({
    required String viewerId,
    required StudentModel student,
  }) {
    if (viewerId.isEmpty) return false;
    return viewerId == student.studentId ||
        viewerId == student.phoneNumber ||
        viewerId == student.roommate1Phone ||
        viewerId == student.roommate2Phone ||
        viewerId == student.wardenPhone ||
        viewerId == student.parentPhone ||
        viewerId == 'DOCTOR_ON_CALL';
  }

  // ------------------------------------------------------------
  // DIALER FACILITATION
  // ------------------------------------------------------------

  /// Default dialer launcher using url_launcher (facilitates opening dialer without auto-calling).
  static Future<bool> defaultDialerLauncher(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------
  // START EMERGENCY
  // ------------------------------------------------------------

  EmergencyModel startEmergency(StudentModel student) {
    _countdownTimer?.cancel();
    stopLiveTracking();

    _currentEmergency = EmergencyModel(
      emergencyId: _generateEmergencyId(),
      studentId: student.studentId,
      createdAt: DateTime.now(),
      hostelBlock: student.hostelBlock,
      roomNumber: student.roomNumber,
      status: EmergencyStatus.countdown,
    );

    _countdownSeconds = 3;
    notifyListeners();
    return _currentEmergency!;
  }

  // ------------------------------------------------------------
  // 3-SECOND SAFETY COUNTDOWN
  // ------------------------------------------------------------

  void startCountdown({
    required void Function(int secondsRemaining) onTick,
    required void Function() onCompleted,
  }) {
    _countdownTimer?.cancel();
    _countdownSeconds = 3;

    _currentEmergency = _currentEmergency?.copyWith(
      status: EmergencyStatus.countdown,
    );
    notifyListeners();

    onTick(_countdownSeconds);

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _countdownSeconds--;
        notifyListeners();

        if (_countdownSeconds > 0) {
          onTick(_countdownSeconds);
        } else {
          timer.cancel();

          _currentEmergency = _currentEmergency?.copyWith(
            status: EmergencyStatus.locating,
          );
          notifyListeners();

          onCompleted();
        }
      },
    );
  }

  // ------------------------------------------------------------
  // EMERGENCY AUTOPILOT FLOW
  // ------------------------------------------------------------

  /// Orchestrates the entire emergency autopilot:
  /// Countdown -> Locating (GPS) -> Checking Campus (Geofence) -> Escalation -> Active Tracking
  Future<void> startEmergencyAutopilot({
    required StudentModel student,
    required LocationService locationService,
    required CampusGeofenceService geofenceService,
    Duration stepDelay = const Duration(milliseconds: 600),
    DialerLauncher? dialerLauncher,
  }) async {
    startEmergency(student);

    _countdownCompleter = Completer<bool>();

    startCountdown(
      onTick: (_) {},
      onCompleted: () {
        if (_countdownCompleter != null && !_countdownCompleter!.isCompleted) {
          _countdownCompleter!.complete(true);
        }
      },
    );

    final completed = await _countdownCompleter!.future;
    if (!completed || _currentEmergency?.status == EmergencyStatus.cancelled) {
      return;
    }

    // 1. Locating State
    if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
    if (_currentEmergency?.status == EmergencyStatus.cancelled) return;

    final coords = await locationService.getCurrentCoordinates();
    if (coords != null) {
      updateLocation(latitude: coords.latitude, longitude: coords.longitude);
    }

    // 2. Checking Campus State
    _currentEmergency = _currentEmergency?.copyWith(
      status: EmergencyStatus.checkingCampus,
    );
    notifyListeners();

    if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
    if (_currentEmergency?.status == EmergencyStatus.cancelled) return;

    final campusStatus = geofenceService.checkCoordinates(
      latitude: _currentEmergency?.latitude,
      longitude: _currentEmergency?.longitude,
    );
    updateCampusStatus(campusStatus);

    // 3. Escalation Sequence
    if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
    if (_currentEmergency?.status == EmergencyStatus.cancelled) return;

    if (campusStatus == CampusStatus.insideCampus) {
      // Inside Campus: Roommate -> Warden -> Campus Clinic/Doctor -> Parent -> Active
      markRoommateNotified();
      if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
      if (_currentEmergency?.status == EmergencyStatus.cancelled) return;

      markWardenNotified();
      if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
      if (_currentEmergency?.status == EmergencyStatus.cancelled) return;

      markDoctorNotified();
      if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
      if (_currentEmergency?.status == EmergencyStatus.cancelled) return;

      markParentNotified();
      if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
      if (_currentEmergency?.status == EmergencyStatus.cancelled) return;

      _currentEmergency = _currentEmergency?.copyWith(
        status: EmergencyStatus.active,
      );
      notifyListeners();

      // Start live GPS tracking during active emergency
      startLiveTracking(locationService);
    } else {
      // Outside Campus: Parent -> Warden -> Waiting for 112 Approval
      markParentNotified();
      if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
      if (_currentEmergency?.status == EmergencyStatus.cancelled) return;

      markWardenNotified();
      if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
      if (_currentEmergency?.status == EmergencyStatus.cancelled) return;

      _currentEmergency = _currentEmergency?.copyWith(
        status: EmergencyStatus.waitingFor112Approval,
      );
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // CANCEL EMERGENCY
  // ------------------------------------------------------------

  void cancelEmergency() {
    _countdownTimer?.cancel();
    if (_countdownCompleter != null && !_countdownCompleter!.isCompleted) {
      _countdownCompleter!.complete(false);
    }
    stopLiveTracking();

    if (_currentEmergency != null) {
      _currentEmergency = _currentEmergency!.copyWith(
        status: EmergencyStatus.cancelled,
        liveTrackingActive: false,
      );
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // 112 APPROVAL & DIALER FACILITATION
  // ------------------------------------------------------------

  /// Approves 112 emergency assistance, transitions to active,
  /// starts live tracking, and facilitates opening the phone dialer.
  Future<bool> approve112({
    required LocationService locationService,
    DialerLauncher? dialerLauncher,
  }) async {
    if (_currentEmergency == null) return false;

    set112Approval(true);
    startLiveTracking(locationService);

    final launcher = dialerLauncher ?? defaultDialerLauncher;
    return await launcher('112');
  }

  /// Dismisses 112 approval request while keeping emergency active with campus responders.
  void dismiss112Approval({required LocationService locationService}) {
    if (_currentEmergency == null) return;
    set112Approval(false);
    _currentEmergency = _currentEmergency?.copyWith(
      status: EmergencyStatus.active,
    );
    notifyListeners();
    startLiveTracking(locationService);
  }

  // ------------------------------------------------------------
  // UPDATE LOCATION
  // ------------------------------------------------------------

  void updateLocation({
    required double latitude,
    required double longitude,
  }) {
    _currentEmergency = _currentEmergency?.copyWith(
      latitude: latitude,
      longitude: longitude,
    );
    notifyListeners();
  }

  // ------------------------------------------------------------
  // UPDATE CAMPUS STATUS
  // ------------------------------------------------------------

  void updateCampusStatus(CampusStatus campusStatus) {
    _currentEmergency = _currentEmergency?.copyWith(
      campusStatus: campusStatus,
      status: EmergencyStatus.escalating,
    );
    notifyListeners();
  }

  // ------------------------------------------------------------
  // RESPONDER NOTIFICATIONS
  // ------------------------------------------------------------

  void markRoommateNotified() {
    _currentEmergency = _currentEmergency?.copyWith(
      roommateNotified: true,
    );
    notifyListeners();
  }

  void markWardenNotified() {
    _currentEmergency = _currentEmergency?.copyWith(
      wardenNotified: true,
    );
    notifyListeners();
  }

  void markDoctorNotified() {
    _currentEmergency = _currentEmergency?.copyWith(
      doctorNotified: true,
    );
    notifyListeners();
  }

  void markParentNotified() {
    _currentEmergency = _currentEmergency?.copyWith(
      parentNotified: true,
    );
    notifyListeners();
  }

  // ------------------------------------------------------------
  // 112 APPROVAL
  // ------------------------------------------------------------

  void set112Approval(bool approved) {
    _currentEmergency = _currentEmergency?.copyWith(
      approvalFor112: approved,
      status: approved
          ? EmergencyStatus.active
          : EmergencyStatus.escalating,
    );
    notifyListeners();
  }

  // ------------------------------------------------------------
  // LIVE LOCATION TRACKING
  // ------------------------------------------------------------

  /// Starts continuous live GPS tracking stream.
  void startLiveTracking(LocationService locationService) {
    _trackingSubscription?.cancel();
    setLiveTracking(true);

    _trackingSubscription = locationService.getPositionStream().listen(
      (position) {
        if (hasActiveEmergency) {
          updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      },
      onError: (_) {},
    );
  }

  /// Stops continuous live GPS tracking stream.
  void stopLiveTracking() {
    _trackingSubscription?.cancel();
    _trackingSubscription = null;
    if (_currentEmergency?.liveTrackingActive == true) {
      setLiveTracking(false);
    }
  }

  void setLiveTracking(bool active) {
    _currentEmergency = _currentEmergency?.copyWith(
      liveTrackingActive: active,
    );
    notifyListeners();
  }

  // ------------------------------------------------------------
  // RESOLVE EMERGENCY
  // ------------------------------------------------------------

  void resolveEmergency() {
    _countdownTimer?.cancel();
    if (_countdownCompleter != null && !_countdownCompleter!.isCompleted) {
      _countdownCompleter!.complete(false);
    }
    stopLiveTracking();

    if (_currentEmergency != null) {
      _currentEmergency = _currentEmergency!.copyWith(
        status: EmergencyStatus.resolved,
        liveTrackingActive: false,
      );
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // GENERATE EMERGENCY ID
  // ------------------------------------------------------------

  String _generateEmergencyId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'EMG-$timestamp';
  }

  // ------------------------------------------------------------
  // CLEAN UP
  // ------------------------------------------------------------

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _trackingSubscription?.cancel();
    super.dispose();
  }
}