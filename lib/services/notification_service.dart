import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Central service for scheduling and cancelling task/medicine alarms.
///
/// Usage:
///   await NotificationService.instance.init();  // once in main()
///   await NotificationService.instance.scheduleTaskAlarm(task);
///   await NotificationService.instance.cancel(notifId);
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // Set local timezone to India (device locale ideally, India default for NER)
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBgNotificationTap,
    );

    // Create the high-priority alarm channel
    const channel = AndroidNotificationChannel(
      'cognicare_alarms',
      'CogniCare Alarms',
      description: 'Full-screen reminders for tasks and medicines',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request exact alarm permission (Android 12+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    // Request notification permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// Schedule a full-screen alarm for a task.
  /// [notifId] must be stored on the Task so we can cancel it later.
  Future<void> scheduleTaskAlarm({
    required int notifId,
    required String taskName,
    required DateTime scheduledAt,
  }) async {
    await _ensureInit();
    // If the scheduled time is already in the past, skip silently
    if (scheduledAt.isBefore(DateTime.now())) return;

    final tzScheduled = tz.TZDateTime.from(scheduledAt, tz.local);

    await _plugin.zonedSchedule(
      notifId,
      '⏰ Reminder', // notification title
      taskName,      // notification body (shown on lock screen)
      tzScheduled,
      _buildNotificationDetails(taskName),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task:$notifId:$taskName',
    );
  }

  /// Schedule a snooze — fires [snoozeMinutes] from now for the same task.
  Future<void> snoozeAlarm({
    required int notifId,
    required String taskName,
    required int snoozeMinutes,
  }) async {
    await _ensureInit();
    final fireAt = DateTime.now().add(Duration(minutes: snoozeMinutes));
    await scheduleTaskAlarm(
      notifId: notifId,
      taskName: taskName,
      scheduledAt: fireAt,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  /// Cancel a single scheduled alarm by its notif ID.
  Future<void> cancel(int notifId) async {
    await _ensureInit();
    await _plugin.cancel(notifId);
  }

  /// Cancel all pending alarms (e.g. on logout).
  Future<void> cancelAll() async {
    await _ensureInit();
    await _plugin.cancelAll();
  }

  // ── ID generation ─────────────────────────────────────────────────────────

  /// Generate a unique notification ID (positive int, fits in 32-bit).
  static int generateNotifId() => Random().nextInt(2147483647);

  // ── Private ───────────────────────────────────────────────────────────────

  AndroidNotificationDetails _buildAndroidDetails(String body) {
    return AndroidNotificationDetails(
      'cognicare_alarms',
      'CogniCare Alarms',
      channelDescription: 'Full-screen reminders for tasks and medicines',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,       // ← shows even on lock screen
      category: AndroidNotificationCategory.alarm,
      ticker: body,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      autoCancel: false,            // must be manually dismissed (patient may forget)
    );
  }

  NotificationDetails _buildNotificationDetails(String body) {
    return NotificationDetails(android: _buildAndroidDetails(body));
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }

  // ── Notification tap handlers ─────────────────────────────────────────────
  // These are called when the user taps the notification from the notification shade.
  // The full-screen alarm screen handles the actual interaction when the alarm fires.

  static void _onNotificationTap(NotificationResponse response) {
    // Payload: "task:<notifId>:<taskName>"
    // On tap, the app should navigate to the alarm screen.
    // Navigation is handled by the app's navigatorKey via the alarm route.
    _handlePayload(response.payload);
  }

  @pragma('vm:entry-point')
  static void _onBgNotificationTap(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  static void _handlePayload(String? payload) {
    // The AlarmScreen is shown as a route when the app is open.
    // When tapped from notification shade: navigatorKey.currentState?.pushNamed('/alarm', arguments: payload)
    // Implemented in main.dart via navigatorKey.
    if (payload != null) {
      alarmPayloadStream.add(payload);
    }
  }

  // Stream used to communicate alarm taps to the running app
  static final AlarmPayloadBus alarmPayloadStream = AlarmPayloadBus();
}

/// Simple broadcast bus so main.dart can listen to incoming alarm taps.
class AlarmPayloadBus {
  final List<void Function(String)> _listeners = [];

  void add(String payload) {
    for (final l in _listeners) {
      l(payload);
    }
  }

  void listen(void Function(String) listener) {
    _listeners.add(listener);
  }
}
