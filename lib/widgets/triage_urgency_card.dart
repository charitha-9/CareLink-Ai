import 'package:flutter/material.dart';

import '../models/triage_model.dart';
import 'disclaimer_banner.dart';

/// Card widget displaying the triage outcome for GREEN, YELLOW, or RED urgency.
///
/// If urgency is RED, it prominently renders the Emergency Autopilot callback
/// trigger button so students under acute distress can immediately alert help.
class TriageUrgencyCard extends StatelessWidget {
  final TriageResult result;
  final void Function(BuildContext context)? onEmergencyTriggered;
  final VoidCallback? onReset;

  const TriageUrgencyCard({
    super.key,
    required this.result,
    this.onEmergencyTriggered,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final urgency = result.urgency;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: urgency.primaryColor,
          width: 2.5,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Urgency Header Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: urgency.cardBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: urgency.primaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: urgency.primaryColor,
                    radius: 20,
                    child: Icon(
                      urgency.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'URGENCY LEVEL: ${urgency.code}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: urgency.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          urgency.displayName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: urgency.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (result.isAiAssisted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.deepPurple.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: Colors.deepPurple.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI-Assisted',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Mandatory Disclaimer
            const DisclaimerBanner(compact: true),

            const SizedBox(height: 16),

            // Headline
            Text(
              result.headline,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // Explanation
            Text(
              result.explanation,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),

            // Detected Red Flags Section
            if (result.detectedRedFlags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Colors.red.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Critical Red Flags Identified:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...result.detectedRedFlags.map(
                      (flag) => Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                flag,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Recommended Actions
            const Text(
              'Recommended Next Steps:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            ...result.recommendedActions.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final action = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: urgency.primaryColor.withValues(alpha: 0.15),
                      child: Text(
                        '$idx',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: urgency.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        action,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // RED Emergency Trigger Action
            if (urgency == TriageUrgency.red) ...[
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade300.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (onEmergencyTriggered != null) {
                        onEmergencyTriggered!(context);
                      } else {
                        _showEmergencyDialog(context);
                      }
                    },
                    icon: const Icon(
                      Icons.emergency_share,
                      size: 28,
                    ),
                    label: const Text(
                      'TRIGGER EMERGENCY AUTOPILOT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Re-assess Button
            if (onReset != null)
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Start New Assessment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Mode'),
          ],
        ),
        content: const Text(
          'Immediate emergency response is advised.\n\n'
          '• Dial 112 or local campus security.\n'
          '• Alert roommates or campus staff immediately.\n'
          '• Emergency Autopilot module callback triggered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
