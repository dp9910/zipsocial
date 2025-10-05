import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _showPasswordSection = false;
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuthService.currentUser;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: _currentPasswordController.text,
      );

      await _currentUser!.reauthenticateWithCredential(credential);
      
      // Update password
      await _currentUser!.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: Color(0xFF8CE830),
          ),
        );
        
        // Clear form and hide password section
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() => _showPasswordSection = false);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update password';
        
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'wrong-password':
              errorMessage = 'Current password is incorrect';
              break;
            case 'weak-password':
              errorMessage = 'New password is too weak';
              break;
            case 'requires-recent-login':
              errorMessage = 'Please sign out and sign in again to change password';
              break;
            default:
              errorMessage = e.message ?? errorMessage;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Information Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        color: const Color(0xFF8CE830),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Email
                  if (_currentUser?.email != null) ...[
                    _buildInfoRow(
                      'Email',
                      _currentUser!.email!,
                      Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Phone Number
                  if (_currentUser?.phoneNumber != null) ...[
                    _buildInfoRow(
                      'Phone Number',
                      _currentUser!.phoneNumber!,
                      Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // User ID
                  _buildInfoRow(
                    'User ID',
                    _currentUser?.uid ?? 'Unknown',
                    Icons.fingerprint_outlined,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Account Creation Date
                  if (_currentUser?.metadata.creationTime != null)
                    _buildInfoRow(
                      'Member Since',
                      _formatDate(_currentUser!.metadata.creationTime!),
                      Icons.calendar_today_outlined,
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Security Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security_outlined,
                        color: const Color(0xFF8CE830),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Security',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Change Password Button (only for email/password users)
                  if (_currentUser?.email != null && 
                      _currentUser?.providerData.any((info) => info.providerId == 'password') == true)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _showPasswordSection = !_showPasswordSection);
                            },
                            icon: Icon(_showPasswordSection ? Icons.expand_less : Icons.expand_more),
                            label: Text(_showPasswordSection ? 'Hide Password Change' : 'Change Password'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8CE830),
                              side: const BorderSide(color: Color(0xFF8CE830)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        
                        if (_showPasswordSection) ...[
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _currentPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Current Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your current password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _newPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a new password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm New Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your new password';
                                    }
                                    if (value != _newPasswordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _changePassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8CE830),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text('Update Password'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Password change is not available for social login accounts',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade600,
          size: 20,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.year}';
  }
}