import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:neuronova/data/repositories/game_repository.dart';
import 'package:neuronova/data/models/game_session.dart';
import 'package:neuronova/data/models/content_item.dart';
import 'package:neuronova/data/db/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('GameRepository Tests', () {
    late GameRepository repo;

    setUp(() async {
      await DatabaseHelper.instance.initInMemoryDatabase();
      repo = GameRepository();
    });

    tearDown(() async {
      final db = await DatabaseHelper.instance.database;
      await db.close();
      DatabaseHelper.instance.setDatabaseForTesting(null);
    });

    test('Save game session and fetch latest', () async {
      final now = DateTime.now();
      final session = GameSession(
        id: '',
        gameType: 'read_memorize_speak',
        playedAt: now,
        category: ContentCategory.wisdom,
        language: 'en',
        length: ContentLength.short,
        difficultyTier: 1,
        contentId: 'wisdom_1',
        textTitle: 'Morning Peace',
        sourceText: 'May peace and joy prevail everywhere today.',
        spokenText: 'May peace and joy prevail everywhere today.',
        scorePercent: 95,
        wordMatchCount: 7,
        totalWords: 7,
      );

      final saved = await repo.saveSession(session);
      expect(saved.id, isNotEmpty);
      expect(saved.scorePercent, 95);

      final latest = await repo.getLatestSession();
      expect(latest, isNotNull);
      expect(latest!.textTitle, 'Morning Peace');
      expect(latest.scorePercent, 95);

      final recent = await repo.getRecentSessions(limit: 5);
      expect(recent.any((s) => s.id == saved.id), isTrue);
    });

    test('Get current difficulty defaults to tier 1', () async {
      final tier = await repo.getCurrentDifficulty();
      expect(tier, inInclusiveRange(1, 4));
    });
  });
}
