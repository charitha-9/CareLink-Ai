class StudentModel {
  final String studentId;
  final String name;
  final String phone;
  final String email;

  // Campus residence information (From student profile, not GPS)
  final String hostel;
  final String block;
  final String room;
  final String? _hostelBlock;
  final String? _roomNumber;

  // Campus info (optional defaults for campus compatibility)
  final String campusId;
  final String campusName;

  // Emergency & Trusted contacts
  final String parentName;
  final String parentPhone;
  final String? roommate1Name;
  final String? roommate1Phone;
  final String? roommate2Name;
  final String? roommate2Phone;
  final String? wardenPhone;

  // Account and notification fields
  final String? fcmToken;

  const StudentModel({
    required this.studentId,
    this.name = '',
    String? phone,
    String? phoneNumber,
    this.email = '',
    this.hostel = '',
    this.block = '',
    this.room = '',
    String? hostelBlock,
    String? roomNumber,
    this.campusId = 'CAMPUS-MAIN',
    this.campusName = 'Main Campus',
    this.parentName = '',
    this.parentPhone = '',
    this.roommate1Name,
    this.roommate1Phone,
    this.roommate2Name,
    this.roommate2Phone,
    this.wardenPhone,
    this.fcmToken,
  })  : phone = phone ?? phoneNumber ?? '',
        // ignore: prefer_initializing_formals
        _hostelBlock = hostelBlock,
        // ignore: prefer_initializing_formals
        _roomNumber = roomNumber;

  // ------------------------------------------------------------
  // BACKWARD COMPATIBILITY GETTERS (for teammate modules like EmergencyService)
  // ------------------------------------------------------------

  /// Compatibility getter for teammate modules expecting `phoneNumber`
  String get phoneNumber => phone;

  /// Compatibility getter for teammate modules expecting `roomNumber`
  String get roomNumber => _roomNumber ?? room;

  /// Compatibility getter for teammate modules expecting `hostelBlock`
  String get hostelBlock {
    final explicit = _hostelBlock;
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    if (block.isNotEmpty) {
      return hostel.isNotEmpty ? '$hostel - Block $block' : 'Block $block';
    }
    return hostel;
  }

  // ------------------------------------------------------------
  // COPY WITH
  // ------------------------------------------------------------

  StudentModel copyWith({
    String? studentId,
    String? name,
    String? phone,
    String? phoneNumber,
    String? email,
    String? hostel,
    String? block,
    String? room,
    String? hostelBlock,
    String? roomNumber,
    String? campusId,
    String? campusName,
    String? parentName,
    String? parentPhone,
    String? roommate1Name,
    String? roommate1Phone,
    String? roommate2Name,
    String? roommate2Phone,
    String? wardenPhone,
    String? fcmToken,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      phone: phone ?? phoneNumber ?? this.phone,
      email: email ?? this.email,
      hostel: hostel ?? this.hostel,
      block: block ?? this.block,
      room: room ?? this.room,
      hostelBlock: hostelBlock ?? _hostelBlock,
      roomNumber: roomNumber ?? _roomNumber,
      campusId: campusId ?? this.campusId,
      campusName: campusName ?? this.campusName,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      roommate1Name: roommate1Name ?? this.roommate1Name,
      roommate1Phone: roommate1Phone ?? this.roommate1Phone,
      roommate2Name: roommate2Name ?? this.roommate2Name,
      roommate2Phone: roommate2Phone ?? this.roommate2Phone,
      wardenPhone: wardenPhone ?? this.wardenPhone,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  // ------------------------------------------------------------
  // SERIALIZATION (Ready for Firebase Cloud Firestore)
  // ------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'name': name,
      'phone': phone,
      'phoneNumber': phoneNumber,
      'email': email,
      'hostel': hostel,
      'block': block,
      'room': room,
      'hostelBlock': hostelBlock,
      'roomNumber': roomNumber,
      'campusId': campusId,
      'campusName': campusName,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'roommate1Name': roommate1Name,
      'roommate1Phone': roommate1Phone,
      'roommate2Name': roommate2Name,
      'roommate2Phone': roommate2Phone,
      'wardenPhone': wardenPhone,
      'fcmToken': fcmToken,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawHostel = map['hostel'] as String? ?? '';
    final rawBlock = map['block'] as String? ?? '';
    final rawRoom = (map['room'] ?? map['roomNumber']) as String? ?? '';
    final rawHostelBlock = map['hostelBlock'] as String?;
    final rawRoomNumber = map['roomNumber'] as String?;

    return StudentModel(
      studentId: docId ?? (map['studentId'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      phone: (map['phone'] ?? map['phoneNumber']) as String? ?? '',
      email: map['email'] as String? ?? '',
      hostel: rawHostel,
      block: rawBlock,
      room: rawRoom,
      hostelBlock: rawHostelBlock,
      roomNumber: rawRoomNumber,
      campusId: map['campusId'] as String? ?? 'CAMPUS-MAIN',
      campusName: map['campusName'] as String? ?? 'Main Campus',
      parentName: map['parentName'] as String? ?? '',
      parentPhone: map['parentPhone'] as String? ?? '',
      roommate1Name: map['roommate1Name'] as String?,
      roommate1Phone: map['roommate1Phone'] as String?,
      roommate2Name: map['roommate2Name'] as String?,
      roommate2Phone: map['roommate2Phone'] as String?,
      wardenPhone: map['wardenPhone'] as String?,
      fcmToken: map['fcmToken'] as String?,
    );
  }

  @override
  String toString() {
    return 'StudentModel(studentId: $studentId, name: $name, phone: $phone, email: $email, hostel: $hostel, block: $block, room: $room, campusId: $campusId, fcmToken: $fcmToken)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StudentModel &&
        other.studentId == studentId &&
        other.name == name &&
        other.phone == phone &&
        other.email == email &&
        other.hostel == hostel &&
        other.block == block &&
        other.room == room &&
        other.campusId == campusId &&
        other.campusName == campusName &&
        other.parentName == parentName &&
        other.parentPhone == parentPhone &&
        other.roommate1Name == roommate1Name &&
        other.roommate1Phone == roommate1Phone &&
        other.roommate2Name == roommate2Name &&
        other.roommate2Phone == roommate2Phone &&
        other.wardenPhone == wardenPhone &&
        other.fcmToken == fcmToken;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      studentId,
      name,
      phone,
      email,
      hostel,
      block,
      room,
      campusId,
      campusName,
      parentName,
      parentPhone,
      roommate1Name,
      roommate1Phone,
      roommate2Name,
      roommate2Phone,
      wardenPhone,
      fcmToken,
    ]);
  }
}