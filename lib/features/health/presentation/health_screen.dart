import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/care_reminder.dart';
import '../../../data/repositories/care_repository.dart';
import '../../../data/db/database_helper.dart';
import '../../../core/extensions/l10n_ext.dart';

/// Health tab — shows today's medicines, hydration, and care plan routines.
/// Primary bottom-nav tab for patients.
class HealthScreen extends StatefulWidget {
  final bool standalone;
  const HealthScreen({super.key, this.standalone = false});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with AutomaticKeepAliveClientMixin {
  final _careRepo = CareRepository();
  final _db = DatabaseHelper.instance;

  List<CareLog> _allLogs = [];
  int _glassesToday = 0;
  int _dailyWaterGoal = 8;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Sync active care plan reminders to today's logs/tasks
    await _careRepo.syncCarePlanToTodayTasks();

    final logs = await _careRepo.getTodayLogs();
    final reminders = await _careRepo.getActiveReminders();

    // Hydration goal from active hydration reminder if present
    int hydGoal = 8;
    for (final r in reminders) {
      if (r.type == CareReminderType.hydration) {
        if (r.scheduleMode == ReminderScheduleMode.dailyGoal) {
          final g = r.configData['goal'] ?? r.configData['target_glasses'];
          if (g is int && g > 0) hydGoal = g;
        }
      }
    }

    // Hydration glasses from hydration_logs table
    final db = await _db.database;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final hydRows = await db.query(
      'hydration_logs',
      where: 'date = ?',
      whereArgs: [todayStr],
    );
    final glasses = hydRows.isEmpty ? 0 : hydRows.first['glass_count'] as int;

    if (!mounted) return;
    setState(() {
      _allLogs = logs;
      _glassesToday = glasses;
      _dailyWaterGoal = hydGoal;
      _loading = false;
    });
  }

  Future<void> _markLogDone(String logId) async {
    await _careRepo.updateLogStatus(logId, 'done');
    _load();
  }

  Future<void> _addGlass() async {
    final db = await _db.database;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await db.insert(
      'hydration_logs',
      {'date': todayStr, 'glass_count': _glassesToday + 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final content = _buildContent();
    if (widget.standalone) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          title: Text(
            '💊 ${context.l.healthTitle}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          backgroundColor: AppColors.scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: AppColors.scaffoldBg,
        ),
        body: content,
      );
    }
    return content;
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final medLogs = _allLogs
        .where((l) => l.type == CareReminderType.medication)
        .toList();
    final routineLogs = _allLogs
        .where((l) =>
            l.type != CareReminderType.medication &&
            l.type != CareReminderType.hydration)
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // ── Medicines Section ──────────────────────────────────────────
          _SectionHeader(
            icon: Icons.medication_rounded,
            title: context.l.medicines,
            color: AppColors.info,
          ),
          const SizedBox(height: 8),
          if (medLogs.isEmpty)
            _EmptySection(
              icon: Icons.medication_outlined,
              message: context.l.noMedicinesScheduled,
              subtext: context.l.askCaregiverMedicine,
            )
          else
            ...medLogs.map((log) => _CareLogCard(
                  log: log,
                  onDone: () => _markLogDone(log.id),
                )),

          const SizedBox(height: 24),

          // ── Hydration Section ──────────────────────────────────────────
          _SectionHeader(
            icon: Icons.water_drop_rounded,
            title: context.l.hydration,
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 8),
          _HydrationCard(
            glassesToday: _glassesToday,
            dailyGoal: _dailyWaterGoal,
            onAddGlass: _addGlass,
          ),

          // ── Daily Care Routines Section (if any configured) ─────────────
          if (routineLogs.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionHeader(
              icon: Icons.favorite_rounded,
              title: 'Daily Care Routines',
              color: AppColors.accent,
            ),
            const SizedBox(height: 8),
            ...routineLogs.map((log) => _CareLogCard(
                  log: log,
                  onDone: () => _markLogDone(log.id),
                )),
          ],
        ],
      ),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Empty state for a section ────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtext;
  const _EmptySection({required this.icon, required this.message, required this.subtext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 4),
          Text(subtext,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textHint,
              )),
        ],
      ),
    );
  }
}

// ─── Medicine dose card ────────────────────────────────────────────────────────

// ─── Care Log Card ─────────────────────────────────────────────────────────────

class _CareLogCard extends StatelessWidget {
  final CareLog log;
  final VoidCallback onDone;
  const _CareLogCard({required this.log, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final isDone = log.status == 'done';
    final name = log.reminderName;
    final scheduledAt = log.scheduledAt;
    final timeStr =
        '${scheduledAt.hour % 12 == 0 ? 12 : scheduledAt.hour % 12}:${scheduledAt.minute.toString().padLeft(2, '0')} ${scheduledAt.hour < 12 ? 'AM' : 'PM'}';

    final isMedication = log.type == CareReminderType.medication;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.success.withOpacity(0.12)
                    : (isMedication
                        ? AppColors.info.withOpacity(0.10)
                        : AppColors.accent.withOpacity(0.10)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 28)
                    : Text(log.type.icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            // Name + info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color:
                          isDone ? AppColors.textHint : AppColors.textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: !isDone
                  ? ElevatedButton(
                      key: const ValueKey('action_btn'),
                      onPressed: onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 44),
                        textStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(isMedication
                          ? context.l.takenButton
                          : context.l.markAsDone),
                    )
                  : Container(
                      key: const ValueKey('done_badge'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        context.l.doneMark,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hydration card ────────────────────────────────────────────────────────────

class _HydrationCard extends StatelessWidget {
  final int glassesToday;
  final int dailyGoal;
  final VoidCallback onAddGlass;
  const _HydrationCard({
    required this.glassesToday,
    required this.dailyGoal,
    required this.onAddGlass,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (glassesToday / dailyGoal).clamp(0.0, 1.0);
    final done = glassesToday >= dailyGoal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        done ? context.l.hydrationGreat : context.l.hydrationKeepGoing,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: done ? AppColors.success : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l.glassesOfDay(glassesToday, dailyGoal),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Big water count
                Text(
                  '$glassesToday',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: done ? AppColors.success : const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                    done ? AppColors.success : const Color(0xFF2196F3)),
              ),
            ),

            // Glass icons
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                dailyGoal,
                (i) => Icon(
                  i < glassesToday ? Icons.water_drop_rounded : Icons.water_drop_outlined,
                  size: 30,
                  color: i < glassesToday
                      ? const Color(0xFF2196F3)
                      : AppColors.divider,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Add glass button
            if (!done)
              ElevatedButton.icon(
                onPressed: onAddGlass,
                icon: const Icon(Icons.add_rounded, size: 24),
                label: Text(context.l.drankGlass),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      context.l.dailyGoalReached,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
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
