import 'dart:math';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class SupabaseAuthService {
  static final _supabase = Supabase.instance.client;

  static User? get currentUser => _supabase.auth.currentUser;
  static bool get isSignedIn => currentUser != null;

  static String _generateUserId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  static Future<void> _createInitialUser(User user) async {
    final customUserId = _generateUserId();
    print('Attempting to create initial user in public.users table...');
    print('User ID: ${user.id}');
    print('Custom User ID: $customUserId');
    print('User Email: ${user.email}');
    print('User Phone: ${user.phone}');

    try {
      await _supabase.from('users').insert({
        'id': user.id,
        'custom_user_id': customUserId,
        'email': user.email,
        'phone_number': user.phone,
      });
      print('Initial user created successfully!');
    } catch (e) {
      print('Error creating initial user: $e');
      // Ignore if user already exists
      if (e is PostgrestException && e.code == '23505') { // Unique violation
        print('User already exists in public.users, ignoring.');
        return;
      }
      rethrow;
    }
  }

  static Future<void> signInWithGoogle() async {
    print('signInWithGoogle called.');
    try {
      const webClientId = '867310496279-cshu2jj10llk18ek68fh1bhdvec6kbov.apps.googleusercontent.com';
      const iosClientId = '867310496279-s4n7jhbrm5c3r74314nug67hdm04ch9n.apps.googleusercontent.com';
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      print('Supabase signInWithIdToken response:');
      print('  Session: ${response.session}');
      print('  User: ${response.user}');

      if (response.user != null) {
        print('Supabase signInWithIdToken successful. User ID: ${response.user!.id}');
        await _createInitialUser(response.user!);
      } else {
        print('Supabase signInWithIdToken failed: response.user is null.');
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  static Future<void> signInWithEmail(String email, String password) async {
    print('signInWithEmail called.');
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  static Future<void> signUpWithEmail(String email, String password) async {
    print('signUpWithEmail called.');
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        print('Supabase signUp successful. User ID: ${response.user!.id}');
        await _createInitialUser(response.user!);
      }
    } catch (e) {
      print('Error signing up with email: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  static Future<AppUser?> getUserProfile() async {
    final user = currentUser;
    if (user == null) {
      print('getUserProfile: No current Supabase user.');
      return null;
    }
    print('getUserProfile: Attempting to fetch profile for user ID: ${user.id}');

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        print('getUserProfile: No profile found for user ID: ${user.id}');
        return null;
      }
      print('getUserProfile: Profile fetched successfully: $response');
      return AppUser.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  static Future<AppUser?> getUserProfileById(String userId) async {
    print('getUserProfileById: Attempting to fetch profile for user ID: $userId');
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        print('getUserProfileById: No profile found for user ID: $userId');
        return null;
      }
      print('getUserProfileById: Profile fetched successfully: $response');
      return AppUser.fromJson(response);
    } catch (e) {
      print('Error getting user profile by ID: $e');
      return null;
    }
  }

  static Future<AppUser> updateUserProfile({
    required String nickname,
    String? bio,
    bool? isProfileComplete,
    String? preferredZipcode,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    print('updateUserProfile: Updating profile for user ID: ${user.id}');

    final updates = {
      'nickname': nickname,
      'bio': bio,
      'is_profile_complete': isProfileComplete,
      'preferred_zipcode': preferredZipcode,
    };

    updates.removeWhere((key, value) => value == null);

    try {
      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', user.id)
          .select()
          .single();
      print('updateUserProfile: Profile updated successfully: $response');
      return AppUser.fromJson(response);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  static Future<void> followUser(String targetUserId) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    if (user.id == targetUserId) {
      throw Exception('Cannot follow yourself');
    }
    
    print('followUser: User ${user.id} attempting to follow $targetUserId');

    try {
      // Check if already following to prevent duplicates
      final existingFollow = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId)
          .maybeSingle();
      
      if (existingFollow != null) {
        print('followUser: Already following this user');
        return; // Already following
      }

      // Insert follow relationship
      await _supabase
          .from('followers')
          .insert({
            'follower_id': user.id,
            'following_id': targetUserId,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
      print('followUser: Follow relationship inserted.');

      // Update follower count for target user
      await _updateUserCount(targetUserId, 'follower_count', 1);
      print('followUser: Target user follower count incremented.');

      // Update following count for current user
      await _updateUserCount(user.id, 'following_count', 1);
      print('followUser: Current user following count incremented.');
    } catch (e) {
      print('Error following user: $e');
      throw Exception('Failed to follow user: $e');
    }
  }

  static Future<void> unfollowUser(String targetUserId) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    print('unfollowUser: User ${user.id} attempting to unfollow $targetUserId');

    try {
      // Delete follow relationship
      await _supabase
          .from('followers')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId);
      print('unfollowUser: Follow relationship deleted.');

      // Update follower count for target user
      await _updateUserCount(targetUserId, 'follower_count', -1);
      print('unfollowUser: Target user follower count decremented.');

      // Update following count for current user
      await _updateUserCount(user.id, 'following_count', -1);
      print('unfollowUser: Current user following count decremented.');
    } catch (e) {
      print('Error unfollowing user: $e');
      throw Exception('Failed to unfollow user: $e');
    }
  }

  // Helper method to safely update user counts
  static Future<void> _updateUserCount(String userId, String countField, int change) async {
    try {
      // Get current count
      final response = await _supabase
          .from('users')
          .select(countField)
          .eq('id', userId)
          .single();
      
      final currentCount = response[countField] ?? 0;
      final newCount = (currentCount + change).clamp(0, double.infinity).toInt();
      
      // Update count
      await _supabase
          .from('users')
          .update({countField: newCount})
          .eq('id', userId);
    } catch (e) {
      print('Error updating $countField for user $userId: $e');
      throw e;
    }
  }

  static Future<bool> isFollowing(String targetUserId) async {
    final user = currentUser;
    if (user == null) return false;
    print('isFollowing: Checking follow status for user ${user.id} and target $targetUserId');

    try {
      final response = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId)
          .maybeSingle();
      print('isFollowing: Follow status response: $response');
      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Get followers list with user details
  static Future<List<AppUser>> getFollowers({String? userId}) async {
    final user = currentUser;
    final targetUserId = userId ?? user?.id;
    if (targetUserId == null) return [];

    try {
      print('Fetching followers for user: $targetUserId');
      
      // Get follower IDs first
      final followersResponse = await _supabase
          .from('followers')
          .select('follower_id')
          .eq('following_id', targetUserId);
      
      print('Followers IDs response: $followersResponse');
      
      if (followersResponse.isEmpty) {
        print('No followers found');
        return [];
      }
      
      // Extract follower IDs
      final followerIds = followersResponse
          .map((item) => item['follower_id'] as String)
          .toList();
      
      print('Follower IDs: $followerIds');
      
      // Get user details for these follower IDs
      final usersResponse = await _supabase
          .from('users')
          .select('''
            id,
            custom_user_id,
            nickname,
            bio,
            preferred_zipcode,
            post_count,
            follower_count,
            following_count,
            created_at,
            is_profile_complete
          ''')
          .inFilter('id', followerIds);
      
      print('Users response: $usersResponse');

      List<AppUser> users = [];
      for (var userData in usersResponse) {
        print('Processing user data: $userData');
        
        // Add safety checks for required fields
        if (userData['id'] == null || userData['custom_user_id'] == null) {
          print('Warning: missing required fields in user data: $userData');
          continue;
        }
        
        try {
          users.add(AppUser.fromJson(userData));
        } catch (e) {
          print('Error parsing user data: $e for data: $userData');
        }
      }
      
      return users;
    } catch (e) {
      print('Error fetching followers: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get following list with user details
  static Future<List<AppUser>> getFollowing({String? userId}) async {
    final user = currentUser;
    final targetUserId = userId ?? user?.id;
    if (targetUserId == null) return [];

    try {
      print('Fetching following for user: $targetUserId');
      
      // Get following IDs first
      final followingResponse = await _supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', targetUserId);
      
      print('Following IDs response: $followingResponse');
      
      if (followingResponse.isEmpty) {
        print('No following found');
        return [];
      }
      
      // Extract following IDs
      final followingIds = followingResponse
          .map((item) => item['following_id'] as String)
          .toList();
      
      print('Following IDs: $followingIds');
      
      // Get user details for these following IDs
      final usersResponse = await _supabase
          .from('users')
          .select('''
            id,
            custom_user_id,
            nickname,
            bio,
            preferred_zipcode,
            post_count,
            follower_count,
            following_count,
            created_at,
            is_profile_complete
          ''')
          .inFilter('id', followingIds);
      
      print('Users response: $usersResponse');

      List<AppUser> users = [];
      for (var userData in usersResponse) {
        print('Processing user data: $userData');
        
        // Add safety checks for required fields
        if (userData['id'] == null || userData['custom_user_id'] == null) {
          print('Warning: missing required fields in user data: $userData');
          continue;
        }
        
        try {
          users.add(AppUser.fromJson(userData));
        } catch (e) {
          print('Error parsing user data: $e for data: $userData');
        }
      }
      
      return users;
    } catch (e) {
      print('Error fetching following: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Block a user (remove them as follower)
  static Future<void> blockUser(String userIdToBlock) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _supabase.rpc('unfollow_and_decrement_counts', params: {
        'p_follower_id': userIdToBlock,
        'p_following_id': user.id,
      });
    } catch (e) {
      print('Error blocking user: $e');
      throw Exception('Failed to block user: $e');
    }
  }
}