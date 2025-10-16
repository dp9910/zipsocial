import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/supabase_auth_service.dart'; // Changed import
import 'followers_screen.dart';
import 'following_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? customUserId;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.customUserId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  AppUser? _user;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  bool _isAccessDenied = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkFollowStatus();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await SupabaseAuthService.getUserProfileById(widget.userId); // Changed service call
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
          _isAccessDenied = user == null; // If user is null, access might be denied
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAccessDenied = true; // Access denied or error occurred
        });
      }
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await SupabaseAuthService.isFollowing(widget.userId); // Changed service call
      if (mounted) {
        setState(() => _isFollowing = isFollowing);
      }
    } catch (e) {
      // Handle error silently for follow status
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isFollowLoading = true);

    try {
      if (_isFollowing) {
        await SupabaseAuthService.unfollowUser(widget.userId); // Changed service call
      } else {
        await SupabaseAuthService.followUser(widget.userId); // Changed service call
      }
      
      setState(() => _isFollowing = !_isFollowing);
      
      // Reload user profile to get updated follower count
      await _loadUserProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowLoading = false);
      }
    }
  }

  void _navigateToFollowers() async {
    if (_user == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FollowersScreen(
          user: _user!,
          onFollowerCountChanged: _loadUserProfile,
        ),
      ),
    );
    _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isAccessDenied ? Icons.block : Icons.person_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _isAccessDenied 
                    ? 'Access Restricted'
                    : 'User not found',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isAccessDenied 
                    ? 'This user has restricted access to their profile.'
                    : 'The user you are looking for does not exist.',
                style: const TextStyle(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isOwnProfile = SupabaseAuthService.currentUser?.id == widget.userId; // Changed service call

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.nickname ?? 'Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
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
                    width: 120,
                    height: 120,
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
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Nickname
                  Text(
                    _user!.nickname ?? 'No nickname',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // User ID
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '@${_user!.customUserId}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        'Posts',
                        _user!.postCount.toString(),
                        Icons.edit_note,
                      ),
                      _buildStatCard(
                        'Followers',
                        _user!.followerCount.toString(),
                        Icons.people,
                        onTap: _navigateToFollowers,
                      ),
                      _buildStatCard(
                        'Following',
                        _user!.followingCount.toString(),
                        Icons.person_add,
                      ),
                    ],
                  ),
                  
                  if (!isOwnProfile) ...[
                    const SizedBox(height: 24),
                    
                    // Follow Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isFollowLoading ? null : _toggleFollow,
                        icon: _isFollowLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                _isFollowing ? Icons.person_remove : Icons.person_add,
                              ),
                        label: Text(
                          _isFollowing ? 'Unfollow' : 'Follow',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing 
                              ? Colors.grey.shade600 
                              : const Color(0xFF4ECDC4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Bio Section
            if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
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
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _user!.bio!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            
            // Posts Section (placeholder)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posts will appear here when they start sharing',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF4ECDC4),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
