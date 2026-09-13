import 'dart:convert';
import 'dart:io';

import '../models/triage_model.dart';

/// Service for calling Google Gemini API to assist with interpreting
/// structured student triage responses.
///
/// SAFETY CONSTRAINTS:
/// 1. The API key is NEVER hardcoded or committed (read from runtime or --dart-define).
/// 2. Gemini cannot independently diagnose or make unrestricted medical decisions.
/// 3. If Gemini is unavailable, offline, or misconfigured, it safely returns null,
///    allowing the rule-based safety engine to function seamlessly.
class GeminiTriageService {
  final String _apiKey;
  final String model;

  GeminiTriageService({
    String? apiKey,
    this.model = 'gemini-1.5-flash',
  })  : _apiKey = apiKey ??
            const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Returns true if an API key has been supplied.
  bool get isConfigured => _apiKey.trim().isNotEmpty;

  /// Requests Gemini's assistance in assessing the structured triage input.
  /// Returns null on any network failure, timeout, format error, or missing key.
  Future<TriageResult?> evaluateWithGemini(TriageAssessment assessment) async {
    if (!isConfigured) {
      return null;
    }

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);

      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
      );

      final prompt = _buildPrompt(assessment);

      final requestBody = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 500,
          'responseMimeType': 'application/json',
        }
      });

      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.add(utf8.encode(requestBody));

      final response =
          await request.close().timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final decodedJson = jsonDecode(responseBody) as Map<String, dynamic>;

      final candidates = decodedJson['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return null;
      }

      final text = candidates[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        return null;
      }

      return _parseGeminiResponse(text);
    } catch (_) {
      // Safe fallback on any error (network failure, timeout, invalid JSON, etc.)
      return null;
    } finally {
      client?.close();
    }
  }

  String _buildPrompt(TriageAssessment assessment) {
    final symptomsList = assessment.selectedSymptoms.isEmpty
        ? 'None specified'
        : assessment.selectedSymptoms.join(', ');

    return '''
You are CareLink AI, an assistant for college students.
ROLE CONSTRAINTS:
- You are providing PRELIMINARY TRIAGE GUIDANCE only, NOT a medical diagnosis or prescription.
- Evaluate the student's reported situation into EXACTLY ONE of three urgency levels:
  1. "GREEN" = Home Care (mild, self-limiting symptoms, normal mobility, mild pain)
  2. "YELLOW" = Clinic Visit (moderate symptoms, persistent fever, moderate pain, sprains, persistent illness)
  3. "RED" = Emergency (severe breathing trouble, chest pain, fainting, inability to walk/talk, severe pain 8-10, severe trauma)

Student Assessment Data:
- Primary symptom/complaint: ${assessment.mainSymptom}
- Duration: ${assessment.duration.label}
- Mobility/Speech: ${assessment.walkTalkStatus.label}
- Associated symptoms: $symptomsList
- Pain level: ${assessment.painLevel} / 10
- Additional notes: ${assessment.additionalNotes.isEmpty ? 'None' : assessment.additionalNotes}

Respond ONLY with valid JSON matching this schema:
{
  "urgency": "GREEN" | "YELLOW" | "RED",
  "headline": "Short title (5-8 words)",
  "explanation": "Student-friendly clear explanation (2-3 sentences)",
  "recommendedActions": ["Action 1", "Action 2", "Action 3", "Action 4"]
}
''';
  }

  TriageResult? _parseGeminiResponse(String rawText) {
    try {
      // Clean possible markdown code fence wrappers (```json ... ```)
      var clean = rawText.trim();
      if (clean.startsWith('```json')) {
        clean = clean.substring(7);
      } else if (clean.startsWith('```')) {
        clean = clean.substring(3);
      }
      if (clean.endsWith('```')) {
        clean = clean.substring(0, clean.length - 3);
      }
      clean = clean.trim();

      final data = jsonDecode(clean) as Map<String, dynamic>;

      final urgencyStr = (data['urgency'] as String?)?.toUpperCase() ?? '';
      final urgency = switch (urgencyStr) {
        'RED' => TriageUrgency.red,
        'YELLOW' => TriageUrgency.yellow,
        _ => TriageUrgency.green,
      };

      final headline = data['headline'] as String? ?? urgency.displayName;
      final explanation = data['explanation'] as String? ?? '';
      final rawActions = data['recommendedActions'] as List<dynamic>?;
      final actions = rawActions?.map((e) => e.toString()).toList() ??
          [
            'Follow recommended care guidelines.',
            'Monitor your condition closely.'
          ];

      return TriageResult(
        urgency: urgency,
        headline: headline,
        explanation: explanation,
        recommendedActions: actions,
        detectedRedFlags: const [],
        isAiAssisted: true,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
