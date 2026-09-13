import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal & Account Controllers
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Residence Controllers
  final _hostelController = TextEditingController();
  final _blockController = TextEditingController();
  final _roomController = TextEditingController();

  // Contact Controllers
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _roommate1NameController = TextEditingController();
  final _roommate1PhoneController = TextEditingController();
  final _roommate2NameController = TextEditingController();
  final _roommate2PhoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _hostelController.dispose();
    _blockController.dispose();
    _roomController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _roommate1NameController.dispose();
    _roommate1PhoneController.dispose();
    _roommate2NameController.dispose();
    _roommate2PhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the highlighted fields before submitting.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newStudent = StudentModel(
      studentId: _studentIdController.text.trim(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      hostel: _hostelController.text.trim(),
      block: _blockController.text.trim(),
      room: _roomController.text.trim(),
      parentName: _parentNameController.text.trim(),
      parentPhone: _parentPhoneController.text.trim(),
      roommate1Name: _roommate1NameController.text.trim().isEmpty
          ? null
          : _roommate1NameController.text.trim(),
      roommate1Phone: _roommate1PhoneController.text.trim().isEmpty
          ? null
          : _roommate1PhoneController.text.trim(),
      roommate2Name: _roommate2NameController.text.trim().isEmpty
          ? null
          : _roommate2NameController.text.trim(),
      roommate2Phone: _roommate2PhoneController.text.trim().isEmpty
          ? null
          : _roommate2PhoneController.text.trim(),
    );

    try {
      await AuthService.instance.signup(
        student: newStudent,
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Navigate to Profile screen as required by the flow: Login -> Signup -> Profile -> Home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      const genericMsg = 'Registration failed. Please try again.';
      setState(() {
        _errorMessage = genericMsg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(genericMsg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 20),
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
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool isPassword = false,
    bool isRequired = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
              if (isRequired)
                const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: isPassword && _obscurePassword,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(prefixIcon, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
              ),
            ),
            validator: validator ??
                (val) {
                  if (isRequired && (val == null || val.trim().isEmpty)) {
                    return '$label is required';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Student Registration',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Section 1: Personal & Account
                    _buildSectionCard(
                      title: 'Student & Account Details',
                      icon: Icons.person_outline,
                      subtitle: 'Basic identity and CareLink credentials',
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'e.g. Charitha Silva',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        _buildTextField(
                          controller: _studentIdController,
                          label: 'Student ID',
                          hint: 'e.g. STU-2024-001',
                          prefixIcon: Icons.perm_identity_outlined,
                        ),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'e.g. +94 77 123 4567',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (val.trim().length < 7) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Campus Email',
                          hint: 'student@carelink.edu',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Min. 6 characters',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Password is required';
                            }
                            if (val.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    // Section 2: Hostel Residence
                    _buildSectionCard(
                      title: 'Campus Residence',
                      icon: Icons.home_work_outlined,
                      subtitle:
                          'Hostel, block, and room are registered here. GPS locates campus boundary, not your room.',
                      children: [
                        _buildTextField(
                          controller: _hostelController,
                          label: 'Hostel Name',
                          hint: 'e.g. Emerald Hall / Nilwala',
                          prefixIcon: Icons.apartment_outlined,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _blockController,
                                label: 'Block',
                                hint: 'e.g. B / 3',
                                prefixIcon: Icons.grid_view_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _roomController,
                                label: 'Room Number',
                                hint: 'e.g. 304 / B-12',
                                prefixIcon: Icons.door_front_door_outlined,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Section 3: Emergency Contacts
                    _buildSectionCard(
                      title: 'Emergency Contacts',
                      icon: Icons.contact_emergency_outlined,
                      subtitle:
                          'Trusted contacts notified by Emergency Autopilot during urgent medical situations',
                      children: [
                        _buildTextField(
                          controller: _parentNameController,
                          label: 'Parent / Guardian Name',
                          hint: 'e.g. Sunil Silva',
                          prefixIcon: Icons.family_restroom_outlined,
                        ),
                        _buildTextField(
                          controller: _parentPhoneController,
                          label: 'Parent / Guardian Phone',
                          hint: 'e.g. +94 71 987 6543',
                          prefixIcon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Parent phone number is required';
                            }
                            if (val.trim().length < 7) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const Divider(height: 20),
                        _buildTextField(
                          controller: _roommate1NameController,
                          label: 'Roommate 1 Name',
                          hint: 'e.g. Kasun Perera',
                          prefixIcon: Icons.person_outline,
                        ),
                        _buildTextField(
                          controller: _roommate1PhoneController,
                          label: 'Roommate 1 Phone',
                          hint: 'e.g. +94 76 555 1234',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Roommate 1 phone number is required';
                            }
                            if (val.trim().length < 7) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const Divider(height: 20),
                        _buildTextField(
                          controller: _roommate2NameController,
                          label: 'Roommate 2 Name (Optional)',
                          hint: 'e.g. Nuwan Fernando',
                          prefixIcon: Icons.person_outline,
                          isRequired: false,
                        ),
                        _buildTextField(
                          controller: _roommate2PhoneController,
                          label: 'Roommate 2 Phone (Optional)',
                          hint: 'e.g. +94 78 444 5678',
                          prefixIcon: Icons.phone_outlined,
                          isRequired: false,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Submit Button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.deepPurple.withValues(alpha: 0.6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Register Profile',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
