import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../services/supabase_auth_service.dart';
import '../screens/user_profile_screen.dart';

class FollowingScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback? onFollowingCountChanged;

  const FollowingScreen({
    Key? key,
    required this.user,
    this.onFollowingCountChanged,
  }) : super(key: key);

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<AppUser> _following = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    setState(() => _isLoading = true);
    
    try {
      final following = await SupabaseAuthService.getFollowing(userId: widget.user.id);
      if (mounted) {
        setState(() {
          _following = following;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading following: $e')),
        );
      }
    }
  }

  Future<void> _unfollowUser(AppUser userToUnfollow) async {
    try {
      await SupabaseAuthService.unfollowUser(userToUnfollow.id);
      
      // Remove from local list
      setState(() {
        _following.removeWhere((user) => user.id == userToUnfollow.id);
      });
      
      // Notify parent screen that following count changed
      widget.onFollowingCountChanged?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unfollowed ${userToUnfollow.nickname}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unfollowing user: $e')),
        );
      }
    }
  }

  void _showUnfollowDialog(AppUser userToUnfollow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfollow User'),
        content: Text('Unfollow ${userToUnfollow.nickname ?? userToUnfollow.customUserId}? You will no longer see their posts in your feed.'),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
              _unfollowUser(userToUnfollow);
            },
            child: const Text(
              'Unfollow',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = SupabaseAuthService.currentUser?.id == widget.user.id;

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: Theme.of(context).brightness,
        ),
        title: Text(isOwnProfile ? 'Following' : '${widget.user.nickname} Following'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: const Color(0xFF4ECDC4),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Following ${_following.length} ${_following.length == 1 ? 'person' : 'people'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Following List
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Dismiss keyboard when tapping anywhere on the screen
                FocusScope.of(context).unfocus();
              },
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _following.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isOwnProfile ? 'Not following anyone yet' : 'Not following anyone',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isOwnProfile 
                                  ? 'Discover and follow other users to see their posts!'
                                  : 'This user isn\'t following anyone yet',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFollowing,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _following.length,
                          itemBuilder: (context, index) {
                            final followedUser = _following[index];
                            return _buildFollowingItem(followedUser, isOwnProfile);
                          },
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingItem(AppUser followedUser, bool isOwnProfile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
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
            ),
            child: const Icon(
              Icons.person,
              size: 25,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          
          // User info
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      userId: followedUser.id,
                      customUserId: followedUser.customUserId,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    followedUser.nickname ?? 'No nickname',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${followedUser.customUserId}',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF4ECDC4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (followedUser.preferredZipcode != null && followedUser.preferredZipcode!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          followedUser.preferredZipcode!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Unfollow button (only show for own profile)
          if (isOwnProfile)
            OutlinedButton(
              onPressed: () => _showUnfollowDialog(followedUser),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(60, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                'Unfollow',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}