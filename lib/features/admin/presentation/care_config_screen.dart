import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/care_reminder.dart';
import '../../../data/repositories/care_repository.dart';
import 'add_reminder_sheet.dart';

/// Admin screen to configure the patient's Care Plan.
/// Simple, large-touch-target UI. One card per category type.
class CareConfigScreen extends StatefulWidget {
  const CareConfigScreen({super.key});

  @override
  State<CareConfigScreen> createState() => _CareConfigScreenState();
}

class _CareConfigScreenState extends State<CareConfigScreen> {
  final _repo = CareRepository();
  List<CareReminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reminders = await _repo.getAllReminders();
    if (!mounted) return;
    setState(() {
      _reminders = reminders;
      _loading = false;
    });
  }

  Future<void> _addReminder(CareReminderType type) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReminderSheet(type: type),
    );
    if (added == true) _load();
  }

  Future<void> _toggleActive(CareReminder r) async {
    await _repo.setReminderActive(r.id, !r.isActive);
    _load();
  }

  Future<void> _delete(CareReminder r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove reminder?'),
        content: Text('Remove "${r.name}" from the care plan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteReminder(r.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Plan Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.accent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Set up reminders for your patient. These will appear on their Health screen and ring as alarms.',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Existing reminders
                if (_reminders.isNotEmpty) ...[
                  Text(
                    'Current Reminders',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._reminders.map((r) => _ReminderConfigCard(
                        reminder: r,
                        onToggle: () => _toggleActive(r),
                        onDelete: () => _delete(r),
                      )),
                  const SizedBox(height: 20),
                ],

                // Add new reminders — one button per category
                Text(
                  'Add Reminder',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: CareReminderType.values.map((type) {
                    return _AddCategoryButton(
                      type: type,
                      onTap: () => _addReminder(type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

// ─── Existing reminder card ────────────────────────────────────────────────────

class _ReminderConfigCard extends StatelessWidget {
  final CareReminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _ReminderConfigCard(
      {required this.reminder, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final active = reminder.isActive;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(reminder.type.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.name,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                  Text(
                    _scheduleDesc(reminder),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: active,
              onChanged: (_) => onToggle(),
              activeThumbColor: AppColors.primary,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 22, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _scheduleDesc(CareReminder r) {
    switch (r.scheduleMode) {
      case ReminderScheduleMode.specificTimes:
        final times = r.configData['times'] as List? ?? [];
        final names = r.configData['names'] as List? ?? [];
        if (names.isNotEmpty) return names.join(' • ');
        return times.join(' • ');
      case ReminderScheduleMode.interval:
        final h = r.configData['interval_hours'];
        final start = r.configData['start'] ?? '08:00';
        final end = r.configData['end'] ?? '22:00';
        return 'Every ${h}h ($start – $end)';
      case ReminderScheduleMode.dailyGoal:
        final goal = r.configData['goal'] ?? 8;
        final unit = r.configData['unit'] ?? 'times';
        return 'Goal: $goal $unit per day';
    }
  }
}

// ─── Add category button ────────────────────────────────────────────────────────

class _AddCategoryButton extends StatelessWidget {
  final CareReminderType type;
  final VoidCallback onTap;
  const _AddCategoryButton({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(type.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 6),
              Text(
                type.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
