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

  Map<String, dynamic> toMap() {
    return {
      'emergencyId': emergencyId,
      'studentId': studentId,
      'createdAt': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'campusStatus': campusStatus.name,
      'status': status.name,
      'hostelBlock': hostelBlock,
      'roomNumber': roomNumber,
      'roommateNotified': roommateNotified,
      'wardenNotified': wardenNotified,
      'doctorNotified': doctorNotified,
      'parentNotified': parentNotified,
      'approvalFor112': approvalFor112,
      'liveTrackingActive': liveTrackingActive,
    };
  }

  factory EmergencyModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      try {
        final dynamic timestamp = val;
        if (timestamp != null && timestamp.toDate != null) {
          return timestamp.toDate() as DateTime;
        }
      } catch (_) {}
      return DateTime.now();
    }

    CampusStatus parseCampusStatus(String? name) {
      for (final val in CampusStatus.values) {
        if (val.name == name) return val;
      }
      return CampusStatus.unknown;
    }

    EmergencyStatus parseEmergencyStatus(String? name) {
      for (final val in EmergencyStatus.values) {
        if (val.name == name) return val;
      }
      return EmergencyStatus.idle;
    }

    return EmergencyModel(
      emergencyId: docId ?? (map['emergencyId'] as String? ?? ''),
      studentId: map['studentId'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      campusStatus: parseCampusStatus(map['campusStatus'] as String?),
      status: parseEmergencyStatus(map['status'] as String?),
      hostelBlock: map['hostelBlock'] as String?,
      roomNumber: map['roomNumber'] as String?,
      roommateNotified: map['roommateNotified'] as bool? ?? false,
      wardenNotified: map['wardenNotified'] as bool? ?? false,
      doctorNotified: map['doctorNotified'] as bool? ?? false,
      parentNotified: map['parentNotified'] as bool? ?? false,
      approvalFor112: map['approvalFor112'] as bool? ?? false,
      liveTrackingActive: map['liveTrackingActive'] as bool? ?? false,
    );
  }
}