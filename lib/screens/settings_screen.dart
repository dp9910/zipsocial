import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase User
import '../services/supabase_auth_service.dart'; // Changed import
import '../models/user.dart'; // AppUser model
import 'edit_profile_screen.dart'; // Assuming this will be updated to use AppUser

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppUser? _appUser; // Using AppUser from our model
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await SupabaseAuthService.getUserProfile();
      if (mounted) {
        setState(() {
          _appUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appUser == null
              ? const Center(child: Text('Failed to load user data'))
              : SingleChildScrollView(
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
                                  color: const Color(0xFF4ECDC4),
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
                            if (_appUser?.email != null) ...[
                              _buildInfoRow(
                                'Email',
                                _appUser!.email!,
                                Icons.email_outlined,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // User ID (Supabase user ID)
                            _buildInfoRow(
                              'User ID',
                              _appUser?.id ?? 'Unknown',
                              Icons.fingerprint_outlined,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Custom User ID (from our users table)
                            _buildInfoRow(
                              'Custom User ID',
                              _appUser?.customUserId ?? 'Unknown',
                              Icons.tag,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Account Creation Date
                            if (_appUser?.createdAt != null)
                              _buildInfoRow(
                                'Member Since',
                                _formatDate(_appUser!.createdAt),
                                Icons.calendar_today_outlined,
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Security Section (Password Change - Placeholder)
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
                                  color: const Color(0xFF4ECDC4),
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
                            
                            // Placeholder for password change
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
                                      'Password change functionality will be implemented here. For now, please use the Supabase dashboard for password resets.',
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
                      
                      const SizedBox(height: 32),
                      
                      // Delete Account Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Show confirmation dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Account'),
                                content: const Text(
                                  'Are you sure you want to delete your account? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              try {
                                await SupabaseAuthService.deleteUserAccount();
                                if (mounted) {
                                  // Navigate to auth screen and clear all routes
                                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Account deleted successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error deleting account: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await SupabaseAuthService.signOut();
                              if (mounted) {
                                // Navigate to auth screen and clear all routes
                                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error signing out: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
