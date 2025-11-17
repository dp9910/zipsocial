import 'package:filter_text/filter_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComprehensiveFilterService {
  static final _client = Supabase.instance.client;
  static late final FilterText _filter;
  
  // Initialize the filter (call this once in app startup)
  static void initialize() {
    _filter = FilterText();
  }

  /// Comprehensive content filtering using filter_text package
  static ContentFilterResult filterContent(String content, String contentType) {
    List<String> violations = [];
    List<String> detectedWords = [];
    int severityScore = 0;
    
    final originalContent = content;
    
    // Test different filter categories and track what was filtered
    
    // 1. Basic profanity check (high priority)
    final profanityCheck = _checkBasicProfanity(content);
    if (profanityCheck.isNotEmpty) {
      violations.add('profanity');
      severityScore += 8;
      detectedWords.addAll(profanityCheck);
    }
    
    // 2. Adult/Sexual content (high priority)
    final adultFiltered = _filter.filter(content, filterTypes: [FilterType.adult]);
    if (adultFiltered != content) {
      violations.add('adult_content');
      severityScore += 12;
      detectedWords.addAll(_getFilteredWords(content, adultFiltered));
    }
    
    // 2. Drugs (high priority)  
    final drugsFiltered = _filter.filter(content, filterTypes: [FilterType.drugs]);
    if (drugsFiltered != content) {
      violations.add('drugs');
      severityScore += 10;
      detectedWords.addAll(_getFilteredWords(content, drugsFiltered));
    }
    
    // 3. Violence (critical priority)
    final violenceFiltered = _filter.filter(content, filterTypes: [FilterType.violence]);
    if (violenceFiltered != content) {
      violations.add('violence');
      severityScore += 15;
      detectedWords.addAll(_getFilteredWords(content, violenceFiltered));
    }
    
    // 4. Spam (moderate priority)
    final spamFiltered = _filter.filter(content, filterTypes: [FilterType.spam]);
    if (spamFiltered != content) {
      violations.add('spam');
      severityScore += 5;
      detectedWords.addAll(_getFilteredWords(content, spamFiltered));
    }
    
    // 5. Politics (low priority - may be allowed in some contexts)
    final politicsFiltered = _filter.filter(content, filterTypes: [FilterType.politics]);
    if (politicsFiltered != content) {
      violations.add('politics');
      severityScore += 3;
      detectedWords.addAll(_getFilteredWords(content, politicsFiltered));
    }

    // 6. Additional custom checks for threats and harassment
    if (_containsThreats(content)) {
      violations.add('threats');
      severityScore += 20; // Highest priority
    }

    if (_containsHarassment(content)) {
      violations.add('harassment');
      severityScore += 15;
    }

    // 7. Formatting issues
    if (_isExcessiveCaps(content)) {
      violations.add('excessive_caps');
      severityScore += 2;
    }

    if (_hasRepeatedChars(content)) {
      violations.add('repeated_chars');
      severityScore += 2;
    }

    // Remove duplicates from detected words
    detectedWords = detectedWords.toSet().toList();

    // Determine action based on severity score and violation types
    if (violations.contains('threats') || violations.contains('drugs') || violations.contains('adult_content') || violations.contains('profanity') || severityScore >= 8) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.critical,
        action: FilterAction.rejected,
        violationTypes: violations,
        detectedWords: detectedWords,
        severityScore: severityScore,
        message: 'Content contains inappropriate language and cannot be posted. If you believe this is an error, please contact support.',
        originalContent: originalContent,
        cleanedContent: _getFullyCleanedContent(content),
      );
    }

    if (violations.contains('violence') || violations.contains('harassment') || severityScore >= 12) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.high,
        action: FilterAction.autoHidden,
        violationTypes: violations,
        detectedWords: detectedWords,
        severityScore: severityScore,
        message: 'Content has been automatically hidden due to inappropriate content. It will be reviewed by moderators.',
        originalContent: originalContent,
        cleanedContent: _getFullyCleanedContent(content),
      );
    }

    if (violations.contains('adult_content') || violations.contains('drugs') || severityScore >= 8) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.medium,
        action: FilterAction.flagged,
        violationTypes: violations,
        detectedWords: detectedWords,
        severityScore: severityScore,
        message: 'Content has been flagged for review due to potentially inappropriate content.',
        originalContent: originalContent,
        cleanedContent: _getFullyCleanedContent(content),
      );
    }

    if (severityScore >= 3) {
      return ContentFilterResult(
        isClean: false,
        severity: FilterSeverity.low,
        action: FilterAction.warned,
        violationTypes: violations,
        detectedWords: detectedWords,
        severityScore: severityScore,
        message: 'Content contains some inappropriate elements but will be posted.',
        originalContent: originalContent,
        cleanedContent: _getFullyCleanedContent(content),
      );
    }

    // Content is clean
    return ContentFilterResult(
      isClean: true,
      severity: FilterSeverity.none,
      action: FilterAction.allowed,
      violationTypes: [],
      detectedWords: [],
      severityScore: 0,
      message: null,
      originalContent: originalContent,
      cleanedContent: content,
    );
  }

  /// Get fully cleaned content with all filters applied
  static String _getFullyCleanedContent(String content) {
    return _filter.filter(
      content,
      filterTypes: [
        FilterType.adult,
        FilterType.drugs,
        FilterType.violence,
        FilterType.spam,
        FilterType.politics,
      ],
    );
  }

  /// Extract words that were filtered out by comparing original and filtered text
  static List<String> _getFilteredWords(String original, String filtered) {
    final originalWords = original.toLowerCase().split(RegExp(r'\s+'));
    final filteredWords = filtered.toLowerCase().split(RegExp(r'\s+'));
    
    final detected = <String>[];
    for (final word in originalWords) {
      if (!filteredWords.contains(word) && word.trim().isNotEmpty) {
        detected.add(word.trim());
      }
    }
    return detected;
  }

  // Additional threat detection patterns
  static bool _containsThreats(String content) {
    final threatPatterns = [
      RegExp(r'\b(kill|murder)\s+(you|yourself|him|her|them)\b', caseSensitive: false),
      RegExp(r'\b(suicide|self\s*harm|cut\s+myself)\b', caseSensitive: false),
      RegExp(r'\b(bomb|terrorist|attack|shoot\s+up)\b', caseSensitive: false),
      RegExp(r'\b(rape|molest|assault)\b', caseSensitive: false),
    ];
    
    return threatPatterns.any((pattern) => pattern.hasMatch(content));
  }

  // Additional harassment detection patterns  
  static bool _containsHarassment(String content) {
    final harassmentPatterns = [
      RegExp(r'\b(kill\s+yourself|kys)\b', caseSensitive: false),
      RegExp(r'\b(hang\s+yourself|go\s+die)\b', caseSensitive: false),
      RegExp(r'\b(worthless|pathetic)\s+(piece\s+of\s+shit|loser)\b', caseSensitive: false),
    ];
    
    return harassmentPatterns.any((pattern) => pattern.hasMatch(content));
  }

  // Helper methods for formatting checks
  static bool _isExcessiveCaps(String content) {
    if (content.length < 20) return false;
    final capsCount = content.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final totalLetters = content.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    return totalLetters > 0 && (capsCount / totalLetters) > 0.7;
  }

  static bool _hasRepeatedChars(String content) {
    return RegExp(r'(.)\1{8,}').hasMatch(content);
  }

  /// Check for basic profanity words
  static List<String> _checkBasicProfanity(String content) {
    final profanityWords = [
      'fuck', 'shit', 'bitch', 'asshole', 'damn', 'crap', 'piss',
      'fucking', 'bullshit', 'bastard', 'dickhead', 'motherfucker',
      'cocksucker', 'dumbass', 'jackass', 'shitty', 'fucked',
      'fuckin', 'shite', 'arse', 'prick', 'twat', 'cunt'
    ];
    
    final detectedWords = <String>[];
    final lowerContent = content.toLowerCase();
    
    for (final word in profanityWords) {
      // Use word boundaries to avoid false positives like 'hello' containing 'hell'
      final regex = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      if (regex.hasMatch(content)) {
        detectedWords.add(word);
      }
    }
    
    return detectedWords;
  }

  /// Log comprehensive filter result to database
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
        'violation_types': result.violationTypes,
        'detected_words': result.detectedWords,
        'severity': result.severity.name,
        'action_taken': result.action.name,
        'severity_score': result.severityScore,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Silently handle database errors
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
          .inFilter('action_taken', ['flagged', 'autoHidden', 'rejected']);
      
      return response.length >= 5; // 5 violations in 1 hour = potential spam
    } catch (e) {
      return false;
    }
  }
}

enum FilterSeverity { none, low, medium, high, critical }
enum FilterAction { allowed, warned, flagged, autoHidden, rejected }

class ContentFilterResult {
  final bool isClean;
  final FilterSeverity severity;
  final FilterAction action;
  final List<String> violationTypes;
  final List<String> detectedWords;
  final int severityScore;
  final String? message;
  final String originalContent;
  final String cleanedContent;
  
  ContentFilterResult({
    required this.isClean,
    required this.severity,
    required this.action,
    required this.violationTypes,
    required this.detectedWords,
    required this.severityScore,
    this.message,
    required this.originalContent,
    required this.cleanedContent,
  });

  // For backwards compatibility with existing code
  List<String> get filteredWords => detectedWords;
}