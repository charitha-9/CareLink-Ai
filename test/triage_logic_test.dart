import 'package:carelink_mobile/logic/triage_logic.dart';
import 'package:carelink_mobile/models/triage_model.dart';
import 'package:carelink_mobile/services/triage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TriageRuleEngine - Red Flag Safety Layer', () {
    test('Inability to walk or talk produces RED Emergency', () {
      const assessment = TriageAssessment(
        mainSymptom: 'Stomach pain',
        duration: SymptomDuration.fewHours,
        walkTalkStatus: WalkTalkStatus.unable,
        painLevel: 4,
      );

      final result = TriageRuleEngine.evaluate(assessment);

      expect(result.urgency, equals(TriageUrgency.red));
      expect(result.detectedRedFlags, isNotEmpty);
      expect(
        result.detectedRedFlags.first,
        contains('Inability to walk or talk'),
      );
    });

    test('Breathing difficulty produces RED Emergency', () {
      const assessment = TriageAssessment(
        mainSymptom: 'Short of breath',
        duration: SymptomDuration.lessThanHour,
        walkTalkStatus: WalkTalkStatus.normal,
        selectedSymptoms: {'breathing_difficulty'},
        painLevel: 3,
      );

      final result = TriageRuleEngine.evaluate(assessment);

      expect(result.urgency, equals(TriageUrgency.red));
      expect(result.detectedRedFlags, contains(contains('Breathing difficulty')));
    });

    test('Severe acute pain (level 8+) produces RED Emergency', () {
      const assessment = TriageAssessment(
        mainSymptom: 'Lower right abdominal pain',
        duration: SymptomDuration.fewHours,
        walkTalkStatus: WalkTalkStatus.difficult,
        painLevel: 9,
      );

      final result = TriageRuleEngine.evaluate(assessment);

      expect(result.urgency, equals(TriageUrgency.red));
      expect(result.detectedRedFlags, contains(contains('Severe acute pain')));
    });

    test('Chest pain produces RED Emergency', () {
      const assessment = TriageAssessment(
        mainSymptom: 'Pressure in chest',
        duration: SymptomDuration.lessThanHour,
        walkTalkStatus: WalkTalkStatus.normal,
        selectedSymptoms: {'chest_pain'},
        painLevel: 5,
      );

      final result = TriageRuleEngine.evaluate(assessment);

      expect(result.urgency, equals(TriageUrgency.red));
      expect(result.detectedRedFlags, contains(contains('Chest pain')));
    });

    test('Fainting / blackout produces RED Emergency', () {
      const assessment = TriageAssessment(
        mainSymptom: 'Fainted in class',
        duration: SymptomDuration.lessThanHour,
        walkTalkStatus: WalkTalkStatus.normal,
        selectedSymptoms: {'fainting'},
        painLevel: 0,
      );

      final result = TriageRuleEngine.evaluate(assessment);

      expect(result.urgency, equals(TriageUrgency.red));
      expect(
        result.detectedRedFlags,
        contains(contains('Loss of consciousness')),
      );
    });

    test('Emergency keyword in description triggers RED Emergency', () {
      const assessment = TriageAssessment(
        mainSymptom: 'My friend passed out on the stairs',
        duration: SymptomDuration.lessThanHour,
        walkTalkStatus: WalkTalkStatus.normal,
      );

      final result = TriageRuleEngine.evaluate(assessment);

      expect(result.urgency, equals(TriageUrgency.red));
      expect(
        result.detectedRedFlags.any((f) => f.contains('passed out')),
        isTrue,
      );
    });
  });

  group('TriageRuleEngine - Yellow Flag (Clinic Visit)', () {
    test('Fever without red flags produces YELLOW Clinic Visit', () {
      const assessment = TriageAssessment(
        mainSymptom: 'Fever and chills',
        duration: SymptomDuration.oneToTwoDays,
        walkTalkStatus: WalkTalkStatus.normal,
        selectedSymptoms: {'fever'},
        painLevel: 3,
      );

      final result = TriageRuleEngine.evaluate(assessment);

      expect(result.urgency, equals(TriageUrgency.yellow));
      expect(result.detectedRedFlags, isEmpty);
      expect(result.headline, contains('Campus Health Clinic'));
    });

    test('Difficulty walking produces YELLOW Clinic Visit', () {
      const assessment = TriageAssessment(
        mainSymptom: 'Twisted ankle while playing basketball',
        duration: SymptomDuration.fewHours,
        walkTalkStatus: WalkTalkStatus.difficult,
        selectedSymptoms: {'injury'},
        painLevel: 5,
      );

      final result = TriageRuleEngine.evaluate(assessment);

      expect(result.urgency, equals(TriageUrgency.yellow));
    });

    test('Symptoms lasting more than 3 days produce YELLOW Clinic Visit', () {
      const assessment = TriageAssessment(
        mainSymptom: 'Persistent sore throat and cough',
        duration: SymptomDuration.moreThanThreeDays,
        walkTalkStatus: WalkTalkStatus.normal,
        painLevel: 3,
      );

      final result = TriageRuleEngine.evaluate(assessment);

      expect(result.urgency, equals(TriageUrgency.yellow));
    });
  });

  group('TriageRuleEngine - Green (Home Care)', () {
    test('Mild headache with normal mobility produces GREEN Home Care', () {
      const assessment = TriageAssessment(
        mainSymptom: 'Mild headache from studying late',
        duration: SymptomDuration.fewHours,
        walkTalkStatus: WalkTalkStatus.normal,
        painLevel: 2,
      );

      final result = TriageRuleEngine.evaluate(assessment);

      expect(result.urgency, equals(TriageUrgency.green));
      expect(result.detectedRedFlags, isEmpty);
      expect(result.headline, contains('Home Care'));
      expect(result.recommendedActions, isNotEmpty);
    });
  });

  group('Safety Boundary Enforcement', () {
    test('AI cannot downgrade RED to GREEN or YELLOW', () {
      expect(
        TriageRuleEngine.enforceSafetyBound(
          ruleUrgency: TriageUrgency.red,
          candidateUrgency: TriageUrgency.green,
        ),
        equals(TriageUrgency.red),
      );

      expect(
        TriageRuleEngine.enforceSafetyBound(
          ruleUrgency: TriageUrgency.red,
          candidateUrgency: TriageUrgency.yellow,
        ),
        equals(TriageUrgency.red),
      );
    });

    test('AI cannot downgrade YELLOW to GREEN', () {
      expect(
        TriageRuleEngine.enforceSafetyBound(
          ruleUrgency: TriageUrgency.yellow,
          candidateUrgency: TriageUrgency.green,
        ),
        equals(TriageUrgency.yellow),
      );
    });

    test('AI is allowed to escalate GREEN to YELLOW or RED', () {
      expect(
        TriageRuleEngine.enforceSafetyBound(
          ruleUrgency: TriageUrgency.green,
          candidateUrgency: TriageUrgency.yellow,
        ),
        equals(TriageUrgency.yellow),
      );

      expect(
        TriageRuleEngine.enforceSafetyBound(
          ruleUrgency: TriageUrgency.green,
          candidateUrgency: TriageUrgency.red,
        ),
        equals(TriageUrgency.red),
      );
    });
  });

  group('TriageService - Offline & Fallback Resilience', () {
    test('Operates without Gemini API key and produces valid triage result', () async {
      final service = TriageService();

      const assessment = TriageAssessment(
        mainSymptom: 'Mild tiredness',
        duration: SymptomDuration.oneToTwoDays,
        walkTalkStatus: WalkTalkStatus.normal,
        painLevel: 1,
      );

      final result = await service.performTriage(assessment);

      expect(result.urgency, equals(TriageUrgency.green));
      expect(result.isAiAssisted, isFalse);
      expect(
        result.disclaimer,
        equals('AI-assisted preliminary triage, not a medical diagnosis.'),
      );
    });

    test('Emergency red flags immediately bypass AI call', () async {
      final service = TriageService();

      const assessment = TriageAssessment(
        mainSymptom: 'Severe chest tightness',
        duration: SymptomDuration.lessThanHour,
        walkTalkStatus: WalkTalkStatus.unable,
        selectedSymptoms: {'chest_pain', 'breathing_difficulty'},
        painLevel: 10,
      );

      final result = await service.performTriage(assessment);

      expect(result.urgency, equals(TriageUrgency.red));
      expect(result.detectedRedFlags, isNotEmpty);
    });
  });
}
