import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../services/notification_service.dart';

class SupabaseAuthService {
  static final _supabase = Supabase.instance.client;
  
  // Cache for user profile to reduce redundant API calls
  static AppUser? _cachedUserProfile;
  static String? _cachedUserId;

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

    try {
      await _supabase.from('users').insert({
        'id': user.id,
        'custom_user_id': customUserId,
        'email': user.email,
        'phone_number': user.phone,
      });
    } catch (e) {
      // Ignore if user already exists
      if (e is PostgrestException && e.code == '23505') { // Unique violation
        return;
      }
      rethrow;
    }
  }

  // Public method to recreate user profile if deleted
  static Future<void> createInitialUserProfile(User user) async {
    await _createInitialUser(user);
  }

  static Future<void> signInWithGoogle() async {
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';
      
      if (webClientId.isEmpty || iosClientId.isEmpty) {
        throw Exception('Google OAuth configuration missing in .env file');
      }
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      
      // FIRST CHECK: Block deleted emails before any authentication
      final email = googleUser!.email;
      final deletedEmailCheck = await _supabase
          .from('deleted_emails')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      
      if (deletedEmailCheck != null) {
        // Sign out from Google to clear their session
        await googleSignIn.signOut();
        throw Exception('This email is associated with a deleted account. Please use a new email to sign up.');
      }
      
      final googleAuth = await googleUser.authentication;
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

      if (response.user != null) {
        await _createInitialUser(response.user!);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signInWithApple() async {
    try {
      // Generate nonce for Apple Sign In
      final rawNonce = _supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      // FIRST CHECK: Block deleted emails before any authentication
      final email = credential.email;
      if (email != null) {
        final deletedEmailCheck = await _supabase
            .from('deleted_emails')
            .select('email')
            .eq('email', email)
            .maybeSingle();
        
        if (deletedEmailCheck != null) {
          throw Exception('This email is associated with a deleted account. Please use a new email to sign up.');
        }
      }

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw 'No ID Token received.';
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (response.user != null) {
        await _createInitialUser(response.user!);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signInWithEmail(String email, String password) async {
    try {
      // Check if this email has been deleted first
      final deletedEmailCheck = await _supabase
          .from('deleted_emails')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      
      if (deletedEmailCheck != null) {
        throw Exception('This email is associated with a deleted account. Please use a new email to sign up.');
      }
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Ensure user record exists for email sign-ins
      if (response.user != null) {
        await _createInitialUser(response.user!);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signUpWithEmail(String email, String password) async {
    try {
      // Check if this email has been deleted
      final deletedEmailCheck = await _supabase
          .from('deleted_emails')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      
      if (deletedEmailCheck != null) {
        throw Exception('This email is associated with a deleted account. Please use a new email to sign up.');
      }
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _createInitialUser(response.user!);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut(scope: SignOutScope.global);
    // Note: Terms are now shown for new users only, so no SharedPreferences cleanup needed
  }

  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  static Future<AppUser?> getUserProfile({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) {
      _clearProfileCache();
      return null;
    }

    // Return cached profile if available and not forcing refresh
    if (!forceRefresh && _cachedUserProfile != null && _cachedUserId == user.id) {
      return _cachedUserProfile;
    }

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // If no user record found, the account was deleted
      if (response == null) {
        _clearProfileCache();
        // Sign out the user since their account no longer exists
        await signOut();
        return null;
      }
      
      final appUser = AppUser.fromJson(response);
      
      // Check if user is marked as deleted (backup check)
      if (response['is_deleted'] == true) {
        _clearProfileCache();
        // Sign out deleted users automatically
        await signOut();
        return null;
      }
      
      // Cache the profile
      _cachedUserProfile = appUser;
      _cachedUserId = user.id;
      
      return appUser;
    } catch (e) {
      _clearProfileCache();
      // If there's an error fetching user profile, sign them out
      await signOut();
      return null;
    }
  }

  static void _clearProfileCache() {
    _cachedUserProfile = null;
    _cachedUserId = null;
  }

  static void clearProfileCache() {
    _clearProfileCache();
  }

  static Future<AppUser?> getUserProfileById(String userId) async {
    try {
      // Direct table query for now until SQL functions are deployed
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .eq('is_deleted', false)
          .maybeSingle();

      if (response == null) {
        return null;
      }
      
      return AppUser.fromJson(response);
    } catch (e) {
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
      
      final updatedUser = AppUser.fromJson(response);
      
      // Update cache with new profile
      _cachedUserProfile = updatedUser;
      _cachedUserId = user.id;
      
      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> followUser(String targetUserId) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    if (user.id == targetUserId) {
      throw Exception('Cannot follow yourself');
    }
    

    try {
      // Check if already following to prevent duplicates
      final existingFollow = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId)
          .maybeSingle();
      
      if (existingFollow != null) {
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

      // Update follower count for target user
      await _updateUserCount(targetUserId, 'follower_count', 1);

      // Update following count for current user
      await _updateUserCount(user.id, 'following_count', 1);

      // Send notification to the user being followed
      try {
        final notificationService = NotificationService(_supabase);
        await notificationService.notifyUserFollowed(targetUserId);
      } catch (e) {
        // Don't fail the follow action if notification fails
        print('Failed to send follow notification: $e');
      }
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  static Future<void> unfollowUser(String targetUserId) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // Delete follow relationship
      await _supabase
          .from('followers')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId);

      // Update follower count for target user
      await _updateUserCount(targetUserId, 'follower_count', -1);

      // Update following count for current user
      await _updateUserCount(user.id, 'following_count', -1);

      // Send notification to the user being unfollowed
      try {
        final notificationService = NotificationService(_supabase);
        await notificationService.notifyUserUnfollowed(targetUserId);
      } catch (e) {
        // Don't fail the unfollow action if notification fails
        print('Failed to send unfollow notification: $e');
      }
    } catch (e) {
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
      throw e;
    }
  }

  static Future<bool> isFollowing(String targetUserId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Check if two users follow each other bidirectionally (for chat access)
  static Future<bool> areUsersMutuallyFollowing(String userId1, String userId2) async {
    try {
      final follow1 = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', userId1)
          .eq('following_id', userId2)
          .maybeSingle();
          
      final follow2 = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', userId2)
          .eq('following_id', userId1)
          .maybeSingle();
          
      return follow1 != null && follow2 != null;
    } catch (e) {
      return false;
    }
  }

  // Get followers list with user details
  static Future<List<AppUser>> getFollowers({String? userId}) async {
    final user = currentUser;
    final targetUserId = userId ?? user?.id;
    if (targetUserId == null) return [];

    try {
      // Get follower IDs first
      final followersResponse = await _supabase
          .from('followers')
          .select('follower_id')
          .eq('following_id', targetUserId);
      
      
      if (followersResponse.isEmpty) {
        return [];
      }
      
      // Extract follower IDs
      final followerIds = followersResponse
          .map((item) => item['follower_id'] as String)
          .toList();
      
      
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
          .inFilter('id', followerIds)
          .eq('is_deleted', false);
      

      List<AppUser> users = [];
      for (var userData in usersResponse) {
        
        // Add safety checks for required fields
        if (userData['id'] == null || userData['custom_user_id'] == null) {
          continue;
        }
        
        try {
          users.add(AppUser.fromJson(userData));
        } catch (e) {
        }
      }
      
      return users;
    } catch (e) {
      return [];
    }
  }

  // Get following list with user details
  static Future<List<AppUser>> getFollowing({String? userId}) async {
    final user = currentUser;
    final targetUserId = userId ?? user?.id;
    if (targetUserId == null) return [];

    try {
      // Get following IDs first
      final followingResponse = await _supabase
          .from('followers')
          .select('following_id')
          .eq('follower_id', targetUserId);
      
      
      if (followingResponse.isEmpty) {
        return [];
      }
      
      // Extract following IDs
      final followingIds = followingResponse
          .map((item) => item['following_id'] as String)
          .toList();
      
      
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
          .inFilter('id', followingIds)
          .eq('is_deleted', false);
      

      List<AppUser> users = [];
      for (var userData in usersResponse) {
        
        // Add safety checks for required fields
        if (userData['id'] == null || userData['custom_user_id'] == null) {
          continue;
        }
        
        try {
          users.add(AppUser.fromJson(userData));
        } catch (e) {
        }
      }
      
      return users;
    } catch (e) {
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
      throw Exception('Failed to block user: $e');
    }
  }

  // Delete user account completely
  static Future<void> deleteUserAccount() async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    final email = user.email;
    if (email == null) throw Exception('No email found for user');

    try {
      // Call the SQL function to completely delete user and all associated data
      await _supabase.rpc('delete_user_completely_safe', params: {
        'user_email': email,
      });
      
      // User will be automatically signed out since their record is deleted
      
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}