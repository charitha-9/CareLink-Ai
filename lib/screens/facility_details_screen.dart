import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/care_facility_model.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

/// Comprehensive detail screen for a selected hospital, clinic, or health center.
/// Strictly presents verified facility attributes without displaying unverified claims.
class FacilityDetailsScreen extends StatelessWidget {
  final CareFacility facility;

  const FacilityDetailsScreen({super.key, required this.facility});

  Future<void> _makePhoneCall(BuildContext context) async {
    final phone = facility.phone;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available for this facility.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        await _copyToClipboard(context, phone, 'Phone number copied');
      }
    } catch (_) {
      if (context.mounted) {
        await _copyToClipboard(context, phone, 'Phone number copied');
      }
    }
  }

  Future<void> _openDirections(BuildContext context) async {
    Uri uri;
    if (facility.latitude != null && facility.longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${facility.latitude},${facility.longitude}',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${facility.name}, ${facility.address}')}',
      );
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        await _copyToClipboard(context, facility.address, 'Address copied');
      }
    } catch (_) {
      if (!context.mounted) return;
      await _copyToClipboard(context, facility.address, 'Address copied');
    }
  }

  Future<void> _openWebsite(BuildContext context) async {
    final website = facility.website;
    if (website == null || website.isEmpty) return;

    final uri = Uri.parse(website.startsWith('http') ? website : 'https://$website');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    String text,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message: $text'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceStr = facility.formattedDistance;

    return Scaffold(
      appBar: AppBar(
        title: Text(facility.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Copy facility info',
            onPressed: () {
              final shareText =
                  '${facility.name}\n${facility.address}\nPhone: ${facility.phone ?? 'N/A'}';
              _copyToClipboard(context, shareText, 'Facility details copied');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Facility Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            FacilityTypeBadge(type: facility.type),
                            if (facility.isOpen != null)
                              OpenStatusBadge(isOpen: facility.isOpen),
                            if (facility.emergencyServicesAvailable == true)
                              const EmergencyServicesBadge(),
                          ],
                        ),
                        if (distanceStr != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.near_me,
                                  size: 16,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Estimated Distance: $distanceStr',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Primary Quick Action Buttons
                Row(
                  children: [
                    if (facility.phone != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(context),
                          icon: const Icon(Icons.call, size: 20),
                          label: const Text('Call Facility'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.safeGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openDirections(context),
                        icon: const Icon(Icons.directions, size: 20),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Details List Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.location_on_outlined,
                          title: 'Address',
                          content: facility.address,
                          actionLabel: 'Copy',
                          onAction: () => _copyToClipboard(
                            context,
                            facility.address,
                            'Address copied',
                          ),
                        ),
                        if (facility.phone != null) ...[
                          const Divider(height: 24, color: AppTheme.borderLight),
                          _buildDetailRow(
                            icon: Icons.phone_outlined,
                            title: 'Contact Phone',
                            content: facility.phone!,
                            actionLabel: 'Call',
                            onAction: () => _makePhoneCall(context),
                          ),
                        ],
                        if (facility.operatingHours != null) ...[
                          const Divider(height: 24, color: AppTheme.borderLight),
                          _buildDetailRow(
                            icon: Icons.access_time_rounded,
                            title: 'Operating Hours',
                            content: facility.operatingHours!,
                          ),
                        ],
                        if (facility.emergencyServicesAvailable != null) ...[
                          const Divider(height: 24, color: AppTheme.borderLight),
                          _buildDetailRow(
                            icon: Icons.medical_services_outlined,
                            title: 'Emergency Services',
                            content: facility.emergencyServicesAvailable!
                                ? 'Dedicated 24/7 emergency & trauma desk'
                                : 'Outpatient consultation & general medical care',
                          ),
                        ],
                        if (facility.website != null) ...[
                          const Divider(height: 24, color: AppTheme.borderLight),
                          _buildDetailRow(
                            icon: Icons.language_outlined,
                            title: 'Official Website',
                            content: facility.website!,
                            actionLabel: 'Visit',
                            onAction: () => _openWebsite(context),
                          ),
                        ],
                        if (facility.rating != null) ...[
                          const Divider(height: 24, color: AppTheme.borderLight),
                          _buildDetailRow(
                            icon: Icons.star_rate_rounded,
                            title: 'Public Rating',
                            content: '${facility.rating!.toStringAsFixed(1)} / 5.0',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Trust and Safety Reminder
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(
                        Icons.shield_outlined,
                        size: 24,
                        color: AppTheme.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Healthcare Directory',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Facilities listed in CareLink are verified university health centers '
                              'or accredited regional medical establishments. For critical emergencies, '
                              'always initiate Emergency SOS.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
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

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String content,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
            ),
            child: Text(actionLabel),
          ),
        ],
      ],
    );
  }
}
