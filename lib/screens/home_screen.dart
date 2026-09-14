import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/feature_card.dart';
import 'emergency_history_screen.dart';
import 'nearby_care_screen.dart';

/// Main Home/Dashboard for CareLink AI.
/// Provides prominent emergency access and intuitive navigation to
/// AI Health Check, Nearby Care, Emergency History, and Student Profile.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToNearbyCare(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NearbyCareScreen(),
      ),
    );
  }

  void _navigateToEmergencyHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EmergencyHistoryScreen(),
      ),
    );
  }

  void _navigateToTriage(BuildContext context) {
    // If the triage route is defined in MaterialApp routes, use it;
    // otherwise gracefully show the triage launcher info
    final navigator = Navigator.of(context);
    try {
      navigator.pushNamed('/triage');
    } catch (_) {
      _showModulePreview(
        context,
        title: 'AI Health Check',
        description:
            'AI Preliminary Triage is integrated on the main navigation route. '
            'When merged with the ai-triage module, this launches the full symptom questionnaire.',
      );
    }
  }

  void _navigateToProfile(BuildContext context) {
    final navigator = Navigator.of(context);
    try {
      navigator.pushNamed('/profile');
    } catch (_) {
      _showModulePreview(
        context,
        title: 'Student Profile',
        description:
            'Student Profile holds hostel block, room number, and trusted emergency contacts. '
            'When merged with the auth-profile module, this launches the full profile manager.',
      );
    }
  }

  void _showModulePreview(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmergencySafetyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => const _EmergencyConfirmationDialog(),
    );
  }

  Future<void> _callEmergencyNumber(BuildContext context, String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialing emergency number: $number'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Call emergency line: $number'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.shield_rounded, size: 22),
            SizedBox(width: 8),
            Text('CareLink AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            tooltip: 'Student Profile',
            onPressed: () => _navigateToProfile(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Greeting and Campus context
                const Text(
                  'Hello! 👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(
                      Icons.location_on,
                      size: 15,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Amity University Campus • Safe & Connected',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // ============================================================
                // HERO EMERGENCY SOS ACTION
                // High contrast, prominent, designed for high-stress situations
                // ============================================================
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFD32F2F),
                        Color(0xFFB71C1C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade700.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      onTap: () => _showEmergencySafetyDialog(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLg,
                          vertical: 20,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emergency,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'EMERGENCY SOS',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Tap for rapid campus emergency response',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // Section Title: Quick Navigation
                const Text(
                  'Care & Navigation Services',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // 2x2 Feature Grid
                Row(
                  children: [
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.health_and_safety_rounded,
                        iconColor: AppTheme.primary,
                        badgeText: 'AI',
                        badgeColor: AppTheme.primary,
                        title: 'AI Health Check',
                        subtitle: 'Preliminary triage & care advice',
                        onTap: () => _navigateToTriage(context),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.local_hospital_rounded,
                        iconColor: AppTheme.safeGreen,
                        badgeText: 'Nearby',
                        badgeColor: AppTheme.safeGreen,
                        title: 'Nearby Care',
                        subtitle: 'Hospitals, clinics & campus center',
                        onTap: () => _navigateToNearbyCare(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingSm),

                Row(
                  children: [
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.history_rounded,
                        iconColor: Colors.blueGrey.shade700,
                        badgeText: 'History',
                        badgeColor: Colors.blueGrey,
                        title: 'Emergency Logs',
                        subtitle: 'Past incident history & resolution',
                        onTap: () => _navigateToEmergencyHistory(context),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.badge_rounded,
                        iconColor: Colors.teal.shade700,
                        badgeText: 'Profile',
                        badgeColor: Colors.teal,
                        title: 'Student Profile',
                        subtitle: 'Hostel, room & trusted contacts',
                        onTap: () => _navigateToProfile(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // Section: Campus Quick Emergency Lines
                const Text(
                  'Direct Emergency Hotlines',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    child: Column(
                      children: [
                        _buildHotlineRow(
                          context,
                          title: 'Campus Medical Center',
                          number: '+91 120 439 2000',
                          badge: 'Campus 24/7',
                        ),
                        const Divider(height: 16, color: AppTheme.borderLight),
                        _buildHotlineRow(
                          context,
                          title: 'Campus Security Control',
                          number: '+91 120 439 2100',
                          badge: 'Security',
                        ),
                        const Divider(height: 16, color: AppTheme.borderLight),
                        _buildHotlineRow(
                          context,
                          title: 'National Emergency Service',
                          number: '112',
                          badge: 'Police / ER',
                          isCritical: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Trustworthy Medical Disclaimer
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'CareLink AI provides preliminary health guidance and coordination. '
                          'It is not a substitute for professional medical diagnosis or clinical treatment.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotlineRow(
    BuildContext context, {
    required String title,
    required String number,
    required String badge,
    bool isCritical = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isCritical
                          ? AppTheme.emergencyLightRed
                          : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCritical
                            ? AppTheme.emergencyDarkRed
                            : AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                number,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.phone_in_talk_rounded,
            color: isCritical ? AppTheme.emergencyRed : AppTheme.safeGreen,
            size: 22,
          ),
          tooltip: 'Call $number',
          onPressed: () => _callEmergencyNumber(context, number),
        ),
      ],
    );
  }
}

/// Safety countdown confirmation dialog for Emergency SOS.
/// Prevents accidental triggers while keeping emergency response immediate.
class _EmergencyConfirmationDialog extends StatefulWidget {
  const _EmergencyConfirmationDialog();

  @override
  State<_EmergencyConfirmationDialog> createState() =>
      _EmergencyConfirmationDialogState();
}

class _EmergencyConfirmationDialogState
    extends State<_EmergencyConfirmationDialog> {
  Timer? _countdownTimer;
  int _secondsRemaining = 3;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _confirmEmergency();
      }
    });
  }

  void _confirmEmergency() {
    _countdownTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Emergency SOS Activated! Notifying campus response... 🚨',
        ),
        backgroundColor: AppTheme.emergencyDarkRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      backgroundColor: Colors.white,
      title: Row(
        children: const [
          Icon(Icons.emergency, color: AppTheme.emergencyRed, size: 28),
          SizedBox(width: 8),
          Text(
            'Emergency SOS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.emergencyDarkRed,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Initiating emergency campus coordination in:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5),
          ),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.emergencyLightRed,
            child: Text(
              '$_secondsRemaining',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.emergencyDarkRed,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'If this is an accidental press, tap Cancel now.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            _countdownTimer?.cancel();
            Navigator.of(context).pop();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _confirmEmergency,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emergencyDarkRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Now'),
        ),
      ],
    );
  }
}
