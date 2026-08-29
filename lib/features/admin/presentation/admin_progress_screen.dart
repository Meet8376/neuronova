import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/content_item.dart';
import '../../../data/models/game_session.dart';
import '../../../data/repositories/game_repository.dart';

/// Admin-only progress/clinical view of the patient's game performance.
///
/// Shows everything the patient view hides:
///   - Actual score %, word match counts
///   - Spoken text (what they said vs what was asked)
///   - 7-day trend bar chart (drawn manually with CustomPaint)
///   - Category breakdown, current difficulty tier
///   - Full session log with expandable details
class AdminProgressScreen extends StatefulWidget {
  const AdminProgressScreen({super.key});

  @override
  State<AdminProgressScreen> createState() => _AdminProgressScreenState();
}

class _AdminProgressScreenState extends State<AdminProgressScreen>
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
    final sessions = await _repo.getRecentSessions(limit: 100);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  // ── Computed stats ───────────────────────────────────────────────────────

  int get _totalSessions => _sessions.length;

  double get _avgScore {
    if (_sessions.isEmpty) return 0;
    return _sessions.map((s) => s.scorePercent).reduce((a, b) => a + b) /
        _sessions.length;
  }

  double get _last7DayAvg {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = _sessions.where((s) => s.playedAt.isAfter(cutoff)).toList();
    if (recent.isEmpty) return 0;
    return recent.map((s) => s.scorePercent).reduce((a, b) => a + b) /
        recent.length;
  }

  int get _sessionsThisWeek {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _sessions.where((s) => s.playedAt.isAfter(cutoff)).length;
  }

  /// Returns last 7 days as [day label, avg score (0 if no session)]
  List<_DayBar> get _last7DayBars {
    final bars = <_DayBar>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final daySessions = _sessions.where((s) =>
          s.playedAt.year == day.year &&
          s.playedAt.month == day.month &&
          s.playedAt.day == day.day);
      final avg = daySessions.isEmpty
          ? 0.0
          : daySessions.map((s) => s.scorePercent).reduce((a, b) => a + b) /
              daySessions.length;
      bars.add(_DayBar(
        label: DateFormat('E').format(day), // Mon, Tue...
        score: avg,
        count: daySessions.length,
      ));
    }
    return bars;
  }

  Map<String, int> get _categoryCounts {
    final map = <String, int>{};
    for (final s in _sessions) {
      final key = s.category.displayName;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _sessions.isEmpty
                ? _buildEmpty()
                : _buildContent(),
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
            Icon(Icons.bar_chart_rounded,
                size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            const Text('No sessions yet',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Game session data will appear here once the patient starts practising.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // Header
          Text('Patient Progress',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text('Clinical view — not visible to patient',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: AppColors.textHint)),
          const SizedBox(height: 24),

          // ── Top stat cards ───────────────────────────────────────────────
          Row(
            children: [
              _StatCard(
                label: 'Total Sessions',
                value: '$_totalSessions',
                icon: Icons.psychology_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'This Week',
                value: '$_sessionsThisWeek',
                icon: Icons.calendar_today_rounded,
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: 'Avg Score (all)',
                value: '${_avgScore.round()}%',
                icon: Icons.star_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Avg Score (7d)',
                value: '${_last7DayAvg.round()}%',
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── 7-day bar chart ──────────────────────────────────────────────
          _SectionTitle('7-Day Score Trend'),
          const SizedBox(height: 12),
          _BarChart(bars: _last7DayBars),
          const SizedBox(height: 28),

          // ── Category breakdown ───────────────────────────────────────────
          if (_categoryCounts.isNotEmpty) ...[
            _SectionTitle('Activity by Category'),
            const SizedBox(height: 12),
            ..._categoryCounts.entries.map((e) => _CategoryRow(
                  label: e.key,
                  count: e.value,
                  total: _totalSessions,
                )),
            const SizedBox(height: 28),
          ],

          // ── Full session log ─────────────────────────────────────────────
          _SectionTitle('Session Log'),
          const SizedBox(height: 12),
          ..._sessions.map((s) => _SessionDetailCard(session: s)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model for bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _DayBar {
  final String label;
  final double score; // 0–100
  final int count;
  const _DayBar({required this.label, required this.score, required this.count});
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bar chart — drawn without external packages
// ─────────────────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<_DayBar> bars;
  const _BarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.map((bar) {
                final heightFraction = bar.score / 100.0;
                final hasData = bar.count > 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasData)
                          Text('${bar.score.round()}',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: hasData ? (100 * heightFraction).clamp(4.0, 100.0) : 4,
                          decoration: BoxDecoration(
                            color: hasData
                                ? _barColor(bar.score)
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: bars.map((bar) => Expanded(
              child: Text(bar.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppColors.textHint)),
            )).toList(),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Color _barColor(double score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category breakdown row
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  const _CategoryRow({required this.label, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('$count session${count == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game type → icon + color helper
// ─────────────────────────────────────────────────────────────────────────────

({IconData icon, Color color}) _gameTypeInfo(String gameType) {
  switch (gameType) {
    case 'picture_match':        return (icon: Icons.grid_view_rounded,   color: const Color(0xFF9C27B0));
    case 'routine_recall':       return (icon: Icons.schedule_rounded,     color: const Color(0xFFE91E63));
    case 'pattern_recognition':  return (icon: Icons.category_rounded,     color: const Color(0xFF4CAF50));
    default:                     return (icon: Icons.menu_book_rounded,     color: AppColors.primary); // read_memorize_speak
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language code → readable label helper
// ─────────────────────────────────────────────────────────────────────────────

String _langLabel(String code) {
  switch (code.toLowerCase()) {
    case 'hi': return '🇮🇳 Hindi';
    case 'bn': return '🇧🇩 Bengali';
    case 'as': return '🇮🇳 Assamese';
    case 'ne': return '🇳🇵 Nepali';
    default:   return '🇬🇧 English';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full session detail card — expandable
// ─────────────────────────────────────────────────────────────────────────────

class _SessionDetailCard extends StatefulWidget {
  final GameSession session;
  const _SessionDetailCard({required this.session});

  @override
  State<_SessionDetailCard> createState() => _SessionDetailCardState();
}

class _SessionDetailCardState extends State<_SessionDetailCard> {
  bool _expanded = false;

  Color get _scoreColor {
    final s = widget.session.scorePercent;
    if (s >= 75) return AppColors.success;
    if (s >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Game type icon
                  Builder(builder: (_) {
                    final info = _gameTypeInfo(s.gameType);
                    return Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: info.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(info.icon, size: 18, color: info.color),
                    );
                  }),
                  // Score circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _scoreColor.withValues(alpha: 0.1),
                      border: Border.all(color: _scoreColor, width: 2),
                    ),
                    child: Center(
                      child: Text('${s.scorePercent}%',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _scoreColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.textTitle,
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          '${s.category.displayName} · ${_langLabel(s.language)} · ${DateFormat('d MMM, h:mm a').format(s.playedAt)}',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),

              // Expanded detail
              if (_expanded) ...[
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),

                _DetailRow('Words matched', '${s.wordMatchCount} / ${s.totalWords}'),
                _DetailRow('Difficulty', 'Tier ${s.difficultyTier}'),
                _DetailRow('Length', s.length.displayName),
                const SizedBox(height: 12),

                Text('Prompt text',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(s.sourceText,
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5)),
                ),
                const SizedBox(height: 10),

                Text('What patient said',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _scoreColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _scoreColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    s.spokenText.isEmpty ? '(no speech recorded)' : s.spokenText,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: s.spokenText.isEmpty
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                        fontStyle: s.spokenText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        height: 1.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
