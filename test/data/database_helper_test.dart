import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:neuronova/data/db/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper Tests', () {
    final dbHelper = DatabaseHelper.instance;

    setUp(() async {
      await dbHelper.initInMemoryDatabase();
    });

    tearDown(() async {
      final db = await dbHelper.database;
      await db.close();
      dbHelper.setDatabaseForTesting(null);
    });

    test('Database initializes and tables exist', () async {
      final db = await dbHelper.database;
      expect(db.isOpen, isTrue);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();

      expect(tableNames, contains('tasks'));
      expect(tableNames, contains('medicine_schedules'));
      expect(tableNames, contains('medicine_doses'));
      expect(tableNames, contains('hydration_config'));
      expect(tableNames, contains('hydration_logs'));
      expect(tableNames, contains('game_sessions'));
      expect(tableNames, contains('app_settings'));
      expect(tableNames, contains('users'));
      expect(tableNames, contains('care_reminders'));
      expect(tableNames, contains('care_logs'));
      expect(tableNames, contains('cognitive_scores'));
      expect(tableNames, contains('patients'));
      expect(tableNames, contains('sync_queue'));
    });

    test('Settings key-value store operates correctly', () async {
      await dbHelper.setSetting('test_key', 'test_value');
      final val = await dbHelper.getSetting('test_key');
      expect(val, 'test_value');

      await dbHelper.setSetting('test_key', 'updated_value');
      final updated = await dbHelper.getSetting('test_key');
      expect(updated, 'updated_value');

      final nonExistent = await dbHelper.getSetting('non_existent_key_123');
      expect(nonExistent, isNull);
    });

    test('Default seeded patients exist for ASHA workflow', () async {
      final db = await dbHelper.database;
      final patients = await db.query('patients');
      expect(patients.length, greaterThanOrEqualTo(3));
      expect(patients.any((p) => p['id'] == 'p1'), isTrue);
    });
  });
}
