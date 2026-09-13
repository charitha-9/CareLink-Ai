enum ParentLinkStatus {
  pending,
  approved,
  rejected,
}

class ParentGuardianLinkModel {
  final String linkId;
  final String studentId;
  final String parentName;
  final String parentPhone;
  final String? parentEmail;
  final String relationship;
  final ParentLinkStatus status;
  final DateTime linkedAt;
  final String? studentName;

  const ParentGuardianLinkModel({
    required this.linkId,
    required this.studentId,
    required this.parentName,
    required this.parentPhone,
    this.parentEmail,
    required this.relationship,
    this.status = ParentLinkStatus.pending,
    required this.linkedAt,
    this.studentName,
  });

  ParentGuardianLinkModel copyWith({
    String? linkId,
    String? studentId,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? relationship,
    ParentLinkStatus? status,
    DateTime? linkedAt,
    String? studentName,
  }) {
    return ParentGuardianLinkModel(
      linkId: linkId ?? this.linkId,
      studentId: studentId ?? this.studentId,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      relationship: relationship ?? this.relationship,
      status: status ?? this.status,
      linkedAt: linkedAt ?? this.linkedAt,
      studentName: studentName ?? this.studentName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'linkId': linkId,
      'studentId': studentId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'parentEmail': parentEmail,
      'relationship': relationship,
      'status': status.name,
      'linkedAt': linkedAt.toIso8601String(),
      'studentName': studentName,
    };
  }

  factory ParentGuardianLinkModel.fromMap(
    Map<String, dynamic> map, [
    String? docId,
  ]) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      try {
        final dynamic timestamp = val;
        if (timestamp != null && timestamp.toDate != null) {
          return timestamp.toDate() as DateTime;
        }
      } catch (_) {}
      return DateTime.now();
    }

    ParentLinkStatus parseStatus(String? name) {
      for (final val in ParentLinkStatus.values) {
        if (val.name == name) return val;
      }
      return ParentLinkStatus.pending;
    }

    return ParentGuardianLinkModel(
      linkId: docId ?? (map['linkId'] as String? ?? ''),
      studentId: map['studentId'] as String? ?? '',
      parentName: map['parentName'] as String? ?? '',
      parentPhone: map['parentPhone'] as String? ?? '',
      parentEmail: map['parentEmail'] as String?,
      relationship: map['relationship'] as String? ?? 'Guardian',
      status: parseStatus(map['status'] as String?),
      linkedAt: parseDate(map['linkedAt']),
      studentName: map['studentName'] as String?,
    );
  }
}