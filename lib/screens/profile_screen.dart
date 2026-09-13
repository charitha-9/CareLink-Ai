import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  /// Optional student instance; defaults to [AuthService.instance.currentStudent]
  final StudentModel? student;

  const ProfileScreen({super.key, this.student});

  // ------------------------------------------------------------
  // EXPOSED GETTERS FOR OTHER CARELINK MODULES
  // ------------------------------------------------------------

  StudentModel? get _activeStudent =>
      student ?? AuthService.instance.currentStudent;

  String get studentId => _activeStudent?.studentId ?? '';
  String get name => _activeStudent?.name ?? '';
  String get phone => _activeStudent?.phone ?? '';
  String get email => _activeStudent?.email ?? '';
  String get hostel => _activeStudent?.hostel ?? '';
  String get block => _activeStudent?.block ?? '';
  String get room => _activeStudent?.room ?? '';
  String get parentName => _activeStudent?.parentName ?? '';
  String get parentPhone => _activeStudent?.parentPhone ?? '';
  String? get roommate1Name => _activeStudent?.roommate1Name;
  String? get roommate1Phone => _activeStudent?.roommate1Phone;
  String? get roommate2Name => _activeStudent?.roommate2Name;
  String? get roommate2Phone => _activeStudent?.roommate2Phone;

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of CareLink AI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService.instance.logout();
      if (context.mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? Colors.deepPurple.shade400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _activeStudent;

    if (current == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Student Profile'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No student profile found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please log in or register a new student profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Student Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple,
                          Colors.deepPurple.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Text(
                            current.name.isNotEmpty
                                ? current.name[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                current.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${current.studentId}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                current.email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // GPS vs Profile Notice Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.blue.shade800,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Residence & GPS Dispatch: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text:
                                      'GPS confirms whether you are on or off campus, while your registered hostel, block, and room guide responders to your exact room.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Section 1: Campus Residence
                  _buildSectionCard(
                    title: 'Hostel Residence',
                    icon: Icons.apartment,
                    children: [
                      _buildInfoRow(
                        icon: Icons.domain,
                        label: 'Hostel',
                        value: current.hostel,
                      ),
                      _buildInfoRow(
                        icon: Icons.grid_view,
                        label: 'Block',
                        value: current.block,
                      ),
                      _buildInfoRow(
                        icon: Icons.meeting_room,
                        label: 'Room Number',
                        value: current.room,
                      ),
                      _buildInfoRow(
                        icon: Icons.phone,
                        label: 'Student Phone',
                        value: current.phone,
                      ),
                    ],
                  ),

                  // Section 2: Emergency & Trusted Contacts
                  _buildSectionCard(
                    title: 'Emergency Contacts',
                    icon: Icons.contact_emergency,
                    children: [
                      _buildInfoRow(
                        icon: Icons.family_restroom,
                        label: 'Parent / Guardian',
                        value: '${current.parentName} (${current.parentPhone})',
                      ),
                      if (current.roommate1Name != null &&
                          current.roommate1Name!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.person_pin,
                          label: 'Roommate 1',
                          value:
                              '${current.roommate1Name} (${current.roommate1Phone ?? 'No phone'})',
                        ),
                      if (current.roommate2Name != null &&
                          current.roommate2Name!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.person_pin,
                          label: 'Roommate 2',
                          value:
                              '${current.roommate2Name} (${current.roommate2Phone ?? 'No phone'})',
                        ),
                      if (current.wardenPhone != null &&
                          current.wardenPhone!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.security,
                          label: 'Hostel Warden Phone',
                          value: current.wardenPhone!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Proceed to Home Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToHome(context),
                      icon: const Icon(Icons.home, size: 22),
                      label: const Text(
                        'Continue to CareLink Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
