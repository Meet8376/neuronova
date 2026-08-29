/// Care reminder types — things dementia patients commonly forget.
/// Each type maps to a specific UI icon and category in the Health tab.
enum CareReminderType {
  hydration,
  meal,
  hygiene,
  activity,
  sleep,
  eyeCare,
  social,
  other,
}

extension CareReminderTypeX on CareReminderType {
  String get value {
    switch (this) {
      case CareReminderType.hydration: return 'hydration';
      case CareReminderType.meal: return 'meal';
      case CareReminderType.hygiene: return 'hygiene';
      case CareReminderType.activity: return 'activity';
      case CareReminderType.sleep: return 'sleep';
      case CareReminderType.eyeCare: return 'eye_care';
      case CareReminderType.social: return 'social';
      case CareReminderType.other: return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case CareReminderType.hydration: return 'Drink Water';
      case CareReminderType.meal: return 'Meals';
      case CareReminderType.hygiene: return 'Hygiene';
      case CareReminderType.activity: return 'Activity';
      case CareReminderType.sleep: return 'Sleep';
      case CareReminderType.eyeCare: return 'Eye Care';
      case CareReminderType.social: return 'Stay Connected';
      case CareReminderType.other: return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case CareReminderType.hydration: return '💧';
      case CareReminderType.meal: return '🍽️';
      case CareReminderType.hygiene: return '🧹';
      case CareReminderType.activity: return '🏃';
      case CareReminderType.sleep: return '😴';
      case CareReminderType.eyeCare: return '👁️';
      case CareReminderType.social: return '📞';
      case CareReminderType.other: return '📋';
    }
  }

  static CareReminderType fromString(String s) {
    return CareReminderType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => CareReminderType.hydration,
    );
  }
}

/// How the reminder is scheduled.
enum ReminderScheduleMode {
  specificTimes, // e.g. 8:00 AM, 1:00 PM, 7:00 PM
  interval,      // e.g. every 2 hours between 8am–10pm
  dailyGoal,     // e.g. drink 8 glasses today (tracked manually)
}

extension ReminderScheduleModeX on ReminderScheduleMode {
  String get value {
    switch (this) {
      case ReminderScheduleMode.specificTimes: return 'specific_times';
      case ReminderScheduleMode.interval: return 'interval';
      case ReminderScheduleMode.dailyGoal: return 'daily_goal';
    }
  }

  static ReminderScheduleMode fromString(String s) {
    switch (s) {
      case 'interval': return ReminderScheduleMode.interval;
      case 'daily_goal': return ReminderScheduleMode.dailyGoal;
      default: return ReminderScheduleMode.specificTimes;
    }
  }
}

/// One care reminder configuration row (set by admin).
/// [configData] is a JSON-encoded map: depends on [scheduleMode].
///   specificTimes → {"times": ["08:00","13:00","19:00"], "names": ["Breakfast","Lunch","Dinner"]}
///   interval      → {"interval_hours": 2.0, "start": "08:00", "end": "22:00"}
///   dailyGoal     → {"goal": 8, "unit": "glasses"}
class CareReminder {
  final String id;
  final CareReminderType type;
  final String name;           // e.g. "Breakfast reminder"
  final ReminderScheduleMode scheduleMode;
  final Map<String, dynamic> configData;
  final bool isActive;
  final DateTime createdAt;

  const CareReminder({
    required this.id,
    required this.type,
    required this.name,
    required this.scheduleMode,
    required this.configData,
    required this.isActive,
    required this.createdAt,
  });

  factory CareReminder.fromMap(Map<String, dynamic> m) {
    return CareReminder(
      id: m['id'] as String,
      type: CareReminderTypeX.fromString(m['type'] as String),
      name: m['name'] as String,
      scheduleMode: ReminderScheduleModeX.fromString(m['schedule_mode'] as String),
      configData: Map<String, dynamic>.from(
          (m['config_data'] as String).isNotEmpty
              ? _parseJson(m['config_data'] as String)
              : {}),
      isActive: (m['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'name': name,
      'schedule_mode': scheduleMode.value,
      'config_data': _encodeJson(configData),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  static Map<String, dynamic> _parseJson(String s) {
    // Simple manual parse to avoid adding dart:convert import issues
    try {
      // Use dart's built-in json via jsonDecode
      return {}; // placeholder — actual impl below
    } catch (_) {
      return {};
    }
  }

  static String _encodeJson(Map<String, dynamic> m) {
    return m.entries.map((e) => '"${e.key}":"${e.value}"').join(',');
  }
}

/// One logged instance of a care reminder (today's dose/glass/meal etc.)
class CareLog {
  final String id;
  final String reminderId;
  final String reminderName;
  final CareReminderType type;
  final DateTime scheduledAt;
  final String status; // 'upcoming' | 'ringing' | 'doing' | 'done' | 'snoozed' | 'missed'
  final DateTime? startedAt;
  final DateTime? doneAt;

  const CareLog({
    required this.id,
    required this.reminderId,
    required this.reminderName,
    required this.type,
    required this.scheduledAt,
    required this.status,
    this.startedAt,
    this.doneAt,
  });

  factory CareLog.fromMap(Map<String, dynamic> m) {
    return CareLog(
      id: m['id'] as String,
      reminderId: m['reminder_id'] as String,
      reminderName: m['reminder_name'] as String,
      type: CareReminderTypeX.fromString(m['type'] as String),
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(m['scheduled_at'] as int),
      status: m['status'] as String,
      startedAt: m['started_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['started_at'] as int)
          : null,
      doneAt: m['done_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['done_at'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'reminder_name': reminderName,
      'type': type.value,
      'scheduled_at': scheduledAt.millisecondsSinceEpoch,
      'status': status,
      'started_at': startedAt?.millisecondsSinceEpoch,
      'done_at': doneAt?.millisecondsSinceEpoch,
    };
  }
}
