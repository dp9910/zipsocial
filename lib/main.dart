import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/terms_of_service_screen.dart';
import 'screens/new_user_terms_screen.dart';
import 'services/supabase_auth_service.dart';
import 'services/comprehensive_filter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  ComprehensiveFilterService.initialize();
  runApp(const ZipSocialApp());
}

class ZipSocialApp extends StatelessWidget {
  const ZipSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zip Social',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/auth': (context) => const AuthScreen(),
        '/terms': (context) => const TermsOfServiceScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) {
          return FutureBuilder(
            future: SupabaseAuthService.getUserProfile(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              final user = userSnapshot.data;
              if (user == null) {
                // This shouldn't happen, but if it does, show terms
                return const NewUserTermsScreen();
              } else if (!user.isProfileComplete) {
                // Check if this is a new user (no nickname yet) or returning user
                if (user.nickname == null || user.nickname!.isEmpty) {
                  // New user - show terms first
                  return const NewUserTermsScreen();
                } else {
                  // Existing user with incomplete profile
                  return const ProfileSetupScreen();
                }
              }
              
              return const MainScreen();
            },
          );
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}