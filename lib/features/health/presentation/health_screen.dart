import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/db/database_helper.dart';

/// Health tab — shows today's medicines and hydration.
/// Now a primary bottom-nav tab (per specs/screens/screens.md Phase 2).
///
/// [standalone] = true when used as a primary tab (gives it own Scaffold+AppBar).
/// [standalone] = false (default) when embedded inside another screen.
class HealthScreen extends StatefulWidget {
  final bool standalone;
  const HealthScreen({super.key, this.standalone = false});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with AutomaticKeepAliveClientMixin {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _doses = [];
  Map<String, dynamic>? _hydrationConfig;
  int _glassesToday = 0;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await _db.database;

    // Today's doses
    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final todayEnd =
        DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

    final doses = await db.rawQuery('''
      SELECT d.*, m.name as med_name, m.dose_note
      FROM medicine_doses d
      JOIN medicine_schedules m ON m.id = d.medicine_id
      WHERE d.scheduled_at >= ? AND d.scheduled_at <= ?
      ORDER BY d.scheduled_at ASC
    ''', [todayStart, todayEnd]);

    // Hydration
    final hydrationRows = await db.query('hydration_config', limit: 1);
    final hydConfig = hydrationRows.isEmpty ? null : hydrationRows.first;

    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final hydLogs = await db.query('hydration_logs',
        where: 'date = ?', whereArgs: [todayStr]);
    final glasses = hydLogs.isEmpty ? 0 : hydLogs.first['glass_count'] as int;

    if (!mounted) return;
    setState(() {
      _doses = doses;
      _hydrationConfig = hydConfig;
      _glassesToday = glasses;
      _loading = false;
    });
  }

  Future<void> _markDoseTaken(String doseId) async {
    final db = await _db.database;
    await db.update(
      'medicine_doses',
      {
        'status': 'taken',
        'taken_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [doseId],
    );
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
          title: const Text(
            '💊 Health',
            style: TextStyle(
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // ── Medicines section ────────────────────────────────────────────
        const _SectionHeader(
          icon: Icons.medication_rounded,
          title: 'Medicines',
          color: AppColors.info,
        ),
        const SizedBox(height: 8),
        if (_doses.isEmpty)
          const _EmptySection(
            icon: Icons.medication_outlined,
            message: 'No medicines scheduled for today',
            subtext: 'Ask your caregiver to set up your medicine schedule',
          )
        else
          ..._doses.map((d) => _MedicineDoseCard(
                dose: d,
                onTaken: () => _markDoseTaken(d['id'] as String),
              )),

        const SizedBox(height: 24),

        // ── Hydration section ────────────────────────────────────────────
        const _SectionHeader(
          icon: Icons.water_drop_rounded,
          title: 'Hydration',
          color: Color(0xFF2196F3),
        ),
        const SizedBox(height: 8),

        _HydrationCard(
          glassesToday: _glassesToday,
          dailyGoal: _hydrationConfig?['daily_goal'] as int? ?? 8,
          onAddGlass: _addGlass,
        ),
      ],
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
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
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
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 4),
          Text(subtext,
              textAlign: TextAlign.center,
              style: const TextStyle(
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

class _MedicineDoseCard extends StatelessWidget {
  final Map<String, dynamic> dose;
  final VoidCallback onTaken;
  const _MedicineDoseCard({required this.dose, required this.onTaken});

  @override
  Widget build(BuildContext context) {
    final status = dose['status'] as String;
    final isTaken = status == 'taken';
    final name = dose['med_name'] as String;
    final doseNote = dose['dose_note'] as String?;
    final scheduledAt = DateTime.fromMillisecondsSinceEpoch(dose['scheduled_at'] as int);
    final timeStr =
        '${scheduledAt.hour % 12 == 0 ? 12 : scheduledAt.hour % 12}:${scheduledAt.minute.toString().padLeft(2, '0')} ${scheduledAt.hour < 12 ? 'AM' : 'PM'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Pill icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isTaken
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.info.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTaken ? Icons.check_circle_rounded : Icons.medication_rounded,
                color: isTaken ? AppColors.success : AppColors.info,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // Name + info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: isTaken ? AppColors.textHint : AppColors.textPrimary,
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                      )),
                  if (doseNote != null && doseNote.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(doseNote,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(timeStr,
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            // Take button
            if (!isTaken)
              ElevatedButton(
                onPressed: onTaken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 44),
                  textStyle: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Taken'),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Done ✓',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? "Great job! 🎉" : "Keep drinking water!",
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: done ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$glassesToday of $dailyGoal glasses today',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
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
                label: const Text('I drank a glass of water'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Daily water goal reached!',
                      style: TextStyle(
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
