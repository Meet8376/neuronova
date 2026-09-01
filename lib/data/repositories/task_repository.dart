import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../models/task.dart';
import 'care_repository.dart';

/// Task repository — all task CRUD and status management.
/// BLoCs call this; this calls DatabaseHelper. Never call DatabaseHelper from a BLoC directly.
class TaskRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  // ── Fetch ──────────────────────────────────────────────────────────────────

  /// Today's tasks for the patient (all visibility).
  Future<List<Task>> getTodayTasks() async {
    // Ensure active care plan reminders are generated for today
    try {
      await CareRepository().syncCarePlanToTodayTasks();
    } catch (_) {}

    final db = await _db.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final rows = await db.query(
      'tasks',
      where: 'scheduled_at >= ? AND scheduled_at <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  /// Today's tasks visible to admin (non-private only).
  Future<List<Task>> getTodayAdminVisibleTasks() async {
    // Ensure active care plan reminders are generated for today
    try {
      await CareRepository().syncCarePlanToTodayTasks();
    } catch (_) {}

    final db = await _db.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final rows = await db.query(
      'tasks',
      where: 'scheduled_at >= ? AND scheduled_at <= ? AND is_private = 0',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  /// All tasks (for the "See all" screen).
  Future<List<Task>> getAllTasks({bool adminView = false}) async {
    try {
      await CareRepository().syncCarePlanToTodayTasks();
    } catch (_) {}

    final db = await _db.database;
    final rows = await db.query(
      'tasks',
      where: adminView ? 'is_private = 0' : null,
      orderBy: 'scheduled_at DESC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<Task?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Task.fromMap(rows.first);
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<Task> createTask({
    required String name,
    required DateTime scheduledAt,
    required TaskCreator createdBy,
    required bool isPrivate,
    int notifId = 0,
    String? reminderId,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      name: name,
      scheduledAt: scheduledAt,
      createdBy: createdBy,
      isPrivate: isPrivate,
      status: TaskStatus.upcoming,
      notifId: notifId,
      createdAt: DateTime.now(),
      reminderId: reminderId,
    );
    final db = await _db.database;
    await db.insert('tasks', task.toMap());
    return task;
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<void> updateTask(Task task) async {
    final db = await _db.database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    final db = await _db.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'tasks',
      {
        'status': status.value,
        'completed_at': status == TaskStatus.done ? nowMs : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // If this task was generated from a care reminder, sync corresponding care_log
    final taskRows = await db.query('tasks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (taskRows.isNotEmpty) {
      final reminderId = taskRows.first['reminder_id'] as String?;
      final scheduledAt = taskRows.first['scheduled_at'] as int?;
      if (reminderId != null && scheduledAt != null) {
        final logStatus = status == TaskStatus.done
            ? 'done'
            : (status == TaskStatus.inProgress ? 'doing' : 'upcoming');
        final logUpdate = <String, dynamic>{'status': logStatus};
        if (status == TaskStatus.done) {
          logUpdate['done_at'] = nowMs;
        } else if (status == TaskStatus.inProgress) {
          logUpdate['started_at'] = nowMs;
        }
        await db.update(
          'care_logs',
          logUpdate,
          where: 'reminder_id = ? AND scheduled_at = ?',
          whereArgs: [reminderId, scheduledAt],
        );
      }
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Only patient-created tasks can be deleted by the patient.
  Future<void> deleteTask(String id) async {
    final db = await _db.database;
    await db.delete('tasks', where: 'id = ? AND created_by = ?', whereArgs: [id, 'patient']);
  }

  // ── Missed task sweep ──────────────────────────────────────────────────────

  /// Call on app open to mark overdue "upcoming" tasks as "missed".
  /// A task is missed if it was scheduled > 30 minutes ago and is still upcoming.
  Future<void> sweepMissedTasks() async {
    final db = await _db.database;
    final threshold = DateTime.now()
        .subtract(const Duration(minutes: 30))
        .millisecondsSinceEpoch;
    await db.update(
      'tasks',
      {'status': TaskStatus.missed.value},
      where: 'status = ? AND scheduled_at < ?',
      whereArgs: [TaskStatus.upcoming.value, threshold],
    );
  }
}
