import 'package:flutter/material.dart';

import '../models/emergency_model.dart';
import '../models/student_model.dart';
import '../services/campus_geofence_service.dart';
import '../services/emergency_service.dart';
import '../services/location_service.dart';

class EmergencyScreen extends StatefulWidget {
  final StudentModel student;
  final EmergencyService? emergencyService;
  final LocationService? locationService;
  final CampusGeofenceService? campusGeofenceService;
  final String? viewerId;
  final bool autoStartAutopilot;
  final DialerLauncher? dialerLauncher;

  const EmergencyScreen({
    super.key,
    required this.student,
    this.emergencyService,
    this.locationService,
    this.campusGeofenceService,
    this.viewerId,
    this.autoStartAutopilot = true,
    this.dialerLauncher,
  });

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late final EmergencyService _emergencyService;
  late final LocationService _locationService;
  late final CampusGeofenceService _geofenceService;
  late final String _viewerId;

  @override
  void initState() {
    super.initState();
    _emergencyService = widget.emergencyService ?? EmergencyService();
    _locationService = widget.locationService ?? LocationService();
    _geofenceService = widget.campusGeofenceService ??
        CampusGeofenceService(
          config: CampusGeofenceConfig.amityBengaluruPlaceholder,
        );
    _viewerId = widget.viewerId ?? widget.student.studentId;

    if (widget.autoStartAutopilot &&
        !_emergencyService.hasActiveEmergency &&
        _emergencyService.currentEmergency == null) {
      _startAutopilot();
    }
  }

  void _startAutopilot() {
    _emergencyService.startEmergencyAutopilot(
      student: widget.student,
      locationService: _locationService,
      geofenceService: _geofenceService,
      dialerLauncher: widget.dialerLauncher,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Privacy Authorization Check
    final isAuthorized = _emergencyService.isAuthorizedViewer(
      viewerId: _viewerId,
      student: widget.student,
    );

    if (!isAuthorized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CareLink Emergency'),
          backgroundColor: Colors.red.shade800,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 72,
                  color: Colors.red.shade700,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'You are not authorized to view this emergency session. '
                  'Emergency records are restricted to registered student contacts and campus responders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _emergencyService,
      builder: (context, _) {
        final emergency = _emergencyService.currentEmergency;

        // Countdown State View
        if (emergency?.status == EmergencyStatus.countdown) {
          return _buildCountdownScreen(context);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Active Emergency',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: _getStatusColor(emergency?.status),
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              if (emergency?.status == EmergencyStatus.resolved ||
                  emergency?.status == EmergencyStatus.cancelled)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusHeader(emergency),
                  const SizedBox(height: 16),
                  _buildStudentProfileCard(widget.student),
                  const SizedBox(height: 16),
                  _buildLocationStatusCard(emergency),
                  const SizedBox(height: 16),
                  _buildRespondersCard(emergency),
                  if (emergency?.status ==
                      EmergencyStatus.waitingFor112Approval) ...[
                    const SizedBox(height: 16),
                    _build112ApprovalCard(context),
                  ],
                  const SizedBox(height: 24),
                  _buildActionButtons(context, emergency),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 3-SECOND COUNTDOWN VIEW
  // ------------------------------------------------------------

  Widget _buildCountdownScreen(BuildContext context) {
    final seconds = _emergencyService.countdownSeconds;

    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'EMERGENCY INITIATED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Emergency responders will be notified automatically once the countdown ends.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.red.shade800,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$seconds',
                    style: const TextStyle(
                      fontSize: 68,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  key: const Key('cancelCountdownButton'),
                  onPressed: () {
                    _emergencyService.cancelEmergency();
                  },
                  icon: const Icon(Icons.cancel, size: 28),
                  label: const Text(
                    'CANCEL EMERGENCY',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // STATUS HEADER
  // ------------------------------------------------------------

  Widget _buildStatusHeader(EmergencyModel? emergency) {
    final status = emergency?.status ?? EmergencyStatus.idle;
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(120), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(status), color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(status),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusSubtitle(status),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STUDENT REGISTERED INFO (HOSTEL ROOM ISOLATION)
  // ------------------------------------------------------------

  Widget _buildStudentProfileCard(StudentModel student) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  student.studentId,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registered Hostel Block',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student.hostelBlock ?? 'Not Specified',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registered Room Number',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        student.roomNumber ?? 'Not Specified',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '📍 Room verified from Student Profile (not GPS)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LOCATION & CAMPUS GEOFENCE CARD
  // ------------------------------------------------------------

  Widget _buildLocationStatusCard(EmergencyModel? emergency) {
    final hasCoords =
        emergency?.latitude != null && emergency?.longitude != null;
    final campusStatus = emergency?.campusStatus ?? CampusStatus.unknown;
    final isLiveTracking = emergency?.liveTrackingActive ?? false;

    String campusText;
    Color campusColor;
    IconData campusIcon;

    switch (campusStatus) {
      case CampusStatus.insideCampus:
        campusText = 'Inside Campus Perimeter';
        campusColor = Colors.green.shade700;
        campusIcon = Icons.check_circle_outline;
        break;
      case CampusStatus.outsideCampus:
        campusText = 'Outside Campus Perimeter';
        campusColor = Colors.deepOrange;
        campusIcon = Icons.warning_amber_outlined;
        break;
      case CampusStatus.unknown:
        campusText = 'Determining Campus Status...';
        campusColor = Colors.grey;
        campusIcon = Icons.help_outline;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(campusIcon, color: campusColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  campusText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: campusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hasCoords
                  ? 'GPS: ${emergency!.latitude!.toStringAsFixed(5)}, ${emergency.longitude!.toStringAsFixed(5)}'
                  : 'GPS: Acquiring coordinates...',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLiveTracking ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isLiveTracking
                      ? 'Live GPS tracking active (Foreground)'
                      : 'Live GPS tracking standby',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isLiveTracking ? Colors.green.shade800 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // RESPONDERS NOTIFIED & ESCALATION CARD
  // ------------------------------------------------------------

  Widget _buildRespondersCard(EmergencyModel? emergency) {
    final campusStatus = emergency?.campusStatus ?? CampusStatus.unknown;
    final isInside = campusStatus == CampusStatus.insideCampus;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escalation & Responders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (isInside) ...[
              _buildResponderRow(
                priority: '1',
                role: 'Roommate',
                notified: emergency?.roommateNotified ?? false,
              ),
              _buildResponderRow(
                priority: '2',
                role: 'Hostel Warden',
                notified: emergency?.wardenNotified ?? false,
              ),
              _buildResponderRow(
                priority: '3',
                role: 'Campus Clinic / Doctor',
                notified: emergency?.doctorNotified ?? false,
              ),
              _buildResponderRow(
                priority: '4',
                role: 'Parent / Guardian',
                notified: emergency?.parentNotified ?? false,
              ),
            ] else ...[
              _buildResponderRow(
                priority: '1',
                role: 'Parent / Guardian',
                notified: emergency?.parentNotified ?? false,
              ),
              _buildResponderRow(
                priority: '2',
                role: 'Hostel Warden',
                notified: emergency?.wardenNotified ?? false,
              ),
              _buildResponderRow(
                priority: '3',
                role: '112 Emergency Services',
                notified: emergency?.approvalFor112 ?? false,
                isApprovalBased: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponderRow({
    required String priority,
    required String role,
    required bool notified,
    bool isApprovalBased = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              priority,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              role,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: notified
                  ? Colors.green.shade50
                  : (isApprovalBased
                      ? Colors.orange.shade50
                      : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notified
                    ? Colors.green.shade300
                    : (isApprovalBased
                        ? Colors.orange.shade300
                        : Colors.grey.shade300),
              ),
            ),
            child: Text(
              notified
                  ? 'Notified ✓'
                  : (isApprovalBased ? 'Approval Required' : 'Pending...'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: notified
                    ? Colors.green.shade800
                    : (isApprovalBased
                        ? Colors.orange.shade900
                        : Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 112 APPROVAL CARD
  // ------------------------------------------------------------

  Widget _build112ApprovalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade400, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Outside Campus Emergency: 112 Facilitation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'The student is currently outside campus bounds. You can approve facilitating 112 National Emergency Services. '
            'CareLink AI will open your device dialer with 112 pre-filled; it will NEVER place the call automatically.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('approve112Button'),
            onPressed: () async {
              await _emergencyService.approve112(
                locationService: _locationService,
                dialerLauncher: widget.dialerLauncher,
              );
            },
            icon: const Icon(Icons.phone),
            label: const Text('Approve & Open Phone Dialer (112)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('dismiss112Button'),
            onPressed: () {
              _emergencyService.dismiss112Approval(
                locationService: _locationService,
              );
            },
            child: const Text('Dismiss (Keep Campus Responders Only)'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ACTIONS
  // ------------------------------------------------------------

  Widget _buildActionButtons(BuildContext context, EmergencyModel? emergency) {
    final status = emergency?.status ?? EmergencyStatus.idle;

    if (status == EmergencyStatus.resolved ||
        status == EmergencyStatus.cancelled) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Return to Home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        key: const Key('resolveEmergencyButton'),
        onPressed: () {
          _confirmResolveEmergency(context);
        },
        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
        label: const Text(
          'RESOLVE EMERGENCY',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.green, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _confirmResolveEmergency(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Emergency?'),
        content: const Text(
          'Are you sure the emergency situation is safely resolved? '
          'This will stop live GPS tracking and mark the response complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirmResolveButton'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _emergencyService.resolveEmergency();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Resolve'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPER MAPPINGS
  // ------------------------------------------------------------

  Color _getStatusColor(EmergencyStatus? status) {
    switch (status) {
      case EmergencyStatus.countdown:
      case EmergencyStatus.active:
        return Colors.red.shade700;
      case EmergencyStatus.locating:
      case EmergencyStatus.checkingCampus:
      case EmergencyStatus.escalating:
        return Colors.orange.shade800;
      case EmergencyStatus.waitingFor112Approval:
        return Colors.redAccent.shade700;
      case EmergencyStatus.resolved:
        return Colors.green.shade700;
      case EmergencyStatus.cancelled:
        return Colors.grey.shade700;
      default:
        return Colors.deepPurple;
    }
  }

  IconData _getStatusIcon(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.countdown:
      case EmergencyStatus.active:
        return Icons.emergency;
      case EmergencyStatus.locating:
        return Icons.gps_fixed;
      case EmergencyStatus.checkingCampus:
        return Icons.domain;
      case EmergencyStatus.escalating:
        return Icons.campaign;
      case EmergencyStatus.waitingFor112Approval:
        return Icons.warning_amber_rounded;
      case EmergencyStatus.resolved:
        return Icons.check_circle;
      case EmergencyStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusTitle(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.countdown:
        return 'Safety Countdown';
      case EmergencyStatus.locating:
        return 'Locating Student...';
      case EmergencyStatus.checkingCampus:
        return 'Checking Campus Geofence...';
      case EmergencyStatus.escalating:
        return 'Escalating to Responders...';
      case EmergencyStatus.waitingFor112Approval:
        return 'Waiting for 112 Approval';
      case EmergencyStatus.active:
        return 'Active Emergency';
      case EmergencyStatus.resolved:
        return 'Emergency Resolved';
      case EmergencyStatus.cancelled:
        return 'Emergency Cancelled';
      default:
        return 'Ready';
    }
  }

  String _getStatusSubtitle(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.countdown:
        return 'You have 3 seconds to cancel if triggered by mistake.';
      case EmergencyStatus.locating:
        return 'Acquiring high-accuracy GPS coordinates.';
      case EmergencyStatus.checkingCampus:
        return 'Evaluating position against campus boundaries.';
      case EmergencyStatus.escalating:
        return 'Notifying designated responders according to protocol.';
      case EmergencyStatus.waitingFor112Approval:
        return 'Student is outside campus. User/responder approval required for 112 dialer.';
      case EmergencyStatus.active:
        return 'Live tracking active. Responders deployed.';
      case EmergencyStatus.resolved:
        return 'Situation marked safe. Live tracking terminated.';
      case EmergencyStatus.cancelled:
        return 'Emergency was cancelled before escalation.';
      default:
        return '';
    }
  }
}
