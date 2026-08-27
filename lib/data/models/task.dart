/// Task status — maps 1:1 to the string stored in SQLite.
enum TaskStatus { upcoming, inProgress, done, missed }

extension TaskStatusX on TaskStatus {
  String get value {
    switch (this) {
      case TaskStatus.upcoming: return 'upcoming';
      case TaskStatus.inProgress: return 'in_progress';
      case TaskStatus.done: return 'done';
      case TaskStatus.missed: return 'missed';
    }
  }

  static TaskStatus fromString(String s) {
    switch (s) {
      case 'in_progress': return TaskStatus.inProgress;
      case 'done': return TaskStatus.done;
      case 'missed': return TaskStatus.missed;
      default: return TaskStatus.upcoming;
    }
  }
}

/// CreatedBy — who created the task.
enum TaskCreator { patient, admin }

extension TaskCreatorX on TaskCreator {
  String get value => this == TaskCreator.patient ? 'patient' : 'admin';
  static TaskCreator fromString(String s) =>
      s == 'admin' ? TaskCreator.admin : TaskCreator.patient;
}

/// Core Task entity — used by BLoC and UI.
class Task {
  final String id;
  final String name;
  final DateTime scheduledAt;
  final TaskCreator createdBy;
  final bool isPrivate;
  final TaskStatus status;
  final int notifId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.name,
    required this.scheduledAt,
    required this.createdBy,
    required this.isPrivate,
    required this.status,
    required this.notifId,
    required this.createdAt,
    this.completedAt,
  });

  /// Returns true if this task was created by the patient (shows 3-dot menu).
  bool get isPatientOwned => createdBy == TaskCreator.patient;

  /// Returns true if the task should be visible to the admin.
  bool get isAdminVisible => !isPrivate;

  Task copyWith({
    String? name,
    DateTime? scheduledAt,
    TaskStatus? status,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      name: name ?? this.name,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdBy: createdBy,
      isPrivate: isPrivate,
      status: status ?? this.status,
      notifId: notifId,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'scheduled_at': scheduledAt.millisecondsSinceEpoch,
        'created_by': createdBy.value,
        'is_private': isPrivate ? 1 : 0,
        'status': status.value,
        'notif_id': notifId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
      };

  factory Task.fromMap(Map<String, dynamic> m) => Task(
        id: m['id'] as String,
        name: m['name'] as String,
        scheduledAt: DateTime.fromMillisecondsSinceEpoch(m['scheduled_at'] as int),
        createdBy: TaskCreatorX.fromString(m['created_by'] as String),
        isPrivate: (m['is_private'] as int) == 1,
        status: TaskStatusX.fromString(m['status'] as String),
        notifId: m['notif_id'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        completedAt: m['completed_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['completed_at'] as int)
            : null,
      );

  @override
  String toString() => 'Task($id, $name, $status)';
}
