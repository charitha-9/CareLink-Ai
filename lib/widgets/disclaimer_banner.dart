import 'package:flutter/material.dart';

/// Reusable banner that clearly and prominently communicates the medical disclaimer:
/// "AI-assisted preliminary triage, not a medical diagnosis."
class DisclaimerBanner extends StatelessWidget {
  final bool compact;

  const DisclaimerBanner({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6), // Light purple tint
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD1C4E9),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.deepPurple.shade700,
            size: compact ? 18 : 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI-assisted preliminary triage, not a medical diagnosis.',
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
