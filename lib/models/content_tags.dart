enum ContentTag {
  political,
  religion,
  sensitive,
  vulgar,
  nsfw,
}

class ContentTags {
  static const Map<ContentTag, String> _tagLabels = {
    ContentTag.political: 'Political',
    ContentTag.religion: 'Religious',
    ContentTag.sensitive: 'Sensitive',
    ContentTag.vulgar: 'Vulgar',
    ContentTag.nsfw: 'NSFW',
  };

  static const Map<ContentTag, String> _tagDescriptions = {
    ContentTag.political: 'Political discussions and content',
    ContentTag.religion: 'Religious topics and discussions',
    ContentTag.sensitive: 'Sensitive or controversial content',
    ContentTag.vulgar: 'Strong language or crude content',
    ContentTag.nsfw: 'Not Safe for Work content',
  };

  static String getLabel(ContentTag tag) => _tagLabels[tag] ?? '';
  static String getDescription(ContentTag tag) => _tagDescriptions[tag] ?? '';

  static ContentTag? fromString(String tagString) {
    switch (tagString.toLowerCase()) {
      case 'political':
        return ContentTag.political;
      case 'religion':
        return ContentTag.religion;
      case 'sensitive':
        return ContentTag.sensitive;
      case 'vulgar':
        return ContentTag.vulgar;
      case 'nsfw':
        return ContentTag.nsfw;
      default:
        return null;
    }
  }

  static String toString(ContentTag tag) {
    switch (tag) {
      case ContentTag.political:
        return 'political';
      case ContentTag.religion:
        return 'religion';
      case ContentTag.sensitive:
        return 'sensitive';
      case ContentTag.vulgar:
        return 'vulgar';
      case ContentTag.nsfw:
        return 'nsfw';
    }
  }

  static List<ContentTag> fromStringList(List<String> tagStrings) {
    return tagStrings
        .map((tagString) => fromString(tagString))
        .where((tag) => tag != null)
        .cast<ContentTag>()
        .toList();
  }

  static List<String> toStringList(List<ContentTag> tags) {
    return tags.map((tag) => toString(tag)).toList();
  }

  static List<ContentTag> getAllTags() => ContentTag.values;
}