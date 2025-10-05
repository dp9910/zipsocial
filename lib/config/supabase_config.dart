import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://xtvtewfmzvmpzahlmbsj.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0dnRld2ZtenZtcHphaGxtYnNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2MTQ1NjMsImV4cCI6MjA3NTE5MDU2M30.k1WvFeTpM1wOzvN6f2_i3rxb7dEyQXvu2FLeQZrtGhQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}