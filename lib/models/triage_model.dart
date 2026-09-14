import 'package:flutter/material.dart';

/// Exactly three urgency levels required for CareLink AI Triage:
/// - GREEN: Home Care
/// - YELLOW: Clinic Visit
/// - RED: Emergency
enum TriageUrgency {
  green,
  yellow,
  red;

  String get displayName {
    switch (this) {
      case TriageUrgency.green:
        return 'Home Care';
      case TriageUrgency.yellow:
        return 'Clinic Visit';
      case TriageUrgency.red:
        return 'Emergency';
    }
  }

  String get code {
    switch (this) {
      case TriageUrgency.green:
        return 'GREEN';
      case TriageUrgency.yellow:
        return 'YELLOW';
      case TriageUrgency.red:
        return 'RED';
    }
  }

  Color get primaryColor {
    switch (this) {
      case TriageUrgency.green:
        return const Color(0xFF1B5E20); // Dark Green
      case TriageUrgency.yellow:
        return const Color(0xFFE65100); // Amber/Orange
      case TriageUrgency.red:
        return const Color(0xFFB71C1C); // Deep Red
    }
  }

  Color get cardBackgroundColor {
    switch (this) {
      case TriageUrgency.green:
        return const Color(0xFFE8F5E9); // Light Green
      case TriageUrgency.yellow:
        return const Color(0xFFFFF3E0); // Light Amber
      case TriageUrgency.red:
        return const Color(0xFFFFEBEE); // Light Red
    }
  }

  IconData get icon {
    switch (this) {
      case TriageUrgency.green:
        return Icons.check_circle_outline_rounded;
      case TriageUrgency.yellow:
        return Icons.local_hospital_outlined;
      case TriageUrgency.red:
        return Icons.warning_rounded;
    }
  }

  bool get isEmergency => this == TriageUrgency.red;
}

/// Ability to walk and talk normally
enum WalkTalkStatus {
  normal,
  difficult,
  unable;

  String get label {
    switch (this) {
      case WalkTalkStatus.normal:
        return 'Yes, both normally';
      case WalkTalkStatus.difficult:
        return 'With difficulty';
      case WalkTalkStatus.unable:
        return 'No, unable to walk or talk';
    }
  }
}

/// How long the symptom has been happening
enum SymptomDuration {
  lessThanHour,
  fewHours,
  oneToTwoDays,
  moreThanThreeDays;

  String get label {
    switch (this) {
      case SymptomDuration.lessThanHour:
        return '< 1 hour';
      case SymptomDuration.fewHours:
        return 'A few hours';
      case SymptomDuration.oneToTwoDays:
        return '1 - 2 days';
      case SymptomDuration.moreThanThreeDays:
        return '3+ days';
    }
  }
}

/// Input data captured during student preliminary triage
class TriageAssessment {
  final String mainSymptom;
  final SymptomDuration duration;
  final WalkTalkStatus walkTalkStatus;
  final Set<String> selectedSymptoms;
  final int painLevel; // 0 to 10
  final String additionalNotes;

  const TriageAssessment({
    required this.mainSymptom,
    required this.duration,
    required this.walkTalkStatus,
    this.selectedSymptoms = const {},
    this.painLevel = 0,
    this.additionalNotes = '',
  });

  TriageAssessment copyWith({
    String? mainSymptom,
    SymptomDuration? duration,
    WalkTalkStatus? walkTalkStatus,
    Set<String>? selectedSymptoms,
    int? painLevel,
    String? additionalNotes,
  }) {
    return TriageAssessment(
      mainSymptom: mainSymptom ?? this.mainSymptom,
      duration: duration ?? this.duration,
      walkTalkStatus: walkTalkStatus ?? this.walkTalkStatus,
      selectedSymptoms: selectedSymptoms ?? this.selectedSymptoms,
      painLevel: painLevel ?? this.painLevel,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }
}

/// Structured outcome produced by the triage engine (Rule-based or AI-assisted)
class TriageResult {
  final TriageUrgency urgency;
  final String headline;
  final String explanation;
  final List<String> recommendedActions;
  final List<String> detectedRedFlags;
  final bool isAiAssisted;
  final DateTime timestamp;
  final String disclaimer;

  const TriageResult({
    required this.urgency,
    required this.headline,
    required this.explanation,
    required this.recommendedActions,
    this.detectedRedFlags = const [],
    this.isAiAssisted = false,
    required this.timestamp,
    this.disclaimer = 'AI-assisted preliminary triage, not a medical diagnosis.',
  });
}
