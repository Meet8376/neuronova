import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/game_session.dart';
import '../../../data/models/content_item.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../core/extensions/l10n_ext.dart';
import '../../game/presentation/read_memorize_hub_screen.dart';

/// Practice tab (Patient view) — formerly called "Progress"
/// Shows warm, encouraging history of past sessions.
///
/// CRITICAL RULE (per specs/features/elderly_ux_spec.md Part 7):
///   - Session cards show: date, stars (based on score tier), warm message, category
///   - Session cards do NOT show: score %, word counts, what they said, difficulty number
///   - Once a patient leaves the game screen, past mistakes are NEVER shown again
///   - Admin sees full clinical data on the admin progress view
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

  // Group sessions by date for display
  List<GameSession> get _todaysSessions {
    final now = DateTime.now();
    return _sessions.where((s) {
      return s.playedAt.year == now.year &&
          s.playedAt.month == now.month &&
          s.playedAt.day == now.day;
    }).toList();
  }

  String _encouragementMessage(BuildContext context) {
    return context.l.practiseMemoryHint; // Using the localized hint for encouragement
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                context.l.practiceTitle,
                style: const TextStyle(
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
                            AppColors.primary.withOpacity(0.12),
                            AppColors.primaryLight.withOpacity(0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _encouragementMessage(context),
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
                                  label: context.l.todayLabel,
                                  count: _todaysSessions.length,
                                ),
                                Container(
                                  width: 1, height: 40,
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                                _CountBadge(
                                  icon: Icons.history_rounded,
                                  label: context.l.totalLabel,
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
                    Text(
                      context.l.whatYouPractised,
                      style: const TextStyle(
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReadMemorizeHubScreen()),
                        ).then((_) => _load()),
                        icon: const Icon(Icons.menu_book_rounded, size: 24),
                        label: Text(context.l.practiceAgain),
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
            Icon(Icons.psychology_rounded, size: 80, color: AppColors.primary.withOpacity(0.4)),
            const SizedBox(height: 20),
            Text(
              context.l.readyToBegin,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l.practiseMemoryHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                color: AppColors.textHint,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReadMemorizeHubScreen()),
              ).then((_) => _load()),
              icon: const Icon(Icons.menu_book_rounded, size: 24),
              label: Text(context.l.startPractising),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Count badge ────────────────────────────────────────────────────────────────

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
              style: TextStyle(
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
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

// ─── Session card (stars + warm message — NO score, NO word count) ─────────────

class _SessionCard extends StatelessWidget {
  final GameSession session;
  const _SessionCard({required this.session});

  int get _stars {
    if (session.scorePercent >= 70) return 3;
    if (session.scorePercent >= 40) return 2;
    return 1;
  }

  String _warmMessage(BuildContext context) {
    if (session.scorePercent >= 70) return context.l.warmMessage3Stars;
    if (session.scorePercent >= 40) return context.l.warmMessage2Stars;
    return context.l.warmMessage1Star;
  }

  @override
  Widget build(BuildContext context) {
    // Format: "Tuesday, 26 Aug · 3:45 PM"
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
            // Top row: game icon + title + stars
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
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
                // Stars — warm, non-numeric indicator
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
            // Warm message + category pill
            Row(
              children: [
                Expanded(
                  child: Text(
                    _warmMessage(context),
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
