import '../models/triage_model.dart';

/// Rule-based safety engine for CareLink AI preliminary triage.
///
/// This engine is fully deterministic and independent of external AI services.
/// It acts as the primary safety barrier: red-flag indicators always produce
/// a RED Emergency classification, ensuring patient safety regardless of AI
/// availability or interpretation.
class TriageRuleEngine {
  /// Evaluates an assessment strictly via medical safety heuristics.
  static TriageResult evaluate(TriageAssessment assessment) {
    final redFlags = detectRedFlags(assessment);

    if (redFlags.isNotEmpty) {
      return TriageResult(
        urgency: TriageUrgency.red,
        headline: 'Immediate Emergency Attention Required',
        explanation:
            'Critical red-flag symptoms detected. For safety, this requires urgent medical attention.',
        recommendedActions: [
          'Trigger Emergency Autopilot or call 112 / Campus Security immediately.',
          'Do not attempt to walk alone or drive.',
          'Alert a roommate, resident advisor, or nearby person right now.',
          'Stay calm, sit in a safe resting position, and wait for emergency responders.',
        ],
        detectedRedFlags: redFlags,
        isAiAssisted: false,
        timestamp: DateTime.now(),
      );
    }

    final yellowFlags = detectYellowFlags(assessment);

    if (yellowFlags.isNotEmpty) {
      return TriageResult(
        urgency: TriageUrgency.yellow,
        headline: 'Campus Health Clinic Visit Recommended',
        explanation:
            'Symptoms suggest moderate health concern that should be evaluated by a healthcare professional at the campus clinic or health center.',
        recommendedActions: [
          'Visit the Campus Health Center or local urgent care clinic today.',
          'Bring your student ID and list of any medications you take.',
          'If symptoms rapidly worsen, difficulties breathing begin, or pain increases sharply, re-evaluate or seek emergency care.',
          'Rest, stay hydrated, and have a friend or roommate check on you.',
        ],
        detectedRedFlags: const [],
        isAiAssisted: false,
        timestamp: DateTime.now(),
      );
    }

    // Green - Home Care
    return TriageResult(
      urgency: TriageUrgency.green,
      headline: 'Home Care & Symptom Monitoring',
      explanation:
          'No high-risk or acute red-flag symptoms reported. Mild symptoms are typically manageable with self-care and rest.',
      recommendedActions: [
        'Rest adequately and maintain good hydration (water, electrolyte fluids).',
        'Monitor your temperature and symptoms over the next 24-48 hours.',
        'Consider over-the-counter pain relief or comfort measures if appropriate for you.',
        'If symptoms persist beyond 3 days or get worse, schedule a visit at the Campus Health Center.',
      ],
      detectedRedFlags: const [],
      isAiAssisted: false,
      timestamp: DateTime.now(),
    );
  }

  /// Detects critical red-flag conditions that mandate immediate RED Emergency.
  static List<String> detectRedFlags(TriageAssessment assessment) {
    final flags = <String>[];

    // 1. Mobility & speech failure
    if (assessment.walkTalkStatus == WalkTalkStatus.unable) {
      flags.add('Inability to walk or talk normally');
    }

    // 2. Severe pain (pain scale 8-10 or explicit severe pain)
    if (assessment.painLevel >= 8) {
      flags.add('Severe acute pain level (${assessment.painLevel}/10)');
    }
    if (assessment.selectedSymptoms.contains('severe_pain') &&
        !flags.any((f) => f.contains('Severe acute pain'))) {
      flags.add('Severe or excruciating pain reported');
    }

    // 3. Respiratory distress
    if (assessment.selectedSymptoms.contains('breathing_difficulty')) {
      flags.add('Breathing difficulty / shortness of breath');
    }

    // 4. Chest pain / cardiac symptoms
    if (assessment.selectedSymptoms.contains('chest_pain')) {
      flags.add('Chest pain or tightness');
    }

    // 5. Fainting / loss of consciousness / syncope
    if (assessment.selectedSymptoms.contains('fainting') ||
        assessment.selectedSymptoms.contains('loss_of_consciousness')) {
      flags.add('Loss of consciousness or fainting episode');
    }

    // 6. Neurological / stroke signs
    if (assessment.selectedSymptoms.contains('confusion_weakness')) {
      flags.add('Sudden confusion, numbness, or facial/body weakness');
    }

    // 7. Severe head trauma or major injury
    if (assessment.selectedSymptoms.contains('severe_head_injury') ||
        assessment.selectedSymptoms.contains('heavy_bleeding')) {
      flags.add('Severe head injury or uncontrolled bleeding');
    }

    // 8. Keyword safety scan in free text
    final textToScan =
        '${assessment.mainSymptom} ${assessment.additionalNotes}'.toLowerCase();

    const emergencyKeywords = [
      'cannot breathe',
      'cant breathe',
      'can\'t breathe',
      'shortness of breath',
      'suffocating',
      'choking',
      'chest pain',
      'heart attack',
      'unconscious',
      'passed out',
      'blacked out',
      'seizure',
      'bleeding heavily',
      'uncontrolled bleeding',
      'overdose',
      'suicid',
      'anaphylax',
      'stroke',
      'paralyzed',
      'collapsed',
    ];

    for (final kw in emergencyKeywords) {
      if (textToScan.contains(kw)) {
        final flagText = 'Emergency keyword detected: "$kw"';
        if (!flags.contains(flagText)) {
          flags.add(flagText);
        }
        break;
      }
    }

    return flags;
  }

  /// Detects yellow-flag indicators recommending a Campus Clinic Visit.
  static List<String> detectYellowFlags(TriageAssessment assessment) {
    final flags = <String>[];

    // 1. Walking/talking with difficulty
    if (assessment.walkTalkStatus == WalkTalkStatus.difficult) {
      flags.add('Difficulty walking or speaking clearly');
    }

    // 2. Moderate pain (5-7)
    if (assessment.painLevel >= 5 && assessment.painLevel < 8) {
      flags.add('Moderate pain level (${assessment.painLevel}/10)');
    }

    // 3. High or persistent fever
    if (assessment.selectedSymptoms.contains('fever')) {
      flags.add('Fever requiring professional medical review');
    }

    // 4. Physical injury / sprain / cuts
    if (assessment.selectedSymptoms.contains('injury')) {
      flags.add('Physical injury needing examination or dressing');
    }

    // 5. Dizziness / lightheadedness
    if (assessment.selectedSymptoms.contains('dizziness_fainting')) {
      flags.add('Dizziness or persistent lightheadedness');
    }

    // 6. Persistent vomiting / unable to hold food
    if (assessment.selectedSymptoms.contains('persistent_vomiting')) {
      flags.add('Persistent vomiting or inability to keep fluids down');
    }

    // 7. Prolonged symptom duration (> 3 days)
    if (assessment.duration == SymptomDuration.moreThanThreeDays) {
      flags.add('Symptoms persisting for more than 3 days');
    }

    return flags;
  }

  /// Safety boundary enforcement:
  ///
  /// AI output is NEVER allowed to downgrade a rule-based safety classification.
  /// AI can elevate GREEN -> YELLOW or RED, or YELLOW -> RED, but can never reduce
  /// a rule-identified RED or YELLOW.
  static TriageUrgency enforceSafetyBound({
    required TriageUrgency ruleUrgency,
    required TriageUrgency candidateUrgency,
  }) {
    if (ruleUrgency == TriageUrgency.red) {
      // Safety layer unconditionally enforces RED
      return TriageUrgency.red;
    }

    if (ruleUrgency == TriageUrgency.yellow) {
      // Candidate may escalate to RED, but cannot downgrade to GREEN
      if (candidateUrgency == TriageUrgency.red) {
        return TriageUrgency.red;
      }
      return TriageUrgency.yellow;
    }

    // When rule is GREEN, candidate may remain GREEN or escalate to YELLOW/RED
    return candidateUrgency;
  }
}
