import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../models/care_reminder.dart';
import '../models/task.dart';
import '../../services/notification_service.dart';
import '../../services/sync_service.dart';

/// Repository for all care reminder operations.
/// Caregiver creates/edits reminders. Patient marks logs & tasks as done/doing/snoozed.
class CareRepository {
  final _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  // ─── Admin: manage reminder configs ──────────────────────────────────────────

  /// Create a new care reminder (admin action) and immediately generate today's tasks & logs.
  Future<CareReminder> createReminder({
    required CareReminderType type,
    required String name,
    required ReminderScheduleMode scheduleMode,
    required Map<String, dynamic> configData,
  }) async {
    final db = await _db.database;
    final reminder = CareReminder(
      id: _uuid.v4(),
      type: type,
      name: name,
      scheduleMode: scheduleMode,
      configData: configData,
      isActive: true,
      createdAt: DateTime.now(),
    );
    final map = reminder.toMap();
    map['config_data'] = jsonEncode(configData);
    await db.insert('care_reminders', map);

    // Immediately generate today's care logs and patient tasks
    await _syncTodayForReminder(reminder);

    // Queue offline sync
    try {
      await SyncService.instance.enqueueSyncItem('care_reminder_created', map);
    } catch (_) {}

    return reminder;
  }

  /// Update a care reminder config and re-sync today's tasks.
  Future<void> updateReminder(CareReminder reminder) async {
    final db = await _db.database;
    final map = reminder.toMap();
    map['config_data'] = jsonEncode(reminder.configData);
    await db.update(
      'care_reminders',
      map,
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
    await _syncTodayForReminder(reminder);
  }

  /// Toggle active/inactive. When inactive, removes uncompleted tasks for today.
  Future<void> setReminderActive(String id, bool active) async {
    final db = await _db.database;
    await db.update(
      'care_reminders',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    final rows = await db.query(
      'care_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isNotEmpty) {
      final reminder = _fromMapWithJson(rows.first);
      await _syncTodayForReminder(reminder);
    }
  }

  /// Delete a reminder, its logs, and any uncompleted tasks created from it.
  Future<void> deleteReminder(String id) async {
    final db = await _db.database;

    // Cancel alarms for upcoming tasks linked to this reminder
    final uncompletedTasks = await db.query(
      'tasks',
      where: 'reminder_id = ? AND status != ?',
      whereArgs: [id, TaskStatus.done.value],
    );
    for (final row in uncompletedTasks) {
      final notifId = row['notif_id'] as int? ?? 0;
      if (notifId > 0) {
        try {
          await NotificationService.instance.cancel(notifId);
        } catch (_) {}
      }
    }

    // Delete tasks, logs, and reminder
    await db.delete(
      'tasks',
      where: 'reminder_id = ? AND status != ?',
      whereArgs: [id, TaskStatus.done.value],
    );
    await db.delete('care_logs', where: 'reminder_id = ?', whereArgs: [id]);
    await db.delete('care_reminders', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all reminders (for admin config screen).
  Future<List<CareReminder>> getAllReminders() async {
    final db = await _db.database;
    final rows = await db.query('care_reminders', orderBy: 'created_at ASC');
    return rows.map((r) => _fromMapWithJson(r)).toList();
  }

  /// Get only active reminders.
  Future<List<CareReminder>> getActiveReminders() async {
    final db = await _db.database;
    final rows = await db.query(
      'care_reminders',
      where: 'is_active = 1',
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => _fromMapWithJson(r)).toList();
  }

  // ─── Patient: manage today's care logs & task sync ─────────────────────────

  /// Sync all active care plan reminders to today's care logs and patient tasks.
  /// Safe and idempotent: can be called repeatedly without creating duplicates.
  Future<void> syncCarePlanToTodayTasks() async {
    final reminders = await getActiveReminders();
    for (final reminder in reminders) {
      await _syncTodayForReminder(reminder);
    }
  }

  /// Backward-compatible alias for syncCarePlanToTodayTasks.
  Future<void> generateTodayLogs() async {
    await syncCarePlanToTodayTasks();
  }

  /// Get today's care logs for the patient's Health tab.
  Future<List<CareLog>> getTodayLogs() async {
    final db = await _db.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final rows = await db.query(
      'care_logs',
      where: 'scheduled_at >= ? AND scheduled_at < ?',
      whereArgs: [
        todayStart.millisecondsSinceEpoch,
        todayStart.add(const Duration(days: 1)).millisecondsSinceEpoch,
      ],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map((r) => CareLog.fromMap(r)).toList();
  }

  /// Update a care log status and synchronize with the corresponding task.
  Future<void> updateLogStatus(String logId, String status) async {
    final db = await _db.database;
    final update = <String, dynamic>{'status': status};
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (status == 'doing') {
      update['started_at'] = nowMs;
    } else if (status == 'done') {
      update['done_at'] = nowMs;
    }
    await db.update('care_logs', update, where: 'id = ?', whereArgs: [logId]);

    // Find the log details to sync corresponding task
    final logRows = await db.query(
      'care_logs',
      where: 'id = ?',
      whereArgs: [logId],
      limit: 1,
    );
    if (logRows.isNotEmpty) {
      final reminderId = logRows.first['reminder_id'] as String;
      final scheduledAt = logRows.first['scheduled_at'] as int;

      final taskStatus = status == 'done'
          ? TaskStatus.done.value
          : (status == 'doing'
              ? TaskStatus.inProgress.value
              : TaskStatus.upcoming.value);

      await db.update(
        'tasks',
        {
          'status': taskStatus,
          'completed_at': status == 'done' ? nowMs : null,
        },
        where: 'reminder_id = ? AND scheduled_at = ?',
        whereArgs: [reminderId, scheduledAt],
      );

      // Cancel notification if marked done
      if (status == 'done') {
        final taskRows = await db.query(
          'tasks',
          where: 'reminder_id = ? AND scheduled_at = ?',
          whereArgs: [reminderId, scheduledAt],
        );
        for (final t in taskRows) {
          final notifId = t['notif_id'] as int? ?? 0;
          if (notifId > 0) {
            try {
              await NotificationService.instance.cancel(notifId);
            } catch (_) {}
          }
        }
      }
    }
  }

  /// For daily_goal type: add one unit (e.g. one glass of water).
  Future<int> incrementGoalCount(String logId) async {
    final db = await _db.database;
    final rows = await db.query(
      'care_logs',
      where: 'id = ?',
      whereArgs: [logId],
    );
    if (rows.isEmpty) return 0;
    final current = rows.first['goal_count'] as int? ?? 0;
    final newCount = current + 1;
    await db.update(
      'care_logs',
      {'goal_count': newCount},
      where: 'id = ?',
      whereArgs: [logId],
    );
    return newCount;
  }

  // ─── Internal Synchronization Logic ─────────────────────────────────────────

  Future<void> _syncTodayForReminder(CareReminder reminder) async {
    final db = await _db.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (!reminder.isActive) {
      // Clean up today's uncompleted tasks and logs for this deactivated reminder
      final uncompleted = await db.query(
        'tasks',
        where:
            'reminder_id = ? AND scheduled_at >= ? AND scheduled_at <= ? AND status != ?',
        whereArgs: [
          reminder.id,
          todayStart.millisecondsSinceEpoch,
          todayEnd.millisecondsSinceEpoch,
          TaskStatus.done.value,
        ],
      );
      for (final r in uncompleted) {
        final notifId = r['notif_id'] as int? ?? 0;
        if (notifId > 0) {
          try {
            await NotificationService.instance.cancel(notifId);
          } catch (_) {}
        }
      }
      await db.delete(
        'tasks',
        where:
            'reminder_id = ? AND scheduled_at >= ? AND scheduled_at <= ? AND status != ?',
        whereArgs: [
          reminder.id,
          todayStart.millisecondsSinceEpoch,
          todayEnd.millisecondsSinceEpoch,
          TaskStatus.done.value,
        ],
      );
      await db.delete(
        'care_logs',
        where:
            'reminder_id = ? AND scheduled_at >= ? AND scheduled_at <= ? AND status != ?',
        whereArgs: [
          reminder.id,
          todayStart.millisecondsSinceEpoch,
          todayEnd.millisecondsSinceEpoch,
          'done',
        ],
      );
      return;
    }

    // Active reminder: calculate scheduled instances for today
    final instances = _getInstancesForToday(reminder, todayStart);

    for (final instance in instances) {
      final scheduledAt = instance.time;
      final label = instance.label;
      final scheduledMs = scheduledAt.millisecondsSinceEpoch;

      // 1. Ensure CareLog exists for today
      final existingLog = await db.query(
        'care_logs',
        where: 'reminder_id = ? AND scheduled_at = ?',
        whereArgs: [reminder.id, scheduledMs],
        limit: 1,
      );

      if (existingLog.isEmpty) {
        final log = CareLog(
          id: _uuid.v4(),
          reminderId: reminder.id,
          reminderName: reminder.name,
          type: reminder.type,
          scheduledAt: scheduledAt,
          status: 'upcoming',
        );
        await db.insert(
          'care_logs',
          log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      // 2. Ensure Task exists in tasks table for today
      final existingTask = await db.query(
        'tasks',
        where: 'reminder_id = ? AND scheduled_at = ?',
        whereArgs: [reminder.id, scheduledMs],
        limit: 1,
      );

      if (existingTask.isEmpty) {
        String taskName;
        if (label != null &&
            label.trim().isNotEmpty &&
            label.trim().toLowerCase() != reminder.name.trim().toLowerCase()) {
          taskName = '${reminder.type.icon} ${reminder.name} ($label)';
        } else {
          taskName = '${reminder.type.icon} ${reminder.name}';
        }

        final notifId = NotificationService.generateNotifId();

        final task = Task(
          id: _uuid.v4(),
          name: taskName,
          scheduledAt: scheduledAt,
          createdBy: TaskCreator.admin,
          isPrivate: false,
          status: TaskStatus.upcoming,
          notifId: notifId,
          createdAt: DateTime.now(),
          reminderId: reminder.id,
        );

        await db.insert(
          'tasks',
          task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        // Schedule real alarm/notification if in the future
        if (scheduledAt.isAfter(DateTime.now())) {
          try {
            await NotificationService.instance.scheduleTaskAlarm(
              notifId: notifId,
              taskName: taskName,
              scheduledAt: scheduledAt,
            );
          } catch (e) {
            debugPrint('Error scheduling task alarm: $e');
          }
        }
      }
    }
  }

  List<_CareScheduleInstance> _getInstancesForToday(
    CareReminder reminder,
    DateTime todayStart,
  ) {
    final config = reminder.configData;
    switch (reminder.scheduleMode) {
      case ReminderScheduleMode.specificTimes:
        final times = (config['times'] as List?)?.cast<String>() ?? [];
        final names = (config['names'] as List?)?.cast<String>() ?? [];
        final list = <_CareScheduleInstance>[];
        for (int i = 0; i < times.length; i++) {
          final t = times[i];
          final parts = t.split(':');
          final scheduled = todayStart.add(
            Duration(
              hours: int.tryParse(parts[0]) ?? 0,
              minutes: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
            ),
          );
          final label = i < names.length ? names[i] : null;
          list.add(_CareScheduleInstance(time: scheduled, label: label));
        }
        return list;

      case ReminderScheduleMode.interval:
        final intervalHours =
            (config['interval_hours'] as num?)?.toDouble() ?? 2.0;
        final startParts = (config['start'] as String? ?? '08:00').split(':');
        final endParts = (config['end'] as String? ?? '22:00').split(':');
        final start = todayStart.add(
          Duration(
            hours: int.tryParse(startParts[0]) ?? 8,
            minutes:
                int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0,
          ),
        );
        final end = todayStart.add(
          Duration(
            hours: int.tryParse(endParts[0]) ?? 22,
            minutes:
                int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0,
          ),
        );
        final list = <_CareScheduleInstance>[];
        var current = start;
        int step = 1;
        while (!current.isAfter(end)) {
          list.add(_CareScheduleInstance(time: current, label: 'Dose $step'));
          current = current.add(
            Duration(minutes: (intervalHours * 60).round()),
          );
          step++;
        }
        return list;

      case ReminderScheduleMode.dailyGoal:
        final goal = config['goal'] ?? config['target_glasses'] ?? 8;
        final unit = config['unit'] ?? 'glasses';
        return [
          _CareScheduleInstance(
            time: todayStart.add(const Duration(hours: 8)),
            label: 'Goal: $goal $unit',
          ),
        ];
    }
  }

  static CareReminder _fromMapWithJson(Map<String, dynamic> r) {
    Map<String, dynamic> config = {};
    try {
      final raw = r['config_data'];
      if (raw is String && raw.isNotEmpty) {
        config = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        config = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}
    return CareReminder(
      id: r['id'] as String,
      type: CareReminderTypeX.fromString(r['type'] as String),
      name: r['name'] as String,
      scheduleMode:
          ReminderScheduleModeX.fromString(r['schedule_mode'] as String),
      configData: config,
      isActive: (r['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    );
  }
}

class _CareScheduleInstance {
  final DateTime time;
  final String? label;
  const _CareScheduleInstance({required this.time, this.label});
}
