import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/terms_of_service_screen.dart';
import 'services/supabase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
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
    return FutureBuilder<bool>(
      future: _checkTermsAcceptance(),
      builder: (context, termsSnapshot) {
        if (termsSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final termsAccepted = termsSnapshot.data ?? false;
        if (!termsAccepted) {
          return const TermsOfServiceScreen();
        }
        
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
                  if (user == null || !user.isProfileComplete) {
                    return const ProfileSetupScreen();
                  }
                  
                  return const MainScreen();
                },
              );
            } else {
              return const AuthScreen();
            }
          },
        );
      },
    );
  }
  
  Future<bool> _checkTermsAcceptance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('terms_accepted') ?? false;
    } catch (e) {
      return false;
    }
  }
}