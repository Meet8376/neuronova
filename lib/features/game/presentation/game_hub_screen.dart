import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'read_memorize_hub_screen.dart';

/// Game hub — entry point for all cognitive games.
/// Currently has: Read, Memorize & Speak (more games pluggable here).
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
                  const SizedBox(height: 4),
                  Text(
                    'Exercise your mind every day',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Read, Memorize & Speak
                  _GameCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Read, Memorize & Speak',
                    subtitle: 'Read a passage, remember it, then say it aloud',
                    color: AppColors.primary,
                    available: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReadMemorizeHubScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Placeholder games
                  _GameCard(
                    icon: Icons.grid_view_rounded,
                    title: 'Picture Match',
                    subtitle: 'Match pairs of pictures — coming soon',
                    color: const Color(0xFF9C27B0),
                    available: false,
                    onTap: null,
                  ),
                  const SizedBox(height: 16),
                  _GameCard(
                    icon: Icons.calculate_rounded,
                    title: 'Number Recall',
                    subtitle: 'Remember and repeat number sequences — coming soon',
                    color: const Color(0xFFE91E63),
                    available: false,
                    onTap: null,
                  ),
                  const SizedBox(height: 16),
                  _GameCard(
                    icon: Icons.music_note_rounded,
                    title: 'Word & Music',
                    subtitle: 'Match words to familiar songs — coming soon',
                    color: const Color(0xFF4CAF50),
                    available: false,
                    onTap: null,
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
      child: InkWell(
        onTap: available ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: color.withOpacity(available ? 0.12 : 0.07),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: available ? color : AppColors.textHint,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: available ? AppColors.textPrimary : AppColors.textHint,
                            ),
                          ),
                        ),
                        if (!available)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Soon',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    color: AppColors.textHint)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (available) ...[
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: color, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
