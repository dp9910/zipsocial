import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/firebase_config.dart';
import '../config/supabase_config.dart';
import '../models/user.dart';

class FirebaseAuthService {
  static final _auth = FirebaseConfig.auth;
  static final _supabase = SupabaseConfig.client;
  static final _googleSignIn = GoogleSignIn(
    clientId: '919813529279-7aoun3mf2rfk85ajk7abr41bnqiq7vb0.apps.googleusercontent.com',
  );

  static User? get currentUser => _auth.currentUser;
  static bool get isSignedIn => currentUser != null;

  static String _generateUserId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  static Future<void> signInWithPhone(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          try {
            await _auth.signInWithCredential(credential);
          } catch (e) {
            print('Auto-verification failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.code} - ${e.message}');
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Code sent to $phoneNumber with verification ID: $verificationId');
          // Store verificationId for later use
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Code auto-retrieval timeout for verification ID: $verificationId');
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      print('Error in signInWithPhone: $e');
      throw Exception('Failed to send verification code: $e');
    }
  }

  static String? _verificationId;

  static Future<UserCredential> verifyOTP(String smsCode) async {
    try {
      if (_verificationId == null || _verificationId!.isEmpty) {
        throw Exception('No verification ID available. Please request a new code.');
      }

      print('Verifying OTP with verification ID: $_verificationId');

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      print('User signed in successfully: ${userCredential.user?.uid}');
      
      // Create user profile in Supabase if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        print('Creating new user profile in Supabase');
        await _createUserProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Error in verifyOTP: $e');
      throw Exception('Failed to verify code: $e');
    }
  }

  static Future<AppUser?> _createUserProfile(User firebaseUser) async {
    final customUserId = _generateUserId();
    
    try {
      final response = await _supabase
          .from('users')
          .insert({
            'id': firebaseUser.uid,
            'custom_user_id': customUserId,
            'phone_number': firebaseUser.phoneNumber,
            'google_email': firebaseUser.email,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error creating user profile: $e');
      return null;
    }
  }

  static Future<AppUser?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.uid)
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  static Future<UserCredential> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }
      
      print('Google user signed in: ${googleUser.email}');
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      print('Firebase user signed in: ${userCredential.user?.uid}');
      
      // Create user profile in Supabase if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        print('Creating new user profile in Supabase');
        await _createUserProfile(userCredential.user!);
      }
      
      return userCredential;
    } catch (e) {
      print('Error in signInWithGoogle: $e');
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  static Future<AppUser?> createUserProfile({
    required String nickname,
    String? bio,
    String? defaultZipcode,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user');

    final customUserId = _generateUserId();
    
    try {
      final response = await _supabase
          .from('users')
          .insert({
            'id': user.uid,
            'custom_user_id': customUserId,
            'phone_number': user.phoneNumber,
            'google_email': user.email,
            'nickname': nickname,
            'bio': bio,
            'default_zipcode': defaultZipcode,
            'follower_count': 0,
            'following_count': 0,
            'is_profile_complete': true,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error creating user profile: $e');
      throw Exception('Failed to create profile: $e');
    }
  }

  static Future<AppUser?> updateUserProfile({
    String? nickname,
    String? bio,
    String? defaultZipcode,
    bool? isProfileComplete,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final updateData = <String, dynamic>{};
      
      if (nickname != null) updateData['nickname'] = nickname;
      if (bio != null) updateData['bio'] = bio;
      if (defaultZipcode != null) updateData['default_zipcode'] = defaultZipcode;
      if (isProfileComplete != null) updateData['is_profile_complete'] = isProfileComplete;
      
      final response = await _supabase
          .from('users')
          .update(updateData)
          .eq('id', user.uid)
          .select()
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  static Future<AppUser?> getUserProfileById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error getting user profile by ID: $e');
      return null;
    }
  }

  static Future<AppUser?> getUserProfileByCustomId(String customUserId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('custom_user_id', customUserId)
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error getting user profile by custom ID: $e');
      return null;
    }
  }

  static Future<void> followUser(String targetUserId) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // Insert follow relationship
      await _supabase
          .from('followers')
          .insert({
            'follower_id': user.uid,
            'following_id': targetUserId,
            'created_at': DateTime.now().toIso8601String(),
          });

      // Update follower count for target user
      await _supabase.rpc('increment_follower_count', params: {
        'user_id': targetUserId,
      });

      // Update following count for current user
      await _supabase.rpc('increment_following_count', params: {
        'user_id': user.uid,
      });
    } catch (e) {
      print('Error following user: $e');
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
          .eq('follower_id', user.uid)
          .eq('following_id', targetUserId);

      // Update follower count for target user
      await _supabase.rpc('decrement_follower_count', params: {
        'user_id': targetUserId,
      });

      // Update following count for current user
      await _supabase.rpc('decrement_following_count', params: {
        'user_id': user.uid,
      });
    } catch (e) {
      print('Error unfollowing user: $e');
      throw Exception('Failed to unfollow user: $e');
    }
  }

  static Future<bool> isFollowing(String targetUserId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', user.uid)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}