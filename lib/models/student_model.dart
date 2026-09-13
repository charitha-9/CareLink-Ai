class StudentModel {
  final String studentId;
  final String name;
  final String phoneNumber;

  // Campus information
  final String campusId;
  final String campusName;

  // Hostel information
  final String? hostelBlock;
  final String? roomNumber;

  // Trusted contacts
  final String? roommate1Phone;
  final String? roommate2Phone;
  final String? wardenPhone;
  final String? parentPhone;

  // Account and notification fields
  final String? email;
  final String? fcmToken;

  const StudentModel({
    required this.studentId,
    required this.name,
    required this.phoneNumber,
    required this.campusId,
    required this.campusName,
    this.hostelBlock,
    this.roomNumber,
    this.roommate1Phone,
    this.roommate2Phone,
    this.wardenPhone,
    this.parentPhone,
    this.email,
    this.fcmToken,
  });

  StudentModel copyWith({
    String? studentId,
    String? name,
    String? phoneNumber,
    String? campusId,
    String? campusName,
    String? hostelBlock,
    String? roomNumber,
    String? roommate1Phone,
    String? roommate2Phone,
    String? wardenPhone,
    String? parentPhone,
    String? email,
    String? fcmToken,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      campusId: campusId ?? this.campusId,
      campusName: campusName ?? this.campusName,
      hostelBlock: hostelBlock ?? this.hostelBlock,
      roomNumber: roomNumber ?? this.roomNumber,
      roommate1Phone: roommate1Phone ?? this.roommate1Phone,
      roommate2Phone: roommate2Phone ?? this.roommate2Phone,
      wardenPhone: wardenPhone ?? this.wardenPhone,
      parentPhone: parentPhone ?? this.parentPhone,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'name': name,
      'phoneNumber': phoneNumber,
      'campusId': campusId,
      'campusName': campusName,
      'hostelBlock': hostelBlock,
      'roomNumber': roomNumber,
      'roommate1Phone': roommate1Phone,
      'roommate2Phone': roommate2Phone,
      'wardenPhone': wardenPhone,
      'parentPhone': parentPhone,
      'email': email,
      'fcmToken': fcmToken,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return StudentModel(
      studentId: docId ?? (map['studentId'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      campusId: map['campusId'] as String? ?? '',
      campusName: map['campusName'] as String? ?? '',
      hostelBlock: map['hostelBlock'] as String?,
      roomNumber: map['roomNumber'] as String?,
      roommate1Phone: map['roommate1Phone'] as String?,
      roommate2Phone: map['roommate2Phone'] as String?,
      wardenPhone: map['wardenPhone'] as String?,
      parentPhone: map['parentPhone'] as String?,
      email: map['email'] as String?,
      fcmToken: map['fcmToken'] as String?,
    );
  }
}