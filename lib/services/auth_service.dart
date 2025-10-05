import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user.dart';

class AuthService {
  static final _client = SupabaseConfig.client;

  static User? get currentUser => _client.auth.currentUser;
  static bool get isSignedIn => currentUser != null;

  static String _generateUserId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  static Future<void> signInWithPhone(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  static Future<AuthResponse> verifyOTP(String phone, String token) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  static Future<AppUser?> createUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final customUserId = _generateUserId();
    
    final response = await _client
        .from('users')
        .insert({
          'id': user.id,
          'custom_user_id': customUserId,
          'phone_number': user.phone,
          'google_email': user.email,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return AppUser.fromJson(response);
  }

  static Future<AppUser?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return AppUser.fromJson(response);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}