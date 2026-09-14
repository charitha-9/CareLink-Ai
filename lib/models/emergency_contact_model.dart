class EmergencyContactModel {
  final String contactId;
  final String studentId;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;
  final DateTime createdAt;

  const EmergencyContactModel({
    required this.contactId,
    required this.studentId,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isPrimary = false,
    required this.createdAt,
  });

  EmergencyContactModel copyWith({
    String? contactId,
    String? studentId,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return EmergencyContactModel(
      contactId: contactId ?? this.contactId,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contactId': contactId,
      'studentId': studentId,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmergencyContactModel.fromMap(
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

    return EmergencyContactModel(
      contactId: docId ?? (map['contactId'] as String? ?? ''),
      studentId: map['studentId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      relationship: map['relationship'] as String? ?? 'Contact',
      isPrimary: map['isPrimary'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}