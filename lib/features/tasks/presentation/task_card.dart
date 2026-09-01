import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task.dart';
import '../../../core/extensions/l10n_ext.dart';
import 'alarm_screen.dart';

/// A single task card displayed in the dashboard.
///
/// Shows: task name, scheduled time, status badge, lock icon (if private),
/// and a checkmark button. Patient-created tasks also show a 3-dot menu.
class TaskCard extends StatelessWidget {
  final Task task;
  final bool isPatientView;
  final Function(String action) onAction; // 'done', 'in_progress', 'delete', 'edit'

  const TaskCard({
    super.key,
    required this.task,
    required this.isPatientView,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isDone ? null : () => _showActionsDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── Left: tick button ────────────────────────────────────────
              GestureDetector(
                onTap: isDone ? null : () => onAction('done'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.surfaceVariant,
                    border: Border.all(
                      color: isDone ? AppColors.success : AppColors.divider,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : Icons.check_rounded,
                    color: isDone ? AppColors.success : AppColors.divider,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // ── Middle: name + time ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Private lock icon
                        if (task.isPrivate) ...[
                          const Icon(Icons.lock_outline, size: 16, color: AppColors.textHint),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            task.name,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: isDone ? AppColors.textHint : AppColors.textPrimary,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 15, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('h:mm a').format(task.scheduledAt),
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        // "Added by admin" label
                        if (!isPatientView || task.createdBy == TaskCreator.admin) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.createdBy == TaskCreator.admin ? context.l.byCaregiver : context.l.byYou,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: AppColors.info,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Right: status badge + menu ────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(task.status),
                  // Show 3-dot menu only for patient-created tasks in patient view
                  if (isPatientView && task.isPatientOwned && !isDone)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: onAction,
                        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 22),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              const Icon(Icons.edit_outlined, size: 20),
                              const SizedBox(width: 8),
                              Text(context.l.editTask),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(context.l.yesDelete, style: const TextStyle(color: AppColors.error)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionsDialog(BuildContext context) {
    if (task.status == TaskStatus.done) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskActionsSheet(task: task, onAction: onAction),
    );
  }
}

// ─── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case TaskStatus.done:
        bg = AppColors.success.withOpacity(0.12);
        text = AppColors.success;
        label = context.l.taskStatusDone;
        icon = Icons.check_circle_rounded;
        break;
      case TaskStatus.inProgress:
        bg = AppColors.warning.withOpacity(0.12);
        text = AppColors.warning;
        label = context.l.taskStatusInProgress;
        icon = Icons.timelapse_rounded;
        break;
      case TaskStatus.missed:
        bg = AppColors.error.withOpacity(0.12);
        text = AppColors.error;
        label = context.l.taskStatusMissed;
        icon = Icons.warning_amber_rounded;
        break;
      case TaskStatus.upcoming:
        bg = AppColors.info.withOpacity(0.10);
        text = AppColors.info;
        label = context.l.taskStatusUpcoming;
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Task actions bottom sheet ────────────────────────────────────────────────

class _TaskActionsSheet extends StatelessWidget {
  final Task task;
  final Function(String) onAction;
  const _TaskActionsSheet({required this.task, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(task.name,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          _ActionButton(
            icon: Icons.task_alt_rounded,
            label: context.l.markAsDone,
            color: AppColors.success,
            onTap: () {
              Navigator.pop(context);
              onAction('done');
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.play_circle_outline_rounded,
            label: context.l.imStartingNow,
            color: AppColors.warning,
            onTap: () {
              Navigator.pop(context);
              onAction('in_progress');
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.alarm_rounded,
            label: context.l.remindMeLater,
            color: AppColors.info,
            onTap: () {
              Navigator.pop(context);
              // Open the full alarm screen in snooze-ready mode
              Navigator.push(
                context,
                AlarmScreen.route(task),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      ),
    );
  }
}
