import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config/firebase_config.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/firebase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  await SupabaseConfig.initialize();
  runApp(const ZipSocialApp());
}

class ZipSocialApp extends StatelessWidget {
  const ZipSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zip Social',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder(
            future: FirebaseAuthService.getUserProfile(),
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
  }
}
