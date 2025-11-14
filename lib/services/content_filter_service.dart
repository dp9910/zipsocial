import 'package:supabase_flutter/supabase_flutter.dart';

class ContentFilterService {
  static final _client = Supabase.instance.client;
  
  // Enhanced content filtering word lists - using word boundaries to prevent false positives
  static const List<String> _profanityWords = [
    // Strong profanity (exact matches only)
    ' shit ', ' fuck ', ' bitch ', ' bastard ',
    // Inappropriate sexual content
    ' nude ', ' naked ', ' porn ', ' xxx ', 'masturbat', ' orgasm ', 
    // Drug references  
    'cocaine', 'heroin', ' meth ', 'marijuana',
    // Severe harassment terms only
    ' stupid ', ' idiot ', ' moron ',
  ];
  
  // Threat and violence words - focus on serious threats only
  static const List<String> _threatWords = [
    ' kill ', ' murder ', ' bomb ', ' weapon ', ' gun ', ' knife ', 
    ' shoot ', ' stab ', ' terrorist ', ' attack '
  ];
  
  // Hate speech and discrimination
  static const List<String> _hateWords = [
    ' nazi ', ' racist ', ' bigot ', ' supremacist ', ' extremist '
  ];
  
  // Self-harm indicators - serious threats only
  static const List<String> _selfHarmWords = [
    'suicide', 'kill yourself', 'kys', 'self harm', 'cut myself', 'end it all',
    'want to die'
  ];
  
  // Spam indicators
  static const List<String> _spamWords = [
    'click here', 'free money', 'get rich', 'make money fast', 'earn cash',
    'follow me', 'check out', 'link in bio', 'dm me', 'subscribe'
  ];
  

  /// Enhanced content filtering with multiple severity levels
  static ContentFilterResult filterContent(String content, String contentType) {
    final lowerContent = ' ${content.toLowerCase()} '; // Add spaces for word boundary matching
    
    List<String> violations = [];
    int severityScore = 0;
    
    // Check self-harm content (highest priority)
    for (String word in _selfHarmWords) {
      if (lowerContent.contains(word)) {
        violations.add(word.trim());
        severityScore += 15; // Critical severity
      }
    }
    
    // Check hate speech and threats
    for (String word in _hateWords) {
      if (lowerContent.contains(word)) {
        violations.add(word.trim());
        severityScore += 12;
      }
    }
    
    for (String word in _threatWords) {
      if (lowerContent.contains(word)) {
        violations.add(word.trim());
        severityScore += 10;
      }
    }
    
    // Check profanity with higher severity for strong language
    for (String word in _profanityWords) {
      if (lowerContent.contains(word)) {
        violations.add(word.trim());
        // Strong profanity gets higher scores
        if ([' fuck ', ' shit ', ' bitch ', ' bastard '].contains(word)) {
          severityScore += 8; // Will trigger auto-hide at 8+
        } else {
          severityScore += 5; // Other profanity still gets significant penalty
        }
      }
    }
    
    // Check spam indicators
    for (String word in _spamWords) {
      if (lowerContent.contains(word)) {
        violations.add(word);
        severityScore += 2;
      }
    }
    
    // Check for suspicious URL patterns only (not legitimate links)
    if (RegExp(r'bit\.ly|tinyurl|suspicious-domain\.com').hasMatch(lowerContent)) {
      violations.add('suspicious_link');
      severityScore += 2;
    }
    
    // Check for excessive caps (potential shouting/spam) - more lenient
    final capsCount = content.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final totalLetters = content.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (totalLetters > 20 && (capsCount / totalLetters) > 0.8 && content.length > 30) {
      violations.add('excessive_caps');
      severityScore += 2;
    }
    
    // Check for repeated characters (spam pattern) - more lenient  
    if (RegExp(r'(.)\1{8,}').hasMatch(content)) {
      violations.add('repeated_chars');
      severityScore += 2;
    }
    
    // Determine action based on severity score - raised thresholds
    if (severityScore >= 15) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.high,
        action: FilterAction.rejected,
        filteredWords: violations,
        message: 'Content contains harmful language and cannot be posted. If you believe this is an error, please contact support.',
      );
    }
    
    if (severityScore >= 10) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.high,
        action: FilterAction.autoHidden,
        filteredWords: violations,
        message: 'Content has been automatically hidden due to inappropriate language. It will be reviewed by moderators.',
      );
    }
    
    if (severityScore >= 8) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.medium,
        action: FilterAction.flagged,
        filteredWords: violations,
        message: 'Content has been flagged for review due to potentially inappropriate language.',
      );
    }
    
    // Content is clean
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
      // Silently handle RLS policy violations and other database errors
      // Logging failures should not break the main content filtering functionality
      // Only print error if it's not an RLS violation to avoid spam
      if (!e.toString().contains('42501') && !e.toString().contains('row-level security policy')) {
        print('Failed to log content filter result: $e');
      }
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
      // If we can't check spam status due to RLS or other errors, default to false
      // This prevents blocking users when the monitoring system is unavailable
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