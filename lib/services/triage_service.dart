import '../logic/triage_logic.dart';
import '../models/triage_model.dart';
import 'gemini_triage_service.dart';

/// Primary triage orchestration service.
///
/// Ensures strict adherence to the safety layer:
/// 1. Rule-based evaluation runs first.
/// 2. If red flags are present, RED Emergency is returned immediately.
/// 3. Gemini is only invoked for non-red evaluations when configured.
/// 4. Gemini cannot downgrade any safety classification.
/// 5. Gracefully falls back to rule-based engine if Gemini is unavailable.
class TriageService {
  final GeminiTriageService _geminiService;

  TriageService({GeminiTriageService? geminiService})
      : _geminiService = geminiService ?? GeminiTriageService();

  /// Performs full triage evaluation adhering to safety constraints.
  Future<TriageResult> performTriage(TriageAssessment assessment) async {
    // 1. Primary Rule-Based Safety Layer
    final ruleResult = TriageRuleEngine.evaluate(assessment);

    // Rule-based RED flag is non-negotiable and returned immediately.
    if (ruleResult.urgency == TriageUrgency.red) {
      return ruleResult;
    }

    // 2. If Gemini is not configured or unavailable, return rule result directly.
    if (!_geminiService.isConfigured) {
      return ruleResult;
    }

    // 3. Request Gemini AI interpretation
    final aiResult = await _geminiService.evaluateWithGemini(assessment);
    if (aiResult == null) {
      // Fallback seamlessly to rule-based result if network/API fails
      return ruleResult;
    }

    // 4. Enforce strict safety boundary on AI output
    final safeUrgency = TriageRuleEngine.enforceSafetyBound(
      ruleUrgency: ruleResult.urgency,
      candidateUrgency: aiResult.urgency,
    );

    // If Gemini suggested an escalation or kept safe urgency, accept recommendations
    return TriageResult(
      urgency: safeUrgency,
      headline: aiResult.headline.isNotEmpty
          ? aiResult.headline
          : safeUrgency.displayName,
      explanation: aiResult.explanation.isNotEmpty
          ? aiResult.explanation
          : ruleResult.explanation,
      recommendedActions: aiResult.recommendedActions.isNotEmpty
          ? aiResult.recommendedActions
          : ruleResult.recommendedActions,
      detectedRedFlags: ruleResult.detectedRedFlags,
      isAiAssisted: true,
      timestamp: DateTime.now(),
    );
  }
}
