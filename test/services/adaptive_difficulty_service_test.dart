import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:neuronova/services/adaptive_difficulty_service.dart';
import 'package:neuronova/data/db/database_helper.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AdaptiveDifficultyService Tests', () {
    final service = AdaptiveDifficultyService.instance;

    setUp(() async {
      await DatabaseHelper.instance.initInMemoryDatabase();
    });

    tearDown(() async {
      final db = await DatabaseHelper.instance.database;
      await db.close();
      DatabaseHelper.instance.setDatabaseForTesting(null);
    });

    test('Returns baseline Tier 1 metrics when no sessions exist', () async {
      final metrics = await service.evaluatePatientCognitiveState(patientId: 'p1');
      expect(metrics.currentTier, 1);
      expect(metrics.trendDirection, 'stable');
      expect(metrics.hasEarlyWarning, isFalse);
    });

    test('Recommends higher tier when average accuracy is high', () async {
      final db = await DatabaseHelper.instance.database;

      // Insert 6 high score sessions
      for (int i = 0; i < 6; i++) {
        await db.insert('game_sessions', {
          'id': const Uuid().v4(),
          'game_type': 'read_memorize_speak',
          'played_at': DateTime.now().subtract(Duration(hours: 6 - i)).millisecondsSinceEpoch,
          'category': 'stories',
          'language': 'en',
          'length': 'short',
          'difficulty_tier': 1,
          'content_id': 'test_$i',
          'text_title': 'Test Title',
          'source_text': 'test',
          'spoken_text': 'test',
          'score_percent': 90,
          'word_match_count': 5,
          'total_words': 5,
        });
      }

      final metrics = await service.evaluatePatientCognitiveState(patientId: 'p1');
      expect(metrics.cognitiveIndex, closeTo(90.0, 0.1));
      expect(metrics.currentTier, 3);
      expect(metrics.hasEarlyWarning, isFalse);
    });

    test('Triggers early warning when noticeable drop (>15%) occurs in recent sessions', () async {
      final db = await DatabaseHelper.instance.database;

      // 3 older high sessions (played 4-6 hours ago)
      for (int i = 0; i < 3; i++) {
        await db.insert('game_sessions', {
          'id': const Uuid().v4(),
          'game_type': 'read_memorize_speak',
          'played_at': DateTime.now().subtract(Duration(hours: 6 - i)).millisecondsSinceEpoch,
          'category': 'stories',
          'language': 'en',
          'length': 'short',
          'difficulty_tier': 2,
          'content_id': 'old_$i',
          'text_title': 'Old Title',
          'source_text': 'test',
          'spoken_text': 'test',
          'score_percent': 90, // 90% older avg
          'word_match_count': 9,
          'total_words': 10,
        });
      }

      // 3 recent low sessions (played 1-3 hours ago)
      for (int i = 0; i < 3; i++) {
        await db.insert('game_sessions', {
          'id': const Uuid().v4(),
          'game_type': 'read_memorize_speak',
          'played_at': DateTime.now().subtract(Duration(hours: 3 - i)).millisecondsSinceEpoch,
          'category': 'stories',
          'language': 'en',
          'length': 'short',
          'difficulty_tier': 2,
          'content_id': 'recent_$i',
          'text_title': 'Recent Title',
          'source_text': 'test',
          'spoken_text': 'test',
          'score_percent': 50, // 50% recent avg -> 40% drop
          'word_match_count': 5,
          'total_words': 10,
        });
      }

      final metrics = await service.evaluatePatientCognitiveState(patientId: 'p1');
      expect(metrics.trendDirection, 'declining');
      expect(metrics.hasEarlyWarning, isTrue);
      expect(metrics.warningMessage, contains('Noticeable decline'));

      final patients = await db.query('patients', where: 'id = ?', whereArgs: ['p1']);
      expect(patients.first['status'], 'attention_needed');
    });
  });
}
