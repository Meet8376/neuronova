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
    setState(() {
      _patientName = pName ?? '';
      _adminName = aName ?? '';
      _todayTasks = tasks;
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
                            icon: Icons.extension_rounded,
                            label: 'Last Score',
                            value: _latestSession != null
                                ? '${_latestSession!.scorePercent}%'
                                : '—',
                            color: AppColors.success,
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
                  Text('${session.wordMatchCount}/${session.totalWords} words matched',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textHint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
