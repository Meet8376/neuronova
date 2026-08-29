import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/db/database_helper.dart';
import '../../../services/adaptive_difficulty_service.dart';
import '../../../core/extensions/l10n_ext.dart';

class RoutineItem {
  final int correctOrder;
  final String title;
  final IconData icon;
  final Color color;

  const RoutineItem({
    required this.correctOrder,
    required this.title,
    required this.icon,
    required this.color,
  });
}

class RoutineRecallScreen extends StatefulWidget {
  const RoutineRecallScreen({super.key});

  @override
  State<RoutineRecallScreen> createState() => _RoutineRecallScreenState();
}

class _RoutineRecallScreenState extends State<RoutineRecallScreen> {
  final List<RoutineItem> _masterRoutine = const [
    RoutineItem(correctOrder: 1, title: 'Morning Tea & Refreshment', icon: Icons.free_breakfast_rounded, color: Colors.orange),
    RoutineItem(correctOrder: 2, title: 'Take Morning Medicines', icon: Icons.medication_rounded, color: Colors.red),
    RoutineItem(correctOrder: 3, title: 'Drink Glass of Water', icon: Icons.water_drop_rounded, color: Colors.blue),
    RoutineItem(correctOrder: 4, title: 'Walk in Garden / Courtyard', icon: Icons.directions_walk_rounded, color: Colors.green),
    RoutineItem(correctOrder: 5, title: 'Play Memory Game', icon: Icons.psychology_rounded, color: Colors.purple),
  ];

  late List<RoutineItem> _currentList;
  late DateTime _startTime;
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _currentList = List.from(_masterRoutine)..shuffle();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _currentList.removeAt(oldIndex);
      _currentList.insert(newIndex, item);
    });
  }

  Future<void> _checkAnswers() async {
    _timer?.cancel();

    int correctCount = 0;
    for (int i = 0; i < _currentList.length; i++) {
      if (_currentList[i].correctOrder == i + 1) {
        correctCount++;
      }
    }

    int scorePercent = ((correctCount / _currentList.length) * 100).round();

    // Log to SQLite
    final db = await DatabaseHelper.instance.database;
    await db.insert('game_sessions', {
      'id': const Uuid().v4(),
      'game_type': 'routine_recall',
      'played_at': DateTime.now().millisecondsSinceEpoch,
      'category': 'Daily Routine',
      'language': 'en',
      'length': 'medium',
      'difficulty_tier': 1,
      'content_id': 'routine_5_steps',
      'text_title': 'Daily Routine Recall',
      'source_text': 'Ordered ${_currentList.length} steps',
      'spoken_text': '',
      'score_percent': scorePercent,
      'word_match_count': correctCount,
      'total_words': _currentList.length,
      'recording_path': null,
    });

    final metrics = await AdaptiveDifficultyService.instance.evaluatePatientCognitiveState();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              scorePercent >= 80 ? Icons.check_circle_rounded : Icons.info_rounded,
              color: scorePercent >= 80 ? Colors.green : Colors.orange,
              size: 36,
            ),
            const SizedBox(width: 12),
            Text(
              scorePercent >= 80 ? context.l.greatSequence : context.l.goodEffortLabel,
              style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l.youPlaced(correctCount, _currentList.length, _elapsedSeconds),
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Overall Cognitive Index: ${metrics.cognitiveIndex.toStringAsFixed(1)}%\nTrend: ${metrics.trendDirection.toUpperCase()}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(context.l.backToGames, style: const TextStyle(color: Colors.white, fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(context.l.routineRecallTitle, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l.orderYourRoutine,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l.dragReorderHint,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: _currentList.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final item = _currentList[index];
                    return Card(
                      key: ValueKey(item.correctOrder),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, color: item.color, size: 28),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.drag_handle_rounded, color: AppColors.textHint),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _checkAnswers,
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                  label: Text(
                    context.l.checkRoutineSequence,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
