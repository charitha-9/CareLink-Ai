import 'dart:async';

import '../models/emergency_model.dart';
import '../models/student_model.dart';

class EmergencyService {
  EmergencyModel? _currentEmergency;

  Timer? _countdownTimer;

  int _countdownSeconds = 3;

  // ------------------------------------------------------------
  // CURRENT EMERGENCY
  // ------------------------------------------------------------

  EmergencyModel? get currentEmergency => _currentEmergency;

  bool get hasActiveEmergency {
    return _currentEmergency != null &&
        _currentEmergency!.status != EmergencyStatus.resolved &&
        _currentEmergency!.status != EmergencyStatus.cancelled;
  }

  // ------------------------------------------------------------
  // START EMERGENCY
  // ------------------------------------------------------------

  EmergencyModel startEmergency(StudentModel student) {
    _currentEmergency = EmergencyModel(
      emergencyId: _generateEmergencyId(),
      studentId: student.studentId,
      createdAt: DateTime.now(),
      hostelBlock: student.hostelBlock,
      roomNumber: student.roomNumber,
      status: EmergencyStatus.countdown,
    );

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

    onTick(_countdownSeconds);

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _countdownSeconds--;

        if (_countdownSeconds > 0) {
          onTick(_countdownSeconds);
        } else {
          timer.cancel();

          _currentEmergency = _currentEmergency?.copyWith(
            status: EmergencyStatus.locating,
          );

          onCompleted();
        }
      },
    );
  }

  // ------------------------------------------------------------
  // CANCEL EMERGENCY
  // ------------------------------------------------------------

  void cancelEmergency() {
    _countdownTimer?.cancel();

    if (_currentEmergency != null) {
      _currentEmergency = _currentEmergency!.copyWith(
        status: EmergencyStatus.cancelled,
      );
    }
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
  }

  // ------------------------------------------------------------
  // UPDATE CAMPUS STATUS
  // ------------------------------------------------------------

  void updateCampusStatus(CampusStatus campusStatus) {
    _currentEmergency = _currentEmergency?.copyWith(
      campusStatus: campusStatus,
      status: EmergencyStatus.escalating,
    );
  }

  // ------------------------------------------------------------
  // RESPONDER NOTIFICATIONS
  // ------------------------------------------------------------

  void markRoommateNotified() {
    _currentEmergency = _currentEmergency?.copyWith(
      roommateNotified: true,
    );
  }

  void markWardenNotified() {
    _currentEmergency = _currentEmergency?.copyWith(
      wardenNotified: true,
    );
  }

  void markDoctorNotified() {
    _currentEmergency = _currentEmergency?.copyWith(
      doctorNotified: true,
    );
  }

  void markParentNotified() {
    _currentEmergency = _currentEmergency?.copyWith(
      parentNotified: true,
    );
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
  }

  // ------------------------------------------------------------
  // LIVE TRACKING
  // ------------------------------------------------------------

  void setLiveTracking(bool active) {
    _currentEmergency = _currentEmergency?.copyWith(
      liveTrackingActive: active,
    );
  }

  // ------------------------------------------------------------
  // RESOLVE EMERGENCY
  // ------------------------------------------------------------

  void resolveEmergency() {
    _countdownTimer?.cancel();

    _currentEmergency = _currentEmergency?.copyWith(
      status: EmergencyStatus.resolved,
      liveTrackingActive: false,
    );
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

  void dispose() {
    _countdownTimer?.cancel();
  }
}