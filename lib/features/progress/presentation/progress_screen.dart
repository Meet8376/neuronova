import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/game_session.dart';
import '../../../data/models/content_item.dart';
import '../../../data/repositories/game_repository.dart';
import '../../game/presentation/read_memorize_hub_screen.dart';
import '../../game/presentation/game_hub_screen.dart';

/// Practice tab (Patient view)
/// Shows warm, encouraging history of past sessions and practice launcher.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with AutomaticKeepAliveClientMixin {
  final _repo = GameRepository();
  List<GameSession> _sessions = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await _repo.getRecentSessions(limit: 50);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  void _openPracticeChooser() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBgWarm,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const Text(
              'Choose Practice Activity',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select what you would like to practice today:',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Colors.white,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 26),
                ),
                title: const Text('Read, Memorize & Speak',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700)),
                subtitle: const Text('Read passages aloud and test memory recall',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReadMemorizeHubScreen()),
                  ).then((_) => _load());
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Colors.white,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.extension_rounded, color: Color(0xFF9C27B0), size: 26),
                ),
                title: const Text('Brain & Memory Games',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700)),
                subtitle: const Text('Picture matching, routine recall & pattern recognition',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameHubScreen()),
                  ).then((_) => _load());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Group sessions by date for display
  List<GameSession> get _todaysSessions {
    final now = DateTime.now();
    return _sessions.where((s) {
      return s.playedAt.year == now.year &&
          s.playedAt.month == now.month &&
          s.playedAt.day == now.day;
    }).toList();
  }

  String get _encouragementMessage {
    final count = _todaysSessions.length;
    if (count == 0) return 'Ready for a brain workout today? 🌟';
    if (count == 1) return 'Great start today! Keep it up! 💪';
    if (count == 2) return 'You\'re doing wonderful today! 🌸';
    if (count >= 3) return 'Amazing effort today! You\'re a star! ⭐';
    return 'Keep going! Every practice counts! 🎯';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'Practice ✨',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_sessions.isEmpty)
              Expanded(child: _buildEmpty())
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  children: [
                    // Encouragement banner — just today's count, warm message
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.12),
                            AppColors.primaryLight.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _encouragementMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          if (_todaysSessions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _CountBadge(
                                  icon: Icons.today_rounded,
                                  label: 'Today',
                                  count: _todaysSessions.length,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                ),
                                _CountBadge(
                                  icon: Icons.history_rounded,
                                  label: 'Total',
                                  count: _sessions.length,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Past sessions — warm cards, no scores, no mistakes
                    const Text(
                      'What you practised',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ..._sessions.map((s) => _SessionCard(session: s)),

                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _openPracticeChooser,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 24),
                        label: const Text('Practice Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            const Text(
              'Ready to begin?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Practise your memory — every session helps your brain stay sharp!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                color: AppColors.textHint,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openPracticeChooser,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 26),
              label: const Text('Start Practising', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  const _CountBadge({required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final GameSession session;
  const _SessionCard({required this.session});

  int get _stars {
    if (session.scorePercent >= 70) return 3;
    if (session.scorePercent >= 40) return 2;
    return 1;
  }

  String get _warmMessage {
    if (session.scorePercent >= 70) return 'Wonderful practice!';
    if (session.scorePercent >= 40) return 'Great effort today!';
    return 'Every practice helps! ❤️';
  }

  @override
  Widget build(BuildContext context) {
    final dayStr = DateFormat('EEE, d MMM').format(session.playedAt);
    final timeStr = DateFormat('h:mm a').format(session.playedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.textTitle,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dayStr · $timeStr',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Icon(
                      i < _stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 22,
                      color: i < _stars
                          ? AppColors.accent
                          : AppColors.divider,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _warmMessage,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.category.displayName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
