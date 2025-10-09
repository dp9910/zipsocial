import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/supabase_auth_service.dart';
import '../screens/user_profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback? onFollowerCountChanged;

  const FollowersScreen({
    Key? key,
    required this.user,
    this.onFollowerCountChanged,
  }) : super(key: key);

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<AppUser> _followers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoading = true);
    
    try {
      final followers = await SupabaseAuthService.getFollowers(userId: widget.user.id);
      if (mounted) {
        setState(() {
          _followers = followers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading followers: $e')),
        );
      }
    }
  }

  Future<void> _blockUser(AppUser userToBlock) async {
    try {
      await SupabaseAuthService.blockUser(userToBlock.id);
      
      // Remove from local list
      setState(() {
        _followers.removeWhere((user) => user.id == userToBlock.id);
      });
      
      // Notify parent screen that follower count changed
      widget.onFollowerCountChanged?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${userToBlock.nickname} has been removed from your followers')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error blocking user: $e')),
        );
      }
    }
  }

  void _showBlockDialog(AppUser userToBlock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Follower'),
        content: Text('Remove ${userToBlock.nickname ?? userToBlock.customUserId} from your followers? They will no longer be able to follow you until they request to follow again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _blockUser(userToBlock);
            },
            child: const Text(
              'Remove',
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
        title: Text(isOwnProfile ? 'Your Followers' : '${widget.user.nickname}\'s Followers'),
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
                  Icons.people,
                  color: const Color(0xFF8CE830),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_followers.length} ${_followers.length == 1 ? 'Follower' : 'Followers'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Followers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _followers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isOwnProfile ? 'No followers yet' : 'No followers',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isOwnProfile 
                                  ? 'Share interesting posts to attract followers!'
                                  : 'This user doesn\'t have any followers yet',
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
                        onRefresh: _loadFollowers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _followers.length,
                          itemBuilder: (context, index) {
                            final follower = _followers[index];
                            return _buildFollowerItem(follower, isOwnProfile);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerItem(AppUser follower, bool isOwnProfile) {
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
                  const Color(0xFF8CE830),
                  const Color(0xFF8CE830).withOpacity(0.8),
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
                      userId: follower.id,
                      customUserId: follower.customUserId,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    follower.nickname ?? 'No nickname',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${follower.customUserId}',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF8CE830),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (follower.preferredZipcode != null && follower.preferredZipcode!.isNotEmpty) ...[
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
                          follower.preferredZipcode!,
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
          
          // Block button (only show for own profile)
          if (isOwnProfile)
            OutlinedButton(
              onPressed: () => _showBlockDialog(follower),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(60, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}