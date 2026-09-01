import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import 'task_card.dart';

/// Shows ALL tasks (not just today's), grouped by date.
/// Accessible via "See all tasks" link on the dashboard.
class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  final _repo = TaskRepository();
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await _repo.getAllTasks();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  // Group tasks by date string
  Map<String, List<Task>> get _grouped {
    final map = <String, List<Task>>{};
    for (final t in _tasks) {
      final dateKey = _dateLabel(t.scheduledAt);
      map.putIfAbsent(dateKey, () => []).add(t);
    }
    return map;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(dt.year, dt.month, dt.day);
    final diff = taskDay.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEEE, d MMMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final dateKeys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _tasks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 72, color: AppColors.textHint),
                      SizedBox(height: 16),
                      Text('No tasks yet',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, i) {
                    final key = dateKeys[i];
                    final tasks = grouped[key]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            key,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        ...tasks.map((t) => TaskCard(
                              task: t,
                              isPatientView: true,
                              onAction: (action) async {
                                if (action == 'done') {
                                  await _repo.updateStatus(t.id, TaskStatus.done);
                                } else if (action == 'delete') {
                                  await _repo.deleteTask(t.id);
                                }
                                _load();
                              },
                            )),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
    );
  }
}
