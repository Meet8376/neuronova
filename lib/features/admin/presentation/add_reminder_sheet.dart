import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/care_reminder.dart';
import '../../../data/repositories/care_repository.dart';
import '../../../services/notification_service.dart';

/// Bottom sheet for adding a care reminder.
/// Adjusts available options based on the category type.
class AddReminderSheet extends StatefulWidget {
  final CareReminderType type;
  const AddReminderSheet({super.key, required this.type});

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  final _repo = CareRepository();
  final _nameCtrl = TextEditingController();

  // Default schedule modes per type
  late ReminderScheduleMode _mode;
  bool _saving = false;

  // Specific times fields
  final List<TimeOfDay> _selectedTimes = [];
  final List<String> _timeNames = [];

  // Interval fields
  double _intervalHours = 2.0;
  TimeOfDay _intervalStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _intervalEnd = const TimeOfDay(hour: 22, minute: 0);

  // Daily goal fields
  int _dailyGoal = 8;
  String _goalUnit = 'glasses';

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.type.displayName;
    // Sensible defaults per type
    switch (widget.type) {
      case CareReminderType.hydration:
        _mode = ReminderScheduleMode.interval;
        _intervalHours = 2.0;
      case CareReminderType.meal:
        _mode = ReminderScheduleMode.specificTimes;
        _selectedTimes.addAll([
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 13, minute: 0),
          const TimeOfDay(hour: 19, minute: 0),
        ]);
        _timeNames.addAll(['Breakfast', 'Lunch', 'Dinner']);
      case CareReminderType.hygiene:
        _mode = ReminderScheduleMode.specificTimes;
        _selectedTimes.add(const TimeOfDay(hour: 7, minute: 0));
        _timeNames.add('Morning routine');
      case CareReminderType.activity:
        _mode = ReminderScheduleMode.specificTimes;
        _selectedTimes.add(const TimeOfDay(hour: 7, minute: 30));
        _timeNames.add('Morning walk');
      case CareReminderType.sleep:
        _mode = ReminderScheduleMode.specificTimes;
        _selectedTimes.add(const TimeOfDay(hour: 21, minute: 30));
        _timeNames.add('Bedtime');
      case CareReminderType.eyeCare:
        _mode = ReminderScheduleMode.interval;
        _intervalHours = 6.0;
      case CareReminderType.social:
        _mode = ReminderScheduleMode.specificTimes;
        _selectedTimes.add(const TimeOfDay(hour: 17, minute: 0));
        _timeNames.add('Evening call');
      case CareReminderType.other:
        // Blank name — caregiver types their own custom health task name
        _nameCtrl.text = '';
        _mode = ReminderScheduleMode.specificTimes;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _configData {
    switch (_mode) {
      case ReminderScheduleMode.specificTimes:
        return {
          'times': _selectedTimes.map(_tod).toList(),
          'names': _timeNames,
        };
      case ReminderScheduleMode.interval:
        return {
          'interval_hours': _intervalHours,
          'start': _tod(_intervalStart),
          'end': _tod(_intervalEnd),
        };
      case ReminderScheduleMode.dailyGoal:
        return {'goal': _dailyGoal, 'unit': _goalUnit};
    }
  }

  String _tod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    if (_mode == ReminderScheduleMode.specificTimes && _selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one time.')));
      return;
    }
    setState(() => _saving = true);
    await _repo.createReminder(
      type: widget.type,
      name: _nameCtrl.text.trim(),
      scheduleMode: _mode,
      configData: _configData,
    );

    // Schedule alarms for specificTimes reminders
    if (_mode == ReminderScheduleMode.specificTimes) {
      final now = DateTime.now();
      for (final time in _selectedTimes) {
        var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        // If today's time already passed, schedule for tomorrow
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        final notifId = NotificationService.generateNotifId();
        await NotificationService.instance.scheduleTaskAlarm(
          notifId: notifId,
          taskName: _nameCtrl.text.trim(),
          scheduledAt: scheduled,
        );
      }
      // Note: interval/dailyGoal modes need a background service (future work)
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _pickTime({required int index, bool isNew = false}) async {
    final initial = isNew
        ? TimeOfDay.now()
        : (index < _selectedTimes.length ? _selectedTimes[index] : TimeOfDay.now());
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isNew) {
        _selectedTimes.add(picked);
        _timeNames.add('');
      } else {
        _selectedTimes[index] = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Text(widget.type.icon,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(
                    'Add ${widget.type.displayName} Reminder',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Name field
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Reminder name',
                      helperText: 'What should it say on the alarm?',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Schedule mode selector
                  Text(
                    'Schedule type',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ModeSelector(
                    mode: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 20),

                  // Mode-specific config
                  if (_mode == ReminderScheduleMode.specificTimes) ...[
                    Text(
                      'Times',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._selectedTimes.asMap().entries.map((e) {
                      final i = e.key;
                      final t = e.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.access_time_rounded,
                              color: AppColors.primary),
                          title: Text(
                            t.format(context),
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Label (e.g. Breakfast)',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: const TextStyle(
                                fontFamily: 'Nunito', fontSize: 14),
                            onChanged: (v) {
                              if (i < _timeNames.length) _timeNames[i] = v;
                            },
                            controller: TextEditingController(
                                text: i < _timeNames.length
                                    ? _timeNames[i]
                                    : ''),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_rounded,
                                color: AppColors.textHint),
                            onPressed: () => _pickTime(index: i),
                          ),
                          onLongPress: () => setState(() {
                            _selectedTimes.removeAt(i);
                            if (i < _timeNames.length) _timeNames.removeAt(i);
                          }),
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      onPressed: () => _pickTime(index: 0, isNew: true),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add time'),
                    ),
                  ] else if (_mode == ReminderScheduleMode.interval) ...[
                    // Interval slider
                    Text(
                      'Remind every  ${_intervalHours % 1 == 0 ? _intervalHours.toInt() : _intervalHours} hours',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Slider(
                      value: _intervalHours,
                      min: 0.5,
                      max: 6,
                      divisions: 11,
                      label: '${_intervalHours}h',
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _intervalHours = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeTile(
                            label: 'From',
                            time: _intervalStart,
                            onTap: () async {
                              final t = await showTimePicker(
                                  context: context,
                                  initialTime: _intervalStart);
                              if (t != null) {
                                setState(() => _intervalStart = t);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeTile(
                            label: 'Until',
                            time: _intervalEnd,
                            onTap: () async {
                              final t = await showTimePicker(
                                  context: context,
                                  initialTime: _intervalEnd);
                              if (t != null) {
                                setState(() => _intervalEnd = t);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Daily goal
                    Text(
                      'Daily goal',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded,
                              size: 32, color: AppColors.primary),
                          onPressed: () {
                            if (_dailyGoal > 1) {
                              setState(() => _dailyGoal--);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_dailyGoal',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              size: 32, color: AppColors.primary),
                          onPressed: () => setState(() => _dailyGoal++),
                        ),
                        const SizedBox(width: 12),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            isDense: true,
                            constraints: BoxConstraints(maxWidth: 100),
                          ),
                          controller: TextEditingController(text: _goalUnit),
                          onChanged: (v) => _goalUnit = v,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Save button
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60)),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Reminder',
                            style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mode selector chips ────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  final ReminderScheduleMode mode;
  final ValueChanged<ReminderScheduleMode> onChanged;
  const _ModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _chip(ReminderScheduleMode.specificTimes, 'At specific times', Icons.schedule_rounded),
        _chip(ReminderScheduleMode.interval, 'Every few hours', Icons.loop_rounded),
        _chip(ReminderScheduleMode.dailyGoal, 'Daily goal', Icons.flag_rounded),
      ],
    );
  }

  Widget _chip(ReminderScheduleMode m, String label, IconData icon) {
    final selected = mode == m;
    return ChoiceChip(
      avatar: Icon(icon, size: 18,
          color: selected ? Colors.white : AppColors.textSecondary),
      label: Text(label,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: selected ? Colors.white : AppColors.textPrimary)),
      selected: selected,
      onSelected: (_) => onChanged(m),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
    );
  }
}

// ─── Time tile ──────────────────────────────────────────────────────────────────

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeTile({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: AppColors.textHint)),
            Text(
              time.format(context),
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
