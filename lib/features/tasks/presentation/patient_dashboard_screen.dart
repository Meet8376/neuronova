import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../services/secure_settings_service.dart';
import '../../../services/notification_service.dart';
import 'add_task_sheet.dart';
import 'task_card.dart';
import 'all_tasks_screen.dart';

/// Patient home screen — the first thing they see every day.
///
/// Per specs/screens/screens.md P1 and elderly_ux_spec.md:
///   - Greeting + reality orientation date+time line (one combined block)
///   - Today's tasks sorted by time
///   - Emergency call button placeholder (feature pending)
///   - FAB for adding own tasks
///
/// Health is now its own primary tab — NOT shown here as a sub-tab.
/// The DefaultTabController that was here before is gone.
class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  final _repo = TaskRepository();
  final _secure = SecureSettingsService.instance;

  String _patientName = '';
  String _caregiverName = '';
  String _caregiverPhone = '';
  List<Task> _todayTasks = [];
  bool _loading = true;

  // Live clock — updates every minute for reality orientation
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    // Tick the clock every minute
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final name = await _secure.getPatientName();
    final cName = await _secure.getAdminName();
    final phone = await _secure.getCaregiverPhone();
    final tasks = await _repo.getTodayTasks();
    if (!mounted) return;
    setState(() {
      _patientName = name ?? '';
      _caregiverName = cName ?? 'Caregiver';
      _caregiverPhone = phone;
      _todayTasks = tasks;
      _loading = false;
    });
  }

  // ── Greeting helpers ───────────────────────────────────────────────────────

  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _greetingEmoji {
    final h = _now.hour;
    if (h < 12) return '🌅';
    if (h < 17) return '🌞';
    return '🌙';
  }

  /// Full date + time line for reality orientation.
  /// Format: "Tuesday, 26 August 2025 · 3:45 PM"
  String get _dateTimeLine =>
      '${DateFormat('EEEE, d MMMM yyyy').format(_now)} · ${DateFormat('h:mm a').format(_now)}';

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _addTask() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(createdBy: TaskCreator.patient),
    );
    if (result == true) _load();
  }

  Future<void> _onTaskAction(Task task, String action) async {
    switch (action) {
      case 'done':
        await _repo.updateStatus(task.id, TaskStatus.done);
        // Cancel the alarm — patient confirmed they're done
        await NotificationService.instance.cancel(task.notifId);
        break;
      case 'in_progress':
        await _repo.updateStatus(task.id, TaskStatus.inProgress);
        // Cancel pending alarm — they've acknowledged it
        await NotificationService.instance.cancel(task.notifId);
        break;
      case 'delete':
        final confirm = await _showDeleteConfirm(task.name);
        if (confirm == true) {
          await _repo.deleteTask(task.id);
          await NotificationService.instance.cancel(task.notifId);
        }
        break;
      case 'edit':
        // TODO: open edit sheet
        break;
    }
    _load();
  }

  Future<bool?> _showDeleteConfirm(String taskName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Remove "$taskName"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Yes, Delete')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Greeting + Reality Orientation ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting line — large and warm
                  Text(
                    '$_greeting, $_patientName $_greetingEmoji',
                    style: AppTextStyles.greeting(context),
                  ),
                  const SizedBox(height: 4),
                  // Date + time line — reality orientation
                  // (per elderly_ux_spec.md Part 6.1 — not huge, just clear)
                  Text(
                    _dateTimeLine,
                    style: AppTextStyles.dateText(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.today_rounded,
                      size: 22, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Tasks",
                    style: AppTextStyles.sectionHeader(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Task list ──────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _todayTasks.isEmpty
                      ? _buildEmptyTasks()
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 180),
                          children: [
                            ...(_todayTasks.map((t) => TaskCard(
                                  task: t,
                                  isPatientView: true,
                                  onAction: (action) =>
                                      _onTaskAction(t, action),
                                ))),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AllTasksScreen()),
                              ).then((_) => _load()),
                              icon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20),
                              label: const Text('See all tasks'),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),

      // ── FAB + Emergency call ─────────────────────────────────────────────
      // Emergency call button sits above the FAB
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Emergency contact — live dialer
          _EmergencyCallButton(
            caregiverName: _caregiverName,
            caregiverPhone: _caregiverPhone,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_task_fab',
            onPressed: _addTask,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded, size: 28),
            label: const Text(
              'Add Task',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTasks() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No tasks for today!',
            style: AppTextStyles.sectionHeader(context)
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Task" to get started',
            style: AppTextStyles.cardSubtitle(context),
          ),
        ],
      ),
    );
  }
}

// ─── Emergency Call Button ──────────────────────────────────────────────────
// Dials the caregiver's phone number via the native phone app.
// Phone number is set by the caregiver in their profile.

class _EmergencyCallButton extends StatelessWidget {
  final String caregiverName;
  final String caregiverPhone;
  const _EmergencyCallButton({
    required this.caregiverName,
    required this.caregiverPhone,
  });

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: caregiverPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the phone app. Please dial $caregiverPhone manually.',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 16),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _call(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            // Soft teal — safe and reassuring, not alarming red
            color: AppColors.primaryLight.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Call $caregiverName',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
