import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';
import '../models/user.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'saved_posts_screen.dart';
import 'blocked_users_screen.dart';
import 'user_posts_screen.dart';
import 'followers_screen.dart';
import 'following_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
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
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void refreshProfile() {
    setState(() => _isLoading = true);
    _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Failed to load profile'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF4ECDC4).withOpacity(0.1),
                              const Color(0xFF4ECDC4).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF4ECDC4).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Profile Avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF4ECDC4),
                                    const Color(0xFF4ECDC4).withOpacity(0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4ECDC4).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Nickname
                            Text(
                              _user!.nickname ?? 'No nickname set',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // User ID
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '@${_user!.customUserId}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatCard(
                                  'Posts',
                                  _user!.postCount.toString(),
                                  Icons.edit_note,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => UserPostsScreen(user: _user!),
                                      ),
                                    );
                                    // Refresh profile when returning from posts screen
                                    _loadUserProfile();
                                  },
                                ),
                                _buildStatCard(
                                  'Followers',
                                  _user!.followerCount.toString(),
                                  Icons.people,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => FollowersScreen(
                                          user: _user!,
                                          onFollowerCountChanged: _loadUserProfile,
                                        ),
                                      ),
                                    );
                                    // Refresh profile when returning from followers screen
                                    _loadUserProfile();
                                  },
                                ),
                                _buildStatCard(
                                  'Following',
                                  _user!.followingCount.toString(),
                                  Icons.person_add,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => FollowingScreen(
                                          user: _user!,
                                          onFollowingCountChanged: _loadUserProfile,
                                        ),
                                      ),
                                    );
                                    // Refresh profile when returning from following screen
                                    _loadUserProfile();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Profile Actions
                      _buildActionButton(
                        'Edit Profile',
                        Icons.edit_outlined,
                        () async {
                          if (_user != null) {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(user: _user!),
                              ),
                            );
                            
                            // Reload profile if changes were made
                            if (result == true) {
                              _loadUserProfile();
                            }
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Saved Posts Button
                      _buildActionButton(
                        'Saved Posts',
                        Icons.bookmark_outlined,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SavedPostsScreen(),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Blocked Users Button
                      _buildActionButton(
                        'Blocked Users',
                        Icons.block_outlined,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const BlockedUsersScreen(),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Terms of Service Section
                      _buildTermsOfServiceSection(),
                      
                      // Commented out for future implementation
                      // const SizedBox(height: 16),
                      // 
                      // _buildActionButton(
                      //   'Privacy Settings',
                      //   Icons.privacy_tip_outlined,
                      //   () {
                      //     // Navigate to privacy settings
                      //   },
                      // ),
                      // 
                      // const SizedBox(height: 16),
                      // 
                      // _buildActionButton(
                      //   'Help & Support',
                      //   Icons.help_outline,
                      //   () {
                      //     // Navigate to help
                      //   },
                      // ),
                      
                      const SizedBox(height: 32),
                      
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

  Widget _buildStatCard(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF4ECDC4),
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsOfServiceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.gavel,
                  size: 18,
                  color: Color(0xFF4ECDC4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildTermsSection(
            'Age Requirement',
            'You must be 18 years or older to use ZipSocial.',
            Icons.badge,
            Colors.red,
          ),
          
          _buildTermsSection(
            'Zero Tolerance Policy',
            'ZipSocial has ZERO TOLERANCE for hate speech, harassment, threats, explicit content, spam, or abuse. Violations result in immediate account suspension.',
            Icons.block,
            Colors.orange,
          ),
          
          _buildTermsSection(
            'Content Moderation',
            'All content is subject to automated and manual moderation. We reserve the right to remove content and suspend users without prior notice.',
            Icons.security,
            Colors.blue,
          ),
          
          _buildTermsSection(
            'Reporting System',
            'Report inappropriate content immediately. We respond to all reports within 24 hours and take swift action.',
            Icons.report,
            Colors.green,
          ),
          
          _buildTermsSection(
            'User Responsibilities',
            'You are responsible for all content you post and interactions. Respect other users and follow community guidelines.',
            Icons.person_outline,
            Colors.purple,
          ),
          
          _buildTermsSection(
            'Enforcement',
            'Violations may result in content removal, account suspension, or permanent ban. Appeals: hellozipsocial@gmail.com.',
            Icons.gavel,
            Colors.red.shade800,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Community Standards',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ZipSocial is a community-focused platform that prioritizes user safety and respectful communication. By using this app, you agree to our zero tolerance policy for objectionable content and abusive behavior.',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, String content, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
