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
    );
  }
}