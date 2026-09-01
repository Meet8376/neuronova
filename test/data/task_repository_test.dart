import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:neuronova/data/repositories/task_repository.dart';
import 'package:neuronova/data/models/task.dart';
import 'package:neuronova/data/db/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TaskRepository CRUD & Status Tests', () {
    late TaskRepository repo;

    setUp(() async {
      await DatabaseHelper.instance.initInMemoryDatabase();
      repo = TaskRepository();
    });

    tearDown(() async {
      final db = await DatabaseHelper.instance.database;
      await db.close();
      DatabaseHelper.instance.setDatabaseForTesting(null);
    });

    test('Create task and retrieve by ID', () async {
      final now = DateTime.now();
      final task = await repo.createTask(
        name: 'Take blood pressure reading',
        scheduledAt: now,
        createdBy: TaskCreator.patient,
        isPrivate: false,
      );

      expect(task.id, isNotEmpty);
      expect(task.name, 'Take blood pressure reading');
      expect(task.status, TaskStatus.upcoming);

      final fetched = await repo.getById(task.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Take blood pressure reading');
    });

    test('Task status transitions: updateStatus to inProgress and done', () async {
      final now = DateTime.now();
      final task = await repo.createTask(
        name: 'Evening walk',
        scheduledAt: now,
        createdBy: TaskCreator.patient,
        isPrivate: false,
      );

      await repo.updateStatus(task.id, TaskStatus.inProgress);
      var updated = await repo.getById(task.id);
      expect(updated!.status, TaskStatus.inProgress);

      await repo.updateStatus(task.id, TaskStatus.done);
      updated = await repo.getById(task.id);
      expect(updated!.status, TaskStatus.done);
    });

    test('Sweep missed tasks marks overdue upcoming tasks as missed', () async {
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));
      final overdueTask = await repo.createTask(
        name: 'Past Overdue Task',
        scheduledAt: pastTime,
        createdBy: TaskCreator.admin,
        isPrivate: false,
      );

      await repo.sweepMissedTasks();
      final swept = await repo.getById(overdueTask.id);
      expect(swept!.status, TaskStatus.missed);
    });

    test('Privacy filtering separates admin and patient visibility', () async {
      final now = DateTime.now();
      final privateTask = await repo.createTask(
        name: 'Personal Diary Entry',
        scheduledAt: now,
        createdBy: TaskCreator.patient,
        isPrivate: true,
      );

      final publicTask = await repo.createTask(
        name: 'Take Calcium Pill',
        scheduledAt: now,
        createdBy: TaskCreator.admin,
        isPrivate: false,
      );

      final todayPatientTasks = await repo.getTodayTasks();
      final todayAdminTasks = await repo.getTodayAdminVisibleTasks();

      expect(todayPatientTasks.any((t) => t.id == privateTask.id), isTrue);
      expect(todayPatientTasks.any((t) => t.id == publicTask.id), isTrue);

      expect(todayAdminTasks.any((t) => t.id == privateTask.id), isFalse);
      expect(todayAdminTasks.any((t) => t.id == publicTask.id), isTrue);
    });

    test('Delete task removes record from database', () async {
      final task = await repo.createTask(
        name: 'Temporary Task to Delete',
        scheduledAt: DateTime.now(),
        createdBy: TaskCreator.patient,
        isPrivate: false,
      );

      expect(await repo.getById(task.id), isNotNull);
      await repo.deleteTask(task.id);
      expect(await repo.getById(task.id), isNull);
    });
  });
}
