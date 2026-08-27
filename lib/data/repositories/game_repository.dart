import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/content_item.dart';
import '../../data/db/database_helper.dart';
import '../../data/models/game_session.dart';
import 'package:uuid/uuid.dart';

/// Manages game content (loading from assets) and session persistence.
class GameRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();
  final _rng = Random();

  List<ContentItem>? _allContent;

  // ── Content loading ────────────────────────────────────────────────────────

  /// Loads and caches all content from the bundled JSON asset.
  Future<List<ContentItem>> _getContent() async {
    if (_allContent != null) return _allContent!;
    final jsonStr = await rootBundle.loadString('assets/content/texts.json');
    final List<dynamic> jsonList = json.decode(jsonStr) as List;
    _allContent = jsonList
        .map((j) => ContentItem.fromJson(j as Map<String, dynamic>))
        .toList();
    return _allContent!;
  }

  /// Returns a random ContentItem matching the given filters.
  /// Respects the current difficulty tier from settings.
  Future<ContentItem?> getRandomContent({
    required ContentCategory category,
    required String language,
    required ContentLength length,
    required int difficultyTier,
  }) async {
    final all = await _getContent();
    final filtered = all.where((c) =>
        c.category == category &&
        c.language == language &&
        c.length == length &&
        c.difficultyTier == difficultyTier).toList();

    if (filtered.isEmpty) {
      // Fallback: relax difficulty constraint
      final relaxed = all.where((c) =>
          c.category == category && c.language == language && c.length == length).toList();
      if (relaxed.isEmpty) return null;
      return relaxed[_rng.nextInt(relaxed.length)];
    }
    return filtered[_rng.nextInt(filtered.length)];
  }

  Future<List<ContentCategory>> getAvailableCategories(String language) async {
    final all = await _getContent();
    return all.where((c) => c.language == language).map((c) => c.category).toSet().toList();
  }

  Future<List<String>> getAvailableLanguages() async {
    final all = await _getContent();
    return all.map((c) => c.language).toSet().toList();
  }

  // ── Difficulty adaptation ──────────────────────────────────────────────────

  Future<int> getCurrentDifficulty() async {
    final val = await _db.getSetting('difficulty_rms');
    return int.tryParse(val ?? '1') ?? 1;
  }

  /// After every session, check if last 3 sessions warrant a difficulty change.
  Future<void> updateDifficulty() async {
    final db = await _db.database;
    final rows = await db.query(
      'game_sessions',
      where: "game_type = 'read_memorize_speak'",
      orderBy: 'played_at DESC',
      limit: 3,
    );
    if (rows.length < 3) return;

    final scores = rows.map((r) => r['score_percent'] as int).toList();
    final current = await getCurrentDifficulty();

    final allHigh = scores.every((s) => s >= 80);
    final allLow = scores.every((s) => s <= 40);

    if (allHigh && current < 3) {
      await _db.setSetting('difficulty_rms', '${current + 1}');
    } else if (allLow && current > 1) {
      await _db.setSetting('difficulty_rms', '${current - 1}');
    }
  }

  // ── Session persistence ────────────────────────────────────────────────────

  Future<GameSession> saveSession(GameSession session) async {
    final db = await _db.database;
    final s = GameSession(
      id: _uuid.v4(),
      gameType: session.gameType,
      playedAt: session.playedAt,
      category: session.category,
      language: session.language,
      length: session.length,
      difficultyTier: session.difficultyTier,
      contentId: session.contentId,
      textTitle: session.textTitle,
      sourceText: session.sourceText,
      spokenText: session.spokenText,
      scorePercent: session.scorePercent,
      wordMatchCount: session.wordMatchCount,
      totalWords: session.totalWords,
      recordingPath: session.recordingPath,
    );
    await db.insert('game_sessions', s.toMap());
    await updateDifficulty();
    return s;
  }

  Future<List<GameSession>> getRecentSessions({int limit = 20}) async {
    final db = await _db.database;
    final rows = await db.query(
      'game_sessions',
      orderBy: 'played_at DESC',
      limit: limit,
    );
    return rows.map(GameSession.fromMap).toList();
  }

  Future<GameSession?> getLatestSession() async {
    final sessions = await getRecentSessions(limit: 1);
    return sessions.isEmpty ? null : sessions.first;
  }
}
