import 'package:supabase_flutter/supabase_flutter.dart';

class ContentFilterService {
  static final _client = Supabase.instance.client;
  
  // Basic profanity and inappropriate content words
  static const List<String> _profanityWords = [
    // Mild profanity
    'damn', 'hell', 'crap', 'piss', 'ass', 'shit', 'fuck', 'bitch',
    // Hate speech indicators
    'nazi', 'terrorist', 'kill yourself', 'kys', 'die',
    // Inappropriate sexual content
    'nude', 'naked', 'sex', 'porn', 'xxx', 'masturbat', 'orgasm',
    // Drug references
    'cocaine', 'heroin', 'meth', 'weed', 'marijuana', 'drugs',
    // Spam indicators
    'click here', 'free money', 'get rich', 'make money fast',
    // Harassment
    'stupid', 'idiot', 'retard', 'moron', 'loser', 'ugly', 'fat',
  ];
  
  // Severe words that should auto-reject content
  static const List<String> _severeWords = [
    'suicide', 'kill yourself', 'kys', 'die', 'murder', 'bomb', 'terrorist',
    'nazi', 'rape', 'molest', 'abuse', 'violence', 'threat', 'attack'
  ];
  
  // Spam patterns
  static const List<String> _spamPatterns = [
    'http://', 'https://', 'www.', '.com', '.net', '.org',
    'follow me', 'check out', 'click here', 'link in bio'
  ];

  /// Filter content and return result with severity and action
  static ContentFilterResult filterContent(String content, String contentType) {
    final lowerContent = content.toLowerCase();
    final words = lowerContent.split(RegExp(r'\s+'));
    
    List<String> foundProfanity = [];
    List<String> foundSevere = [];
    List<String> foundSpam = [];
    
    // Check for severe words first
    for (String word in _severeWords) {
      if (lowerContent.contains(word)) {
        foundSevere.add(word);
      }
    }
    
    // Check for profanity
    for (String word in _profanityWords) {
      if (lowerContent.contains(word)) {
        foundProfanity.add(word);
      }
    }
    
    // Check for spam patterns
    for (String pattern in _spamPatterns) {
      if (lowerContent.contains(pattern)) {
        foundSpam.add(pattern);
      }
    }
    
    // Determine severity and action
    if (foundSevere.isNotEmpty) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.high,
        action: FilterAction.rejected,
        filteredWords: foundSevere,
        message: 'Content contains inappropriate language and cannot be posted.',
      );
    }
    
    if (foundProfanity.length >= 3 || foundSpam.length >= 2) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.high,
        action: FilterAction.autoHidden,
        filteredWords: [...foundProfanity, ...foundSpam],
        message: 'Content has been flagged for review due to multiple inappropriate words.',
      );
    }
    
    if (foundProfanity.isNotEmpty || foundSpam.isNotEmpty) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.medium,
        action: FilterAction.flagged,
        filteredWords: [...foundProfanity, ...foundSpam],
        message: 'Content has been flagged for containing potentially inappropriate language.',
      );
    }
    
    // Check for excessive caps (potential shouting/spam)
    final capsCount = content.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final totalLetters = content.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (totalLetters > 0 && (capsCount / totalLetters) > 0.6 && content.length > 20) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.low,
        action: FilterAction.flagged,
        filteredWords: ['excessive_caps'],
        message: 'Content flagged for excessive capital letters.',
      );
    }
    
    return ContentFilterResult(
      isClean: true,
      severity: FilterSeverity.low,
      action: FilterAction.allowed,
      filteredWords: [],
      message: null,
    );
  }
  
  /// Log content filter result to database
  static Future<void> logFilterResult({
    required String contentType,
    required String contentId,
    required String userId,
    required ContentFilterResult result,
  }) async {
    try {
      await _client.from('content_filter_logs').insert({
        'content_type': contentType,
        'content_id': contentId,
        'user_id': userId,
        'filtered_words': result.filteredWords,
        'severity': result.severity.name,
        'action_taken': result.action.name,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Don't throw error if logging fails, just continue
      print('Failed to log content filter result: $e');
    }
  }
  
  /// Check if user has been flagged too many times recently
  static Future<bool> isUserSpamming(String userId) async {
    try {
      final response = await _client
          .from('content_filter_logs')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(hours: 1)).toUtc().toIso8601String())
          .eq('action_taken', 'flagged');
      
      return response.length >= 5; // 5 flags in 1 hour = spam
    } catch (e) {
      return false;
    }
  }
}

enum FilterSeverity { low, medium, high }

enum FilterAction { allowed, flagged, autoHidden, rejected }

class ContentFilterResult {
  final bool isClean;
  final FilterSeverity severity;
  final FilterAction action;
  final List<String> filteredWords;
  final String? message;
  
  ContentFilterResult({
    required this.isClean,
    required this.severity,
    required this.action,
    required this.filteredWords,
    this.message,
  });
}