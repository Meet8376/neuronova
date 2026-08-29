import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../services/notification_service.dart';

/// Bottom sheet for adding a new task.
/// [createdBy] is fixed at call time — patient vs admin.
class AddTaskSheet extends StatefulWidget {
  final TaskCreator createdBy;
  const AddTaskSheet({super.key, required this.createdBy});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _repo = TaskRepository();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _adminCanSee = true; // only relevant when createdBy = patient
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final notifId = NotificationService.generateNotifId();

    await _repo.createTask(
      name: _nameCtrl.text.trim(),
      scheduledAt: scheduledAt,
      createdBy: widget.createdBy,
      isPrivate: widget.createdBy == TaskCreator.patient ? !_adminCanSee : false,
      notifId: notifId,
    );

    // Schedule the real alarm
    await NotificationService.instance.scheduleTaskAlarm(
      notifId: notifId,
      taskName: _nameCtrl.text.trim(),
      scheduledAt: scheduledAt,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'New Task',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Task name
            // Admin quick-pick suggestions (game + other common tasks)
            if (widget.createdBy == TaskCreator.admin) ...[
              Text(
                'Quick pick',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _QuickChip(emoji: '🧠', label: 'Cognitive Game',    name: 'Cognitive Game Session',   nameCtrl: _nameCtrl, setState: setState),
                  _QuickChip(emoji: '💊', label: 'Take Medicine',    name: 'Take Medicine',            nameCtrl: _nameCtrl, setState: setState),
                  _QuickChip(emoji: '🚶', label: 'Walk',             name: 'Morning Walk',             nameCtrl: _nameCtrl, setState: setState),
                  _QuickChip(emoji: '📞', label: 'Family Call',     name: 'Call family member',       nameCtrl: _nameCtrl, setState: setState),
                  _QuickChip(emoji: '📝', label: 'Doctor Appt.',   name: 'Doctor appointment',       nameCtrl: _nameCtrl, setState: setState),
                  // 'Other' clears the field so caregiver can type a custom name
                  GestureDetector(
                    onTap: () {
                      setState(() => _nameCtrl.clear());
                      // A tiny delay so the field renders before requesting focus
                      Future.delayed(const Duration(milliseconds: 80), () {
                        FocusScope.of(context).requestFocus(FocusNode());
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        '✏️ Other',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'What is the task?',
                prefixIcon: Icon(Icons.task_alt_rounded, size: 24),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a task name' : null,
            ),
            const SizedBox(height: 16),

            // Date + Time row
            Row(
              children: [
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.calendar_today_rounded,
                    label: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTimeButton(
                    icon: Icons.access_time_rounded,
                    label: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Visibility toggle — only shown for patient-created tasks
            if (widget.createdBy == TaskCreator.patient)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _adminCanSee ? Icons.group_rounded : Icons.lock_outline_rounded,
                      size: 22,
                      color: _adminCanSee ? AppColors.primary : AppColors.textHint,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _adminCanSee ? 'Shared with caregiver' : 'Just me',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _adminCanSee ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                    ),
                    Switch(
                      value: _adminCanSee,
                      onChanged: (v) => setState(() => _adminCanSee = v),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),

            // Save button
            if (_saving)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded, size: 26),
                label: const Text('Add Task'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DateTimeButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
          ],
        ),
      ),
    );
  }
}

/// Quick-pick suggestion chip — fills the task name field when tapped.
/// Only shown in admin (caregiver) task creation mode.
class _QuickChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String name;
  final TextEditingController nameCtrl;
  final void Function(void Function()) setState;

  const _QuickChip({
    required this.emoji,
    required this.label,
    required this.name,
    required this.nameCtrl,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => nameCtrl.text = name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          '$emoji $label',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
