import 'package:flutter/material.dart';
import '../models/emergency_history_model.dart';
import '../theme/app_theme.dart';
import '../widgets/carelink_states.dart';

/// Screen displaying student emergency incident history and resolution records.
/// Fully compatible with Firebase backend data models.
class EmergencyHistoryScreen extends StatefulWidget {
  final List<EmergencyHistoryModel>? initialHistory;

  const EmergencyHistoryScreen({super.key, this.initialHistory});

  @override
  State<EmergencyHistoryScreen> createState() => _EmergencyHistoryScreenState();
}

class _EmergencyHistoryScreenState extends State<EmergencyHistoryScreen> {
  late List<EmergencyHistoryModel> _historyList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _historyList = widget.initialHistory ?? [];
    if (widget.initialHistory == null) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate backend fetch
    await Future.delayed(const Duration(milliseconds: 250));

    if (mounted) {
      setState(() {
        _isLoading = false;
        // Clean default list (empty or verified record)
        _historyList = widget.initialHistory ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh logs',
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: _isLoading
              ? const CareLinkLoadingView(message: 'Loading emergency logs...')
              : _historyList.isEmpty
                  ? CareLinkEmptyView(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'No Emergency Incidents',
                      message:
                          'You have no past emergency incidents on record. '
                          'In case of any urgent crisis, tap Emergency SOS on the home screen.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      itemCount: _historyList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppTheme.spacingSm),
                      itemBuilder: (context, index) {
                        final item = _historyList[index];
                        return _buildHistoryCard(item);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(EmergencyHistoryModel item) {
    final isResolved = item.resolutionStatus.toLowerCase() == 'resolved';
    final statusColor = isResolved ? AppTheme.safeGreen : AppTheme.emergencyDarkRed;
    final statusBg =
        isResolved ? AppTheme.safeLightGreen : AppTheme.emergencyLightRed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.incidentType ?? 'Emergency Alert',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.resolutionStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Incident ID: ${item.emergencyId}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            if (item.summary != null) ...[
              const SizedBox(height: 8),
              Text(
                item.summary!,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            if (item.notifiedParties.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.notifiedParties.map((party) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Notified: $party',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Started: ${item.startedAt.toLocal().toString().split('.')[0]}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
