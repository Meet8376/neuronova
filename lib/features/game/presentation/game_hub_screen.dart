import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'read_memorize_hub_screen.dart';
import 'picture_match_screen.dart';
import 'routine_recall_screen.dart';
import 'pattern_recognition_screen.dart';

/// Game hub — entry point for all 4 cognitive games (PRD Section 6.1).
class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brain Games',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Exercise your mind every day with localized activities',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Game 1: Read, Memorize & Speak
                  _GameCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Read, Memorize & Speak',
                    subtitle: 'Read a passage, remember it, and speak aloud',
                    color: AppColors.primary,
                    available: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReadMemorizeHubScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Game 2: Picture Match (NER Memory Game)
                  _GameCard(
                    icon: Icons.grid_view_rounded,
                    title: 'Picture Match (NER)',
                    subtitle: 'Match pairs of North Eastern cultural symbols',
                    color: const Color(0xFF9C27B0),
                    available: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PictureMatchScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Game 3: Daily Routine Recall
                  _GameCard(
                    icon: Icons.schedule_rounded,
                    title: 'Daily Routine Recall',
                    subtitle: 'Arrange everyday activities in the correct time sequence',
                    color: const Color(0xFFE91E63),
                    available: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoutineRecallScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Game 4: Pattern & Motif Recognition
                  _GameCard(
                    icon: Icons.category_rounded,
                    title: 'Pattern Recognition',
                    subtitle: 'Identify and complete traditional weaving patterns',
                    color: const Color(0xFF4CAF50),
                    available: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatternRecognitionScreen()),
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

class _GameCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool available;
  final VoidCallback? onTap;

  const _GameCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: InkWell(
        onTap: available ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
