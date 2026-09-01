/// Content item for the Read-Memorize-Speak game.
///
/// Content is bundled with the app as JSON assets under assets/content/.
/// In the final round, this is extended to support downloadable language packs
/// (patient's default language always available, others download-on-demand).
library;

enum ContentCategory { dailyConversation, stories, wisdom }

extension ContentCategoryX on ContentCategory {
  String get value {
    switch (this) {
      case ContentCategory.dailyConversation: return 'daily_conversation';
      case ContentCategory.stories: return 'stories';
      case ContentCategory.wisdom: return 'wisdom';
    }
  }

  String get displayName {
    switch (this) {
      case ContentCategory.dailyConversation: return 'Daily Conversation';
      case ContentCategory.stories: return 'Stories';
      case ContentCategory.wisdom: return 'Wisdom';
    }
  }

  static ContentCategory fromString(String s) {
    switch (s) {
      case 'stories': return ContentCategory.stories;
      case 'wisdom': return ContentCategory.wisdom;
      // backward-compat for old data
      case 'sacred_verses': return ContentCategory.wisdom;
      case 'bhagavad_gita': return ContentCategory.wisdom;
      default: return ContentCategory.dailyConversation;
    }
  }
}

enum ContentLength { short, medium, long }

extension ContentLengthX on ContentLength {
  String get value {
    switch (this) {
      case ContentLength.short: return 'short';
      case ContentLength.medium: return 'medium';
      case ContentLength.long: return 'long';
    }
  }

  String get displayName {
    switch (this) {
      case ContentLength.short: return 'Short (1–2 sentences)';
      case ContentLength.medium: return 'Medium (3–4 sentences)';
      case ContentLength.long: return 'Long (5–6 sentences)';
    }
  }

  static ContentLength fromString(String s) {
    switch (s) {
      case 'medium': return ContentLength.medium;
      case 'long': return ContentLength.long;
      default: return ContentLength.short;
    }
  }
}

class ContentItem {
  final String id;
  final ContentCategory category;
  final String language;       // 'en' or 'hi'
  final ContentLength length;
  final int difficultyTier;    // 1-3 (for difficulty adaptation)
  final String title;          // shown in history: "The Thirsty Crow"
  final String text;           // the actual passage

  const ContentItem({
    required this.id,
    required this.category,
    required this.language,
    required this.length,
    required this.difficultyTier,
    required this.title,
    required this.text,
  });

  factory ContentItem.fromJson(Map<String, dynamic> j) => ContentItem(
        id: j['id'] as String,
        category: ContentCategoryX.fromString(j['category'] as String),
        language: j['language'] as String,
        length: ContentLengthX.fromString(j['length'] as String),
        difficultyTier: j['difficulty_tier'] as int,
        title: j['title'] as String,
        text: j['text'] as String,
      );
}
