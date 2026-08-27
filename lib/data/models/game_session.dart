import 'content_item.dart';

/// A completed game session — saved to SQLite and shown in Progress tab.
class GameSession {
  final String id;
  final String gameType;          // 'read_memorize_speak'
  final DateTime playedAt;
  final ContentCategory category;
  final String language;
  final ContentLength length;
  final int difficultyTier;
  final String contentId;
  final String textTitle;         // stored directly so history survives content changes
  final String sourceText;
  final String spokenText;        // STT output (or manual typed input)
  final int scorePercent;         // 0–100
  final int wordMatchCount;
  final int totalWords;
  final String? recordingPath;

  const GameSession({
    required this.id,
    required this.gameType,
    required this.playedAt,
    required this.category,
    required this.language,
    required this.length,
    required this.difficultyTier,
    required this.contentId,
    required this.textTitle,
    required this.sourceText,
    required this.spokenText,
    required this.scorePercent,
    required this.wordMatchCount,
    required this.totalWords,
    this.recordingPath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'game_type': gameType,
        'played_at': playedAt.millisecondsSinceEpoch,
        'category': category.value,
        'language': language,
        'length': length.value,
        'difficulty_tier': difficultyTier,
        'content_id': contentId,
        'text_title': textTitle,
        'source_text': sourceText,
        'spoken_text': spokenText,
        'score_percent': scorePercent,
        'word_match_count': wordMatchCount,
        'total_words': totalWords,
        'recording_path': recordingPath,
      };

  factory GameSession.fromMap(Map<String, dynamic> m) => GameSession(
        id: m['id'] as String,
        gameType: m['game_type'] as String,
        playedAt: DateTime.fromMillisecondsSinceEpoch(m['played_at'] as int),
        category: ContentCategoryX.fromString(m['category'] as String),
        language: m['language'] as String,
        length: ContentLengthX.fromString(m['length'] as String),
        difficultyTier: m['difficulty_tier'] as int,
        contentId: m['content_id'] as String,
        textTitle: m['text_title'] as String,
        sourceText: m['source_text'] as String,
        spokenText: m['spoken_text'] as String,
        scorePercent: m['score_percent'] as int,
        wordMatchCount: m['word_match_count'] as int,
        totalWords: m['total_words'] as int,
        recordingPath: m['recording_path'] as String?,
      );
}
