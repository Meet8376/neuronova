import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/db/database_helper.dart';
import '../../../services/adaptive_difficulty_service.dart';

class PatternQuestion {
  final List<IconData> sequence;
  final IconData correctAnswer;
  final List<IconData> choices;
  final String title;

  const PatternQuestion({
    required this.sequence,
    required this.correctAnswer,
    required this.choices,
    required this.title,
  });
}

class PatternRecognitionScreen extends StatefulWidget {
  const PatternRecognitionScreen({super.key});

  @override
  State<PatternRecognitionScreen> createState() => _PatternRecognitionScreenState();
}

class _PatternRecognitionScreenState extends State<PatternRecognitionScreen> {
  final List<PatternQuestion> _questions = const [
    PatternQuestion(
      title: 'NER Weaving Pattern 1',
      sequence: [
        Icons.crop_square_rounded,
        Icons.change_history_rounded,
        Icons.crop_square_rounded,
        Icons.change_history_rounded,
      ],
      correctAnswer: Icons.crop_square_rounded,
      choices: [
        Icons.crop_square_rounded,
        Icons.circle_outlined,
        Icons.star_rounded,
      ],
    ),
    PatternQuestion(
      title: 'NER Bamboo Craft Motif',
      sequence: [
        Icons.diamond_rounded,
        Icons.hexagon_rounded,
        Icons.diamond_rounded,
        Icons.hexagon_rounded,
      ],
      correctAnswer: Icons.diamond_rounded,
      choices: [
        Icons.circle_rounded,
        Icons.diamond_rounded,
        Icons.square_rounded,
      ],
    ),
    PatternQuestion(
      title: 'Assamese Floral Pattern',
      sequence: [
        Icons.filter_vintage_rounded,
        Icons.spa_rounded,
        Icons.filter_vintage_rounded,
        Icons.spa_rounded,
      ],
      correctAnswer: Icons.filter_vintage_rounded,
      choices: [
        Icons.spa_rounded,
        Icons.filter_vintage_rounded,
        Icons.park_rounded,
      ],
    ),
  ];

  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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

  void _onAnswerSelected(IconData chosen) {
    final currentQ = _questions[_currentIndex];
    if (chosen == currentQ.correctAnswer) {
      _correctAnswers++;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishGame();
    }
  }

  Future<void> _finishGame() async {
    _timer?.cancel();

    int scorePercent = ((_correctAnswers / _questions.length) * 100).round();

    // Log to SQLite
    final db = await DatabaseHelper.instance.database;
    await db.insert('game_sessions', {
      'id': const Uuid().v4(),
      'game_type': 'pattern_recognition',
      'played_at': DateTime.now().millisecondsSinceEpoch,
      'category': 'Pattern Recognition',
      'language': 'en',
      'length': 'short',
      'difficulty_tier': 1,
      'content_id': 'pattern_3_questions',
      'text_title': 'Pattern & Motif Recall',
      'source_text': 'Completed ${_questions.length} pattern puzzles',
      'spoken_text': '',
      'score_percent': scorePercent,
      'word_match_count': _correctAnswers,
      'total_words': _questions.length,
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
            const Icon(Icons.stars_rounded, color: Colors.purple, size: 36),
            const SizedBox(width: 12),
            const Text('Pattern Completed!', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You solved $_correctAnswers out of ${_questions.length} pattern sequences correctly in ${_elapsedSeconds}s!',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Cognitive Index: ${metrics.cognitiveIndex.toStringAsFixed(1)}%\nRecommended Tier: Tier ${metrics.currentTier}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
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
            child: const Text('Back to Games', style: TextStyle(color: Colors.white, fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Pattern Recognition', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1}/${_questions.length}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${_elapsedSeconds}s',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                q.title,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Look at the pattern below. Which motif comes next?',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Pattern sequence display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ...q.sequence.map((icon) => Icon(icon, size: 40, color: AppColors.primary)),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              Text(
                'Select the correct motif:',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: q.choices.map((choice) {
                  return GestureDetector(
                    onTap: () => _onAnswerSelected(choice),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(choice, size: 44, color: AppColors.primary),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
