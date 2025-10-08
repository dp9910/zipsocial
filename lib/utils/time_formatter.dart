class TimeFormatter {
  /// Formats a DateTime to show relative time from now
  /// - 0-59 seconds: "just now" or "X seconds ago"
  /// - 1-59 minutes: "X minutes ago" 
  /// - 1-23 hours: "X hours ago"
  /// - 24+ hours: "MMM dd" or "MMM dd, yyyy" if different year
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // If the time is in the future (shouldn't happen but handle gracefully)
    if (difference.isNegative) {
      return 'just now';
    }

    // Seconds (0-59 seconds)
    if (difference.inSeconds < 60) {
      if (difference.inSeconds <= 5) {
        return 'just now';
      }
      return '${difference.inSeconds} seconds ago';
    }

    // Minutes (1-59 minutes)
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    }

    // Hours (1-23 hours)
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }

    // Days - show actual date
    return _formatDate(dateTime, now);
  }

  /// Formats the date portion for timestamps older than 24 hours
  static String _formatDate(DateTime dateTime, DateTime now) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final month = months[dateTime.month - 1];
    final day = dateTime.day;

    // If same year, show "MMM dd"
    if (dateTime.year == now.year) {
      return '$month $day';
    }

    // If different year, show "MMM dd, yyyy"
    return '$month $day, ${dateTime.year}';
  }

  /// Format time for display in comments (shorter format)
  static String formatCommentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return 'now';
    }

    if (difference.inSeconds < 60) {
      if (difference.inSeconds <= 5) {
        return 'now';
      }
      return '${difference.inSeconds}s';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    // For comments, use short date format
    return _formatDate(dateTime, now);
  }
}