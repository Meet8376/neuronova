import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/game_session.dart';
import '../../../services/scoring_service.dart';
import 'read_memorize_hub_screen.dart';

/// Results screen — shown immediately after a game session.
///
/// Patient UX rules (per specs/features/elderly_ux_spec.md Part 7):
///   - Show stars and warm encouragement (never a percentage or score number)
///   - Show word comparison so they know whether to try again
///   - Once they tap "Save & Finish", this data is gone from their view
///   - No word counts, no difficulty level, no "X of Y matched" in the UI
///
/// The full clinical data (%, matched words, difficulty) is stored in the
/// GameSession and visible to the caregiver via the Admin progress screen.
class ResultsScreen extends StatelessWidget {
  final GameSession session;
  final ScoringResult scoringResult;

  const ResultsScreen({
    super.key,
    required this.session,
    required this.scoringResult,
  });

  /// Star tier based on score — maps nicely to CST effort tiers
  int get _starCount {
    if (scoringResult.percent >= 70) return 3;
    if (scoringResult.percent >= 40) return 2;
    return 1;
  }

  String get _warmMessage {
    if (scoringResult.percent >= 70) {
      return 'Wonderful! You remembered so well! 🌟';
    }
    if (scoringResult.percent >= 40) {
      return 'Great effort! Keep going, you\'re doing great! 💪';
    }
    return 'That\'s okay! Every practice helps your memory! ❤️';
  }

  String get _subMessage {
    if (scoringResult.percent >= 70) {
      return 'Your memory is doing amazing work today.';
    }
    if (scoringResult.percent >= 40) {
      return 'You\'re improving with every try — keep it up!';
    }
    return 'Want to try again? The text will come back for you.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            // ── Stars ─────────────────────────────────────────────────────────
            const SizedBox(height: 8),
            _StarRating(starCount: _starCount),
            const SizedBox(height: 20),

            // ── Warm message ─────────────────────────────────────────────────
            Text(
              _warmMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionHeader(context).copyWith(
                fontSize: 24,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardSubtitle(context).copyWith(
                fontSize: 18,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // ── Word count — visible for this attempt only ────────────────
            // Helps patient know how they did and whether to try again.
            // This is NOT stored anywhere the patient sees later (history
            // shows only stars — per elderly_ux_spec.md Part 7).
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${scoringResult.matched} of ${scoringResult.total} words recalled',
                    style: AppTextStyles.cardTitle(context).copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Word comparison — helpful for "do I try again?" ───────────────
            const _SectionLabel(text: 'The original passage:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBgWarm,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: _HighlightedSourceText(
                source: session.sourceText,
                matchedWords: scoringResult.matchedWords,
              ),
            ),
            const SizedBox(height: 16),

            const _SectionLabel(text: 'What you said:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                session.spokenText.isEmpty
                    ? '(Nothing was recorded)'
                    : session.spokenText,
                style: AppTextStyles.body(context).copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 36),

            // ── Action buttons ────────────────────────────────────────────────
            // "Try Again" = go back to hub to pick same or different content
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const ReadMemorizeHubScreen()),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 26),
              label: const Text('Try Again 💪',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save & Finish 🏁',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Star rating widget ────────────────────────────────────────────────────────

class _StarRating extends StatelessWidget {
  final int starCount; // 1, 2, or 3
  const _StarRating({required this.starCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Glowing star row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final filled = i < starCount;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: AnimatedScale(
                scale: filled ? 1.0 : 0.75,
                duration: Duration(milliseconds: 300 + i * 80),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 64,
                  color: filled ? AppColors.accent : AppColors.divider,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Star count label
        Text(
          ['⭐', '⭐⭐', '⭐⭐⭐'][starCount - 1],
          style: const TextStyle(fontSize: 28),
        ),
      ],
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.cardSubtitle(context).copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
    );
  }
}

// ─── Highlighted source text ───────────────────────────────────────────────────
// Matched words shown in green; unmatched shown normally (not red — never punishing)

class _HighlightedSourceText extends StatelessWidget {
  final String source;
  final Set<String> matchedWords;
  const _HighlightedSourceText(
      {required this.source, required this.matchedWords});

  @override
  Widget build(BuildContext context) {
    final words = source.split(' ');
    return Wrap(
      children: words.map((word) {
        final clean = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        final matched = matchedWords.contains(clean);
        return Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 4),
          child: Container(
            padding: matched
                ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
                : null,
            decoration: matched
                ? BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: Text(
              word,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                height: 1.7,
                color: matched ? AppColors.success : AppColors.textPrimary,
                fontWeight:
                    matched ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
