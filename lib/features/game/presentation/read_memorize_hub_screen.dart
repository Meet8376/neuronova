import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/content_item.dart';
import '../../../data/repositories/game_repository.dart';
import 'reading_session_screen.dart';

/// Step 1 of the game: Choose category, language, and length.
/// Then fetch a random passage and go to ReadingSessionScreen.
class ReadMemorizeHubScreen extends StatefulWidget {
  const ReadMemorizeHubScreen({super.key});

  @override
  State<ReadMemorizeHubScreen> createState() => _ReadMemorizeHubScreenState();
}

class _ReadMemorizeHubScreenState extends State<ReadMemorizeHubScreen> {
  final _repo = GameRepository();

  String _language = 'en';
  ContentCategory? _category;
  ContentLength? _length;
  bool _loading = false;

  final _languageOptions = [
    {'code': 'en', 'label': '🇬🇧  English'},
    {'code': 'hi', 'label': '🇮🇳  Hindi'},
  ];

  final _categoryOptions = [
    {'value': ContentCategory.dailyConversation, 'label': 'Daily Conversation', 'icon': Icons.chat_bubble_outline_rounded},
    {'value': ContentCategory.stories, 'label': 'Stories', 'icon': Icons.auto_stories_rounded},
    {'value': ContentCategory.wisdom, 'label': 'Wisdom', 'icon': Icons.self_improvement_rounded},
  ];

  final _lengthOptions = [
    {'value': ContentLength.short, 'label': 'Short', 'desc': '1–2 sentences'},
    {'value': ContentLength.medium, 'label': 'Medium', 'desc': '3–4 sentences'},
    {'value': ContentLength.long, 'label': 'Long', 'desc': '5–6 sentences'},
  ];

  bool get _canStart => _category != null && _length != null && !_loading;

  Future<void> _startSession() async {
    if (!_canStart) return;
    setState(() => _loading = true);

    final difficulty = await _repo.getCurrentDifficulty();
    final content = await _repo.getRandomContent(
      category: _category!,
      language: _language,
      length: _length!,
      difficultyTier: difficulty,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (content == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No content found for this selection. Try a different combination.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingSessionScreen(
          content: content,
          language: _language,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Read, Memorize & Speak'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  AppColors.primaryLight.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You will read a passage, then try to say it from memory. Take your time!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Language
          _SectionLabel(label: '1. Choose language'),
          const SizedBox(height: 10),
          Row(
            children: _languageOptions.map((l) {
              final selected = _language == l['code'];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: l == _languageOptions.last ? 0 : 12),
                  child: _SelectCard(
                    label: l['label'] as String,
                    selected: selected,
                    onTap: () => setState(() => _language = l['code'] as String),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Category
          _SectionLabel(label: '2. Choose category'),
          const SizedBox(height: 10),
          ..._categoryOptions.map((c) {
            final selected = _category == c['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IconSelectCard(
                icon: c['icon'] as IconData,
                label: c['label'] as String,
                selected: selected,
                onTap: () => setState(() => _category = c['value'] as ContentCategory),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Length
          _SectionLabel(label: '3. Choose length'),
          const SizedBox(height: 10),
          Row(
            children: _lengthOptions.asMap().entries.map((entry) {
              final l = entry.value;
              final selected = _length == l['value'];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: entry.key < _lengthOptions.length - 1 ? 10 : 0),
                  child: _LengthCard(
                    label: l['label'] as String,
                    desc: l['desc'] as String,
                    selected: selected,
                    onTap: () => setState(() => _length = l['value'] as ContentLength),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),

          // Start button
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            AnimatedOpacity(
              opacity: _canStart ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                onPressed: _canStart ? _startSession : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text("Let's Begin!"),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ));
  }
}

class _SelectCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectCard({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              )),
        ),
      ),
    );
  }
}

class _IconSelectCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _IconSelectCard(
      {required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 26,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  )),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _LengthCard extends StatelessWidget {
  final String label;
  final String desc;
  final bool selected;
  final VoidCallback onTap;
  const _LengthCard(
      {required this.label, required this.desc, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                )),
            const SizedBox(height: 4),
            Text(desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: selected ? Colors.white70 : AppColors.textHint,
                )),
          ],
        ),
      ),
    );
  }
}
