import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:neuronova/data/repositories/care_repository.dart';
import 'package:neuronova/data/models/care_reminder.dart';
import 'package:neuronova/data/db/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('CareRepository Tests', () {
    late CareRepository repo;

    setUp(() async {
      await DatabaseHelper.instance.initInMemoryDatabase();
      repo = CareRepository();
    });

    tearDown(() async {
      final db = await DatabaseHelper.instance.database;
      await db.close();
      DatabaseHelper.instance.setDatabaseForTesting(null);
    });

    test('Create, retrieve and toggle care reminder', () async {
      final reminder = await repo.createReminder(
        type: CareReminderType.hydration,
        name: 'Drink 250ml Water',
        scheduleMode: ReminderScheduleMode.interval,
        configData: {'interval_hours': 2.0, 'start': '08:00', 'end': '20:00'},
      );

      expect(reminder.id, isNotEmpty);
      expect(reminder.isActive, isTrue);

      final all = await repo.getAllReminders();
      expect(all.any((r) => r.id == reminder.id), isTrue);

      await repo.setReminderActive(reminder.id, false);
      final active = await repo.getActiveReminders();
      expect(active.any((r) => r.id == reminder.id), isFalse);

      await repo.setReminderActive(reminder.id, true);
    });

    test('Generate today logs from active care reminders', () async {
      await repo.createReminder(
        type: CareReminderType.hydration,
        name: 'Drink Water Interval',
        scheduleMode: ReminderScheduleMode.interval,
        configData: {'interval_hours': 4.0, 'start': '08:00', 'end': '16:00'},
      );

      await repo.generateTodayLogs();
      final logs = await repo.getTodayLogs();
      expect(logs, isNotEmpty);
    });

    test('Log status updates and goal count increments', () async {
      final reminder = await repo.createReminder(
        type: CareReminderType.hydration,
        name: 'Daily Hydration Goal',
        scheduleMode: ReminderScheduleMode.dailyGoal,
        configData: {'target_glasses': 8},
      );

      await repo.generateTodayLogs();
      final logs = await repo.getTodayLogs();
      expect(logs, isNotEmpty);
      final goalLog = logs.firstWhere((l) => l.reminderId == reminder.id);

      await repo.updateLogStatus(goalLog.id, 'doing');
      await repo.updateLogStatus(goalLog.id, 'done');

      final count1 = await repo.incrementGoalCount(goalLog.id);
      expect(count1, equals(1));

      final count2 = await repo.incrementGoalCount(goalLog.id);
      expect(count2, equals(2));
    });

    test('Delete reminder cleans up reminder and logs', () async {
      final reminder = await repo.createReminder(
        type: CareReminderType.activity,
        name: 'Morning Courtyard Walk',
        scheduleMode: ReminderScheduleMode.specificTimes,
        configData: {
          'times': ['07:30']
        },
      );

      await repo.deleteReminder(reminder.id);
      final all = await repo.getAllReminders();
      expect(all.any((r) => r.id == reminder.id), isFalse);
    });

    test('Creating a CareReminder generates patient tasks in tasks table', () async {
      final reminder = await repo.createReminder(
        type: CareReminderType.meal,
        name: 'Meals',
        scheduleMode: ReminderScheduleMode.specificTimes,
        configData: {
          'times': ['08:00', '13:00'],
          'names': ['Breakfast', 'Lunch'],
        },
      );

      final db = await DatabaseHelper.instance.database;
      final tasks = await db.query(
        'tasks',
        where: 'reminder_id = ?',
        whereArgs: [reminder.id],
      );

      expect(tasks.length, 2);
      expect(tasks.first['created_by'], 'admin');
      expect(tasks.first['is_private'], 0);
      expect(tasks.first['status'], 'upcoming');
      expect((tasks.first['name'] as String).contains('Breakfast'), isTrue);
    });

    test('Updating care log status synchronizes corresponding task in tasks table', () async {
      final reminder = await repo.createReminder(
        type: CareReminderType.medication,
        name: 'Morning BP Medicine',
        scheduleMode: ReminderScheduleMode.specificTimes,
        configData: {
          'times': ['08:00'],
          'names': ['Morning Dose'],
        },
      );

      final logs = await repo.getTodayLogs();
      final medLog = logs.firstWhere((l) => l.reminderId == reminder.id);
      await repo.updateLogStatus(medLog.id, 'done');

      final db = await DatabaseHelper.instance.database;
      final tasks = await db.query(
        'tasks',
        where: 'reminder_id = ?',
        whereArgs: [reminder.id],
      );

      expect(tasks.first['status'], 'done');
      expect(tasks.first['completed_at'], isNotNull);
    });
  });
}
