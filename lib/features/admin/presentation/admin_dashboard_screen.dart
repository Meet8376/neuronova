import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task.dart';
import '../../../data/models/game_session.dart';
import '../../../data/models/content_item.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../data/db/database_helper.dart';
import '../../../services/secure_settings_service.dart';
import '../../../services/notification_service.dart';
import '../../tasks/presentation/task_card.dart';
import '../../tasks/presentation/add_task_sheet.dart';

/// Admin (caregiver) dashboard.
/// Shows:
/// - Patient name + today's date
/// - Today's tasks (admin-visible only — no private patient tasks)
/// - Latest game session result
/// - Medicine adherence summary for today
/// - Add Task button (admin can add tasks for the patient)
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  final _taskRepo = TaskRepository();
  final _gameRepo = GameRepository();
  final _db = DatabaseHelper.instance;
  final _secure = SecureSettingsService.instance;

  String _patientName = '';
  String _adminName = '';
  List<Task> _todayTasks = [];
  List<Task> _missedTasks = [];
  GameSession? _latestSession;
  int _totalMedicines = 0;
  int _takenMedicines = 0;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pName = await _secure.getPatientName();
    final aName = await _secure.getAdminName();
    final tasks = await _taskRepo.getTodayAdminVisibleTasks();
    final latestSession = await _gameRepo.getLatestSession();
    // Sweep missed tasks first, then fetch them
    await _taskRepo.sweepMissedTasks();
    final missed = await _taskRepo.getMissedTasks(adminView: true);

    // Medicine adherence today
    final db = await _db.database;
    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final todayEnd =
        DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final allDoses = await db.query(
      'medicine_doses',
      where: 'scheduled_at >= ? AND scheduled_at <= ?',
      whereArgs: [todayStart, todayEnd],
    );
    final takenDoses = allDoses.where((d) => d['status'] == 'taken').length;

    if (!mounted) return;

    // Notify caregiver if there are new missed tasks (fires a local notification)
    if (missed.isNotEmpty && missed.length != _missedTasks.length) {
      NotificationService.instance.scheduleTaskAlarm(
        notifId: 99990001,
        taskName: '⚠️ ${missed.length} task${missed.length > 1 ? 's' : ''} missed by ${pName ?? 'patient'} today',
        scheduledAt: DateTime.now().add(const Duration(seconds: 3)),
      );
    }

    setState(() {
      _patientName = pName ?? '';
      _adminName = aName ?? '';
      _todayTasks = tasks;
      _missedTasks = missed;
      _latestSession = latestSession;
      _totalMedicines = allDoses.length;
      _takenMedicines = takenDoses;
      _loading = false;
    });
  }

  Future<void> _addTask() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(createdBy: TaskCreator.admin),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $_adminName 👋',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Patient: $_patientName",
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 17,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 15,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Admin avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _adminName.isNotEmpty
                                  ? _adminName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Missed items alert ─────────────────────────────────
                    if (_missedTasks.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEF9A9A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFD32F2F), size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  '${_missedTasks.length} Missed Item${_missedTasks.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD32F2F),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._missedTasks.take(3).map((t) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '• ${t.name}  (${DateFormat('d MMM, h:mm a').format(t.scheduledAt)})',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: Color(0xFF7B1818),
                                ),
                              ),
                            )),
                            if (_missedTasks.length > 3)
                              Text(
                                '+${_missedTasks.length - 3} more…',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  color: Color(0xFF9E2626),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Quick stats row ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.task_alt_rounded,
                            label: 'Tasks Today',
                            value: '${_todayTasks.where((t) => t.status == TaskStatus.done).length}/${_todayTasks.length}',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.medication_rounded,
                            label: 'Medicines',
                            value: '$_takenMedicines/$_totalMedicines',
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStat(
                            icon: _missedTasks.isNotEmpty
                                ? Icons.warning_amber_rounded
                                : Icons.extension_rounded,
                            label: _missedTasks.isNotEmpty ? 'Missed' : 'Last Score',
                            value: _missedTasks.isNotEmpty
                                ? '${_missedTasks.length}'
                                : (_latestSession != null ? '${_latestSession!.scorePercent}%' : '—'),
                            color: _missedTasks.isNotEmpty ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Latest game session ────────────────────────────────
                    if (_latestSession != null) ...[
                      _SectionHeader(label: 'Latest Game Session'),
                      const SizedBox(height: 8),
                      _LatestSessionCard(session: _latestSession!),
                      const SizedBox(height: 24),
                    ],

                    // ── Today's tasks ──────────────────────────────────────
                    _SectionHeader(label: "Today's Tasks for $_patientName"),
                    const SizedBox(height: 8),
                    if (_todayTasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 44, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text('No tasks scheduled for today',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 16,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    else
                      ..._todayTasks.map((t) => TaskCard(
                            task: t,
                            isPatientView: false, // no 3-dot menu for admin view
                            onAction: (_) {}, // admin can view, not edit
                          )),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 28),
        label: const Text(
          'Add Task',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ));
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _QuickStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

class _LatestSessionCard extends StatelessWidget {
  final GameSession session;
  const _LatestSessionCard({required this.session});

  Color get _scoreColor {
    if (session.scorePercent >= 70) return AppColors.success;
    if (session.scorePercent >= 40) return AppColors.warning;
    return AppColors.info;
  }

  static String _langLabel(String code) {
    switch (code.toLowerCase()) {
      case 'hi': return '🇮🇳 Hindi';
      case 'bn': return '🇧🇩 Bengali';
      case 'as': return '🇮🇳 Assamese';
      case 'ne': return '🇳🇵 Nepali';
      default:   return '🇬🇧 English';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _scoreColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${session.scorePercent}%',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _scoreColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.textTitle,
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('${session.category.displayName} • ${DateFormat('d MMM, h:mm a').format(session.playedAt)}',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Language badge — key for clinical interpretation
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _langLabel(session.language),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${session.wordMatchCount}/${session.totalWords} words',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
