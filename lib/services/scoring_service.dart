/// Scoring service for the Read-Memorize-Speak game.
///
/// Algorithm: Token F1 (from SQuAD NLP benchmark) + LCS order score,
/// with Levenshtein fuzzy matching to handle STT transcription errors.
///
/// This is fully offline and deterministic — no ML needed.
/// Score = (wordMatchScore * 0.7) + (orderScore * 0.3)
class ScoringService {
  ScoringService._();
  static final ScoringService instance = ScoringService._();

  /// Entry point: returns 0–100 integer score.
  ScoringResult score(String sourceText, String spokenText) {
    final source = _normalise(sourceText);
    final spoken = _normalise(spokenText);

    if (source.isEmpty) return const ScoringResult(percent: 0, matched: 0, total: 0);
    if (spoken.isEmpty) return ScoringResult(percent: 0, matched: 0, total: source.length);

    final matched = _countMatches(source, spoken);
    final lcsLen = _lcs(source, spoken);

    final wordMatchScore = matched / source.length;
    final orderScore = lcsLen / source.length;

    final rawScore = (wordMatchScore * 0.7) + (orderScore * 0.3);
    final percent = (rawScore * 100).round().clamp(0, 100);

    return ScoringResult(
      percent: percent,
      matched: matched,
      total: source.length,
      matchedWords: _getMatchedWords(source, spoken),
    );
  }

  // ── Normalization ─────────────────────────────────────────────────────────

  List<String> _normalise(String text) {
    // ⚠️ Do NOT use \w in regex — it only matches ASCII [a-zA-Z0-9_] in Dart.
    // It strips every Devanagari character, making Hindi scores = 0.
    // Fix: explicit string replacements for each punctuation type.
    String s = text.toLowerCase();
    // Devanagari-specific punctuation
    s = s.replaceAll('।', ' ').replaceAll('॥', ' ');
    // Common ASCII punctuation (no character class needed)
    for (final ch in [',', '.', '!', '?', ';', ':', '-', '(', ')', '[', ']',
                       '"', "'", '`', '~', '@', '#', '%', '^', '&', '*',
                       '_', '+', '=', '<', '>', '/', '\\']) {
      s = s.replaceAll(ch, ' ');
    }
    // Collapse whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s
        .split(' ')
        .where((w) {
          if (w.isEmpty) return false;
          // runes.length counts Unicode code points correctly
          return w.runes.length > 1;
        })
        .toList();
  }

  // ── Fuzzy match count ─────────────────────────────────────────────────────

  int _countMatches(List<String> source, List<String> spoken) {
    final remaining = List<String>.from(source);
    int count = 0;
    for (final sw in spoken) {
      final idx = remaining.indexWhere((srcW) => _isMatch(sw, srcW));
      if (idx != -1) {
        count++;
        remaining.removeAt(idx); // each source word matches at most once
      }
    }
    return count;
  }

  Set<String> _getMatchedWords(List<String> source, List<String> spoken) {
    final remaining = List<String>.from(source);
    final matched = <String>{};
    for (final sw in spoken) {
      final idx = remaining.indexWhere((srcW) => _isMatch(sw, srcW));
      if (idx != -1) {
        matched.add(remaining[idx]);
        remaining.removeAt(idx);
      }
    }
    return matched;
  }

  /// Fuzzy match with word-length-based edit distance tolerance.
  bool _isMatch(String spokenWord, String sourceWord) {
    if (spokenWord == sourceWord) return true;
    final len = sourceWord.length;
    if (len <= 4) return false;           // short words: exact only
    if (len <= 7) return _editDist(spokenWord, sourceWord) <= 1;
    return _editDist(spokenWord, sourceWord) <= 2; // long words: lenient
  }

  // ── Levenshtein edit distance ─────────────────────────────────────────────

  int _editDist(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final dp = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) { dp[i][0] = i; }
    for (int j = 0; j <= b.length; j++) { dp[0][j] = j; }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
              .reduce((a, b) => a < b ? a : b);
        }
      }
    }
    return dp[a.length][b.length];
  }

  // ── LCS (Longest Common Subsequence) for order score ─────────────────────

  int _lcs(List<String> a, List<String> b) {
    final dp = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        if (_isMatch(a[i - 1], b[j - 1])) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }
    return dp[a.length][b.length];
  }
}

/// Result of a scoring computation.
class ScoringResult {
  final int percent;          // 0–100 integer
  final int matched;          // number of matched source words
  final int total;            // total source words
  final Set<String> matchedWords; // source words that were matched (for UI highlighting)

  const ScoringResult({
    required this.percent,
    required this.matched,
    required this.total,
    this.matchedWords = const {},
  });

  String get motivationalMessage {
    if (percent >= 70) return 'Wonderful! You remembered so well! 🌟';
    if (percent >= 40) return 'Good effort! Keep practicing, you\'re improving! 💪';
    return 'That\'s okay! Every attempt helps your memory! ❤️';
  }
}
