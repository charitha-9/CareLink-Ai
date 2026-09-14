import 'package:flutter/material.dart';

import '../models/triage_model.dart';
import '../services/triage_service.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/triage_urgency_card.dart';

/// Screen for student AI Preliminary Triage / Health Check.
///
/// Designed to be stress-friendly, highly accessible, and clearly communicates
/// that results are preliminary guidance rather than a medical diagnosis.
class TriageScreen extends StatefulWidget {
  final void Function(BuildContext context)? onEmergencyTriggered;
  final TriageService? triageService;

  const TriageScreen({
    super.key,
    this.onEmergencyTriggered,
    this.triageService,
  });

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  late final TriageService _triageService;

  final TextEditingController _symptomController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  SymptomDuration _duration = SymptomDuration.lessThanHour;
  WalkTalkStatus _walkTalkStatus = WalkTalkStatus.normal;
  final Set<String> _selectedSymptoms = <String>{};
  int _painLevel = 0;

  bool _isLoading = false;
  TriageResult? _result;

  // Common quick chips to help students under stress quickly formulate their symptom
  static const List<String> _commonComplaints = [
    'Headache',
    'Fever',
    'Cough / Cold',
    'Chest Pain',
    'Breathing Trouble',
    'Stomach Pain',
    'Injury / Fall',
    'Dizziness',
    'Nausea / Vomiting',
    'Allergic Reaction',
  ];

  @override
  void initState() {
    super.initState();
    _triageService = widget.triageService ?? TriageService();
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectComplaintChip(String chipText) {
    setState(() {
      _symptomController.text = chipText;

      // Automatically check related symptom flags for safety
      if (chipText.contains('Breathing')) {
        _selectedSymptoms.add('breathing_difficulty');
      } else if (chipText.contains('Chest')) {
        _selectedSymptoms.add('chest_pain');
      } else if (chipText.contains('Fever')) {
        _selectedSymptoms.add('fever');
      } else if (chipText.contains('Injury')) {
        _selectedSymptoms.add('injury');
      } else if (chipText.contains('Dizziness')) {
        _selectedSymptoms.add('dizziness_fainting');
      }
    });
  }

  Future<void> _evaluate() async {
    final mainSymptom = _symptomController.text.trim();
    if (mainSymptom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your main symptom or select a quick option.'),
          backgroundColor: Colors.deepPurple,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final assessment = TriageAssessment(
      mainSymptom: mainSymptom,
      duration: _duration,
      walkTalkStatus: _walkTalkStatus,
      selectedSymptoms: Set<String>.from(_selectedSymptoms),
      painLevel: _painLevel,
      additionalNotes: _notesController.text.trim(),
    );

    final result = await _triageService.performTriage(assessment);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _result = result;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _symptomController.clear();
      _notesController.clear();
      _duration = SymptomDuration.lessThanHour;
      _walkTalkStatus = WalkTalkStatus.normal;
      _selectedSymptoms.clear();
      _painLevel = 0;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'AI Health Check',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'New Assessment',
              onPressed: _resetForm,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Prominent Medical Disclaimer Banner
                    const DisclaimerBanner(),

                    const SizedBox(height: 16),

                    if (_result != null)
                      TriageUrgencyCard(
                        result: _result!,
                        onEmergencyTriggered: widget.onEmergencyTriggered,
                        onReset: _resetForm,
                      )
                    else
                      _buildAssessmentForm(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.deepPurple,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          const Text(
            'Evaluating symptoms securely...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Applying rule-based safety checks & preliminary triage guidance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question 1: Main problem / symptom
        _buildSectionCard(
          title: '1. What is the main problem or symptom?',
          subtitle: 'Type below or tap a quick symptom chip.',
          icon: Icons.chat_bubble_outline_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonComplaints.map((complaint) {
                  final isSelected =
                      _symptomController.text.trim().toLowerCase() ==
                          complaint.toLowerCase();
                  return ChoiceChip(
                    label: Text(complaint),
                    selected: isSelected,
                    selectedColor: Colors.deepPurple.shade100,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.deepPurple.shade900
                          : Colors.black87,
                    ),
                    onSelected: (_) => _selectComplaintChip(complaint),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _symptomController,
                decoration: InputDecoration(
                  hintText: 'e.g. Sharp pain in lower right abdomen, severe headache...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Question 2: How long has it been happening?
        _buildSectionCard(
          title: '2. How long has it been happening?',
          subtitle: 'Select the approximate duration.',
          icon: Icons.access_time_rounded,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SymptomDuration.values.map((duration) {
              final isSelected = _duration == duration;
              return ChoiceChip(
                label: Text(duration.label),
                selected: isSelected,
                selectedColor: Colors.deepPurple.shade100,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.deepPurple.shade900
                      : Colors.black87,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _duration = duration;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Question 3: Can you walk and talk normally?
        _buildSectionCard(
          title: '3. Can you walk and talk normally?',
          subtitle: 'Mobility and responsiveness indicator.',
          icon: Icons.directions_walk_rounded,
          child: Column(
            children: WalkTalkStatus.values.map((status) {
              final isSelected = _walkTalkStatus == status;
              Color activeColor;
              switch (status) {
                case WalkTalkStatus.normal:
                  activeColor = Colors.green.shade700;
                case WalkTalkStatus.difficult:
                  activeColor = Colors.orange.shade800;
                case WalkTalkStatus.unable:
                  activeColor = Colors.red.shade800;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _walkTalkStatus = status;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor.withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? activeColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? activeColor : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? activeColor : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Question 4: Symptom & Context Checklist
        _buildSectionCard(
          title: '4. Check all symptoms that apply:',
          subtitle: 'Select any specific signs you are experiencing.',
          icon: Icons.checklist_rounded,
          child: Column(
            children: [
              _buildCheckboxItem(
                id: 'breathing_difficulty',
                title: 'Breathing difficulty / Shortness of breath',
                isRedFlag: true,
              ),
              _buildCheckboxItem(
                id: 'chest_pain',
                title: 'Chest pain, tightness, or pressure',
                isRedFlag: true,
              ),
              _buildCheckboxItem(
                id: 'severe_pain',
                title: 'Severe, unbearable pain',
                isRedFlag: true,
              ),
              _buildCheckboxItem(
                id: 'fainting',
                title: 'Dizziness, blackouts, or fainting episode',
                isRedFlag: true,
              ),
              _buildCheckboxItem(
                id: 'confusion_weakness',
                title: 'Sudden confusion, speech difficulty, or weakness',
                isRedFlag: true,
              ),
              _buildCheckboxItem(
                id: 'fever',
                title: 'High fever, chills, or sweats',
              ),
              _buildCheckboxItem(
                id: 'injury',
                title: 'Physical injury, sprain, or bleeding',
              ),
              _buildCheckboxItem(
                id: 'persistent_vomiting',
                title: 'Inability to keep liquids down / persistent vomiting',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Question 5: Pain Scale
        _buildSectionCard(
          title: '5. Pain Level (0 - 10): $_painLevel / 10',
          subtitle: _getPainDescription(_painLevel),
          icon: Icons.show_chart_rounded,
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getPainColor(_painLevel),
                  thumbColor: _getPainColor(_painLevel),
                  overlayColor: _getPainColor(_painLevel).withValues(alpha: 0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _painLevel.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '$_painLevel',
                  onChanged: (val) {
                    setState(() {
                      _painLevel = val.toInt();
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0 (No Pain)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '5 (Moderate)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '10 (Unbearable)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Optional additional context notes
        _buildSectionCard(
          title: '6. Other context or symptoms (optional)',
          subtitle: 'Add any medical history, allergies, or details.',
          icon: Icons.notes_rounded,
          child: TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Diagnosed with asthma, allergic to penicillin, started after sports...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _evaluate,
            icon: const Icon(Icons.health_and_safety_rounded, size: 24),
            label: const Text(
              'CHECK SYMPTOMS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Footer disclaimer reminder
        Text(
          'CareLink AI preliminary triage provides guidance based on reported symptoms and does not substitute for clinical diagnosis.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxItem({
    required String id,
    required String title,
    bool isRedFlag = false,
  }) {
    final isChecked = _selectedSymptoms.contains(id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isChecked) {
              _selectedSymptoms.remove(id);
            } else {
              _selectedSymptoms.add(id);
            }
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isChecked
                ? (isRedFlag ? Colors.red.shade50 : Colors.deepPurple.shade50)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isChecked
                  ? (isRedFlag ? Colors.red.shade300 : Colors.deepPurple.shade300)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isChecked
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: isChecked
                    ? (isRedFlag ? Colors.red.shade700 : Colors.deepPurple)
                    : Colors.grey.shade500,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                    color: isChecked
                        ? (isRedFlag ? Colors.red.shade900 : Colors.deepPurple.shade900)
                        : Colors.black87,
                  ),
                ),
              ),
              if (isRedFlag)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Alert',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPainDescription(int level) {
    if (level == 0) return 'No pain';
    if (level <= 3) return 'Mild pain - noticeable but easily tolerated';
    if (level <= 6) return 'Moderate pain - interferes with normal activities';
    if (level <= 8) return 'Severe pain - demanding immediate attention';
    return 'Extreme / Unbearable pain';
  }

  Color _getPainColor(int level) {
    if (level <= 3) return Colors.green.shade600;
    if (level <= 6) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}
