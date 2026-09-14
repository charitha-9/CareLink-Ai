import 'package:flutter/material.dart';
import '../models/care_facility_model.dart';
import '../theme/app_theme.dart';

/// Renders a compact badge for facility status (Open/Closed).
class OpenStatusBadge extends StatelessWidget {
  final bool? isOpen;

  const OpenStatusBadge({super.key, this.isOpen});

  @override
  Widget build(BuildContext context) {
    if (isOpen == null) return const SizedBox.shrink();

    final isFacilityOpen = isOpen!;
    final bgColor = isFacilityOpen ? AppTheme.safeLightGreen : Colors.red.shade50;
    final textColor = isFacilityOpen ? AppTheme.safeGreen : AppTheme.emergencyDarkRed;
    final text = isFacilityOpen ? 'Open Now' : 'Closed';
    final dotColor = isFacilityOpen ? AppTheme.safeGreen : AppTheme.emergencyRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a badge distinguishing facility types (Hospital, Clinic, Campus Health Center).
class FacilityTypeBadge extends StatelessWidget {
  final CareFacilityType type;

  const FacilityTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case CareFacilityType.campusHealthCenter:
        bgColor = AppTheme.primaryLight;
        textColor = AppTheme.primaryDark;
        icon = Icons.verified_user_outlined;
        break;
      case CareFacilityType.hospital:
        bgColor = AppTheme.emergencyLightRed;
        textColor = AppTheme.emergencyDarkRed;
        icon = Icons.local_hospital_outlined;
        break;
      case CareFacilityType.clinic:
      case CareFacilityType.urgentCare:
        bgColor = AppTheme.clinicLightAmber;
        textColor = AppTheme.clinicAmber;
        icon = Icons.medical_services_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            type.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge highlighting 24/7 ER availability when verified.
class EmergencyServicesBadge extends StatelessWidget {
  const EmergencyServicesBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.emergency, size: 13, color: AppTheme.emergencyDarkRed),
          SizedBox(width: 4),
          Text(
            '24/7 ER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.emergencyDarkRed,
            ),
          ),
        ],
      ),
    );
  }
}
