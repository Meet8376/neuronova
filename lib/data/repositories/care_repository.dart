import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../models/care_reminder.dart';

/// Repository for all care reminder operations.
/// Admin creates/edits reminders. Patient marks logs as done/doing/snoozed.
class CareRepository {
  final _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  // ─── Admin: manage reminder configs ──────────────────────────────────────────

  /// Create a new care reminder (admin action).
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
    return reminder;
  }

  /// Update a care reminder config.
  Future<void> updateReminder(CareReminder reminder) async {
    final db = await _db.database;
    final map = reminder.toMap();
    map['config_data'] = jsonEncode(reminder.configData);
    await db.update('care_reminders', map,
        where: 'id = ?', whereArgs: [reminder.id]);
  }

  /// Toggle active/inactive.
  Future<void> setReminderActive(String id, bool active) async {
    final db = await _db.database;
    await db.update('care_reminders', {'is_active': active ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Delete a reminder and its logs.
  Future<void> deleteReminder(String id) async {
    final db = await _db.database;
    await db.delete('care_logs', where: 'reminder_id = ?', whereArgs: [id]);
    await db.delete('care_reminders', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all reminders (for admin config screen).
  Future<List<CareReminder>> getAllReminders() async {
    final db = await _db.database;
    final rows = await db.query('care_reminders', orderBy: 'created_at ASC');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      try {
        m['config_data_parsed'] = jsonDecode(m['config_data'] as String);
      } catch (_) {}
      return _fromMapWithJson(m);
    }).toList();
  }

  /// Get only active reminders.
  Future<List<CareReminder>> getActiveReminders() async {
    final db = await _db.database;
    final rows = await db.query('care_reminders',
        where: 'is_active = 1', orderBy: 'created_at ASC');
    return rows.map((r) => _fromMapWithJson(r)).toList();
  }

  // ─── Patient: manage today's care logs ───────────────────────────────────────

  /// Generate today's care logs from active reminder configs.
  /// Called once per day (or on app start if not yet generated for today).
  Future<void> generateTodayLogs() async {
    final db = await _db.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Check if logs already generated today
    final existing = await db.query(
      'care_logs',
      where: 'scheduled_at >= ? AND scheduled_at < ?',
      whereArgs: [
        todayStart.millisecondsSinceEpoch,
        todayStart.add(const Duration(days: 1)).millisecondsSinceEpoch,
      ],
      limit: 1,
    );
    if (existing.isNotEmpty) return; // already done

    final reminders = await getActiveReminders();
    for (final reminder in reminders) {
      final times = _getTimesForToday(reminder, todayStart);
      for (final scheduledAt in times) {
        final log = CareLog(
          id: _uuid.v4(),
          reminderId: reminder.id,
          reminderName: reminder.name,
          type: reminder.type,
          scheduledAt: scheduledAt,
          status: 'upcoming',
        );
        await db.insert('care_logs', log.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
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

  /// Update a care log status.
  Future<void> updateLogStatus(String logId, String status) async {
    final db = await _db.database;
    final update = <String, dynamic>{'status': status};
    if (status == 'doing') {
      update['started_at'] = DateTime.now().millisecondsSinceEpoch;
    } else if (status == 'done') {
      update['done_at'] = DateTime.now().millisecondsSinceEpoch;
    }
    await db.update('care_logs', update, where: 'id = ?', whereArgs: [logId]);
  }

  /// For daily_goal type: add one unit (e.g. one glass of water).
  Future<int> incrementGoalCount(String logId) async {
    final db = await _db.database;
    final rows = await db.query('care_logs', where: 'id = ?', whereArgs: [logId]);
    if (rows.isEmpty) return 0;
    final current = rows.first['goal_count'] as int? ?? 0;
    final newCount = current + 1;
    await db.update('care_logs', {'goal_count': newCount},
        where: 'id = ?', whereArgs: [logId]);
    return newCount;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  List<DateTime> _getTimesForToday(CareReminder reminder, DateTime todayStart) {
    final config = reminder.configData;
    switch (reminder.scheduleMode) {
      case ReminderScheduleMode.specificTimes:
        final times = (config['times'] as List?)?.cast<String>() ?? [];
        return times.map((t) {
          final parts = t.split(':');
          return todayStart.add(Duration(
            hours: int.tryParse(parts[0]) ?? 0,
            minutes: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
          ));
        }).toList();

      case ReminderScheduleMode.interval:
        final intervalHours = (config['interval_hours'] as num?)?.toDouble() ?? 2.0;
        final startParts = (config['start'] as String? ?? '08:00').split(':');
        final endParts = (config['end'] as String? ?? '22:00').split(':');
        final start = todayStart.add(Duration(
          hours: int.tryParse(startParts[0]) ?? 8,
          minutes: int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0,
        ));
        final end = todayStart.add(Duration(
          hours: int.tryParse(endParts[0]) ?? 22,
          minutes: int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0,
        ));
        final times = <DateTime>[];
        var current = start;
        while (!current.isAfter(end)) {
          times.add(current);
          current = current.add(Duration(
              minutes: (intervalHours * 60).round()));
        }
        return times;

      case ReminderScheduleMode.dailyGoal:
        // One log per day (not time-specific) — patient tracks manually
        return [todayStart.add(const Duration(hours: 8))];
    }
  }

  static CareReminder _fromMapWithJson(Map<String, dynamic> r) {
    Map<String, dynamic> config = {};
    try {
      config = jsonDecode(r['config_data'] as String) as Map<String, dynamic>;
    } catch (_) {}
    return CareReminder(
      id: r['id'] as String,
      type: CareReminderTypeX.fromString(r['type'] as String),
      name: r['name'] as String,
      scheduleMode: ReminderScheduleModeX.fromString(r['schedule_mode'] as String),
      configData: config,
      isActive: (r['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    );
  }
}
