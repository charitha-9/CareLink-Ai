enum EmergencyStatus {
  idle,
  countdown,
  locating,
  checkingCampus,
  escalating,
  waitingFor112Approval,
  active,
  resolved,
  cancelled,
}

enum CampusStatus {
  unknown,
  insideCampus,
  outsideCampus,
}

class EmergencyModel {
  final String emergencyId;
  final String studentId;
  final DateTime createdAt;

  final double? latitude;
  final double? longitude;

  final CampusStatus campusStatus;
  final EmergencyStatus status;

  final String? hostelBlock;
  final String? roomNumber;

  final bool roommateNotified;
  final bool wardenNotified;
  final bool doctorNotified;
  final bool parentNotified;

  final bool approvalFor112;
  final bool liveTrackingActive;

  const EmergencyModel({
    required this.emergencyId,
    required this.studentId,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.campusStatus = CampusStatus.unknown,
    this.status = EmergencyStatus.idle,
    this.hostelBlock,
    this.roomNumber,
    this.roommateNotified = false,
    this.wardenNotified = false,
    this.doctorNotified = false,
    this.parentNotified = false,
    this.approvalFor112 = false,
    this.liveTrackingActive = false,
  });

  EmergencyModel copyWith({
    String? emergencyId,
    String? studentId,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    CampusStatus? campusStatus,
    EmergencyStatus? status,
    String? hostelBlock,
    String? roomNumber,
    bool? roommateNotified,
    bool? wardenNotified,
    bool? doctorNotified,
    bool? parentNotified,
    bool? approvalFor112,
    bool? liveTrackingActive,
  }) {
    return EmergencyModel(
      emergencyId: emergencyId ?? this.emergencyId,
      studentId: studentId ?? this.studentId,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      campusStatus: campusStatus ?? this.campusStatus,
      status: status ?? this.status,
      hostelBlock: hostelBlock ?? this.hostelBlock,
      roomNumber: roomNumber ?? this.roomNumber,
      roommateNotified:
          roommateNotified ?? this.roommateNotified,
      wardenNotified:
          wardenNotified ?? this.wardenNotified,
      doctorNotified:
          doctorNotified ?? this.doctorNotified,
      parentNotified:
          parentNotified ?? this.parentNotified,
      approvalFor112:
          approvalFor112 ?? this.approvalFor112,
      liveTrackingActive:
          liveTrackingActive ?? this.liveTrackingActive,
    );
  }
}