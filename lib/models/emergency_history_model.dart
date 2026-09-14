/// Data model for past emergency incidents, designed to seamlessly
/// merge with the Firebase backend models.
class EmergencyHistoryModel {
  final String historyId;
  final String emergencyId;
  final String studentId;
  final DateTime startedAt;
  final DateTime resolvedAt;
  final String resolutionStatus;
  final String? incidentType;
  final String? summary;
  final double? latitude;
  final double? longitude;
  final List<String> notifiedParties;

  const EmergencyHistoryModel({
    required this.historyId,
    required this.emergencyId,
    required this.studentId,
    required this.startedAt,
    required this.resolvedAt,
    required this.resolutionStatus,
    this.incidentType,
    this.summary,
    this.latitude,
    this.longitude,
    this.notifiedParties = const [],
  });

  EmergencyHistoryModel copyWith({
    String? historyId,
    String? emergencyId,
    String? studentId,
    DateTime? startedAt,
    DateTime? resolvedAt,
    String? resolutionStatus,
    String? incidentType,
    String? summary,
    double? latitude,
    double? longitude,
    List<String>? notifiedParties,
  }) {
    return EmergencyHistoryModel(
      historyId: historyId ?? this.historyId,
      emergencyId: emergencyId ?? this.emergencyId,
      studentId: studentId ?? this.studentId,
      startedAt: startedAt ?? this.startedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionStatus: resolutionStatus ?? this.resolutionStatus,
      incidentType: incidentType ?? this.incidentType,
      summary: summary ?? this.summary,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notifiedParties: notifiedParties ?? this.notifiedParties,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'historyId': historyId,
      'emergencyId': emergencyId,
      'studentId': studentId,
      'startedAt': startedAt.toIso8601String(),
      'resolvedAt': resolvedAt.toIso8601String(),
      'resolutionStatus': resolutionStatus,
      'incidentType': incidentType,
      'summary': summary,
      'latitude': latitude,
      'longitude': longitude,
      'notifiedParties': notifiedParties,
    };
  }

  factory EmergencyHistoryModel.fromMap(
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

    final rawParties = map['notifiedParties'];
    final List<String> parsedParties = [];
    if (rawParties is List) {
      for (final item in rawParties) {
        if (item != null) parsedParties.add(item.toString());
      }
    }

    return EmergencyHistoryModel(
      historyId: docId ?? (map['historyId'] as String? ?? ''),
      emergencyId: map['emergencyId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      startedAt: parseDate(map['startedAt']),
      resolvedAt: parseDate(map['resolvedAt']),
      resolutionStatus: map['resolutionStatus'] as String? ?? 'resolved',
      incidentType: map['incidentType'] as String?,
      summary: map['summary'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      notifiedParties: parsedParties,
    );
  }
}
