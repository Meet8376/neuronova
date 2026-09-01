import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_ext.dart';
import '../../../data/models/content_item.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../services/language_service.dart';
import '../../../services/translation_service.dart';
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

  // Game-level language — defaults to the user's global app language,
  // but can be changed just for this session without affecting settings.
  late String _gameLanguage;
  ContentCategory? _category;
  ContentLength? _length;
  bool _loading = false;
  String _loadingStatus = '';

  // All supported game languages with display info
  static const _langOptions = [
    {'code': 'en', 'label': 'English',   'flag': '🇬🇧'},
    {'code': 'hi', 'label': 'Hindi',     'flag': '🇮🇳'},
    {'code': 'bn', 'label': 'Bengali',   'flag': '🇧🇩'},
    {'code': 'as', 'label': 'Assamese',  'flag': '🇮🇳'},
    {'code': 'ne', 'label': 'Nepali',    'flag': '🇳🇵'},
  ];

  final _categoryOptions = [
    {'value': ContentCategory.dailyConversation, 'label': 'Daily Conversation', 'icon': Icons.chat_bubble_outline_rounded},
    {'value': ContentCategory.stories, 'label': 'Stories', 'icon': Icons.auto_stories_rounded},
    {'value': ContentCategory.wisdom, 'label': 'Wisdom', 'icon': Icons.self_improvement_rounded},
  ];

  @override
  void initState() {
    super.initState();
    // Default to the user's current global language
    _gameLanguage = LanguageService.instance.currentLanguage;
  }

  final _lengthOptions = [
    {'value': ContentLength.short, 'label': 'Short', 'desc': '1–2 sentences'},
    {'value': ContentLength.medium, 'label': 'Medium', 'desc': '3–4 sentences'},
    {'value': ContentLength.long, 'label': 'Long', 'desc': '5–6 sentences'},
  ];

  bool get _canStart => _category != null && _length != null && !_loading;

  Future<void> _startSession() async {
    if (!_canStart) return;
    setState(() {
      _loading = true;
      _loadingStatus = 'Loading content...';
    });

    final langCode = _gameLanguage;
    final difficulty = await _repo.getCurrentDifficulty();

    // Step 1: Try to find native content in the target language.
    // Step 2: If not found, fall back to a bridge language:
    //   NE → Hindi (Devanagari script, better ML Kit quality)
    //   Others (AS, or missing categories) → English
    ContentItem? content = await _repo.getRandomContent(
      category: _category!,
      language: langCode,
      length: _length!,
      difficultyTier: difficulty,
    );

    if (content == null) {
      // Fallback: choose bridge language and fetch from there
      final fallbackLang = langCode == 'ne' ? 'hi' : 'en';
      content = await _repo.getRandomContent(
        category: _category!,
        language: fallbackLang,
        length: _length!,
        difficultyTier: difficulty,
      );
    }

    if (!mounted) return;

    if (content == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.noContentFound)),
      );
      return;
    }

    // Step 3: Only translate if the fetched content is NOT already in the target language.
    // This means native Bengali daily conversations load instantly (no translation).
    // Bengali stories/wisdom fall back to English → get translated.
    String translatedText = content.text;
    String translatedTitle = content.title;
    if (content.language != langCode) {
      setState(() => _loadingStatus = 'Translating to ${LanguageService.supportedLanguages[langCode]?.name ?? langCode}...');
      final result = await TranslationService.instance.getTranslation(
        contentId: content.id,
        sourceText: content.text,
        sourceTitle: content.title,
        targetLang: langCode,
      );
      translatedText = result.text;
      translatedTitle = result.title;
    }

    setState(() => _loading = false);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingSessionScreen(
          content: content!,
          language: langCode,
          translatedText: translatedText,
          translatedTitle: translatedTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build localized lists here so context is available
    final categoryOptions = [
      {'value': ContentCategory.dailyConversation, 'label': context.l.categoryConversation, 'icon': Icons.chat_bubble_outline_rounded},
      {'value': ContentCategory.stories,           'label': context.l.categoryStories,      'icon': Icons.auto_stories_rounded},
      {'value': ContentCategory.wisdom,            'label': context.l.categoryWisdom,       'icon': Icons.self_improvement_rounded},
    ];
    final lengthOptions = [
      {'value': ContentLength.short,  'label': context.l.lengthShort,  'desc': '1–2 sentences'},
      {'value': ContentLength.medium, 'label': context.l.lengthMedium, 'desc': '3–4 sentences'},
      {'value': ContentLength.long,   'label': context.l.lengthLong,   'desc': '5–6 sentences'},
    ];
    final langOptions = [
      {'code': 'en', 'label': context.l.langEnglish,  'flag': '🇬🇧'},
      {'code': 'hi', 'label': context.l.langHindi,    'flag': '🇮🇳'},
      {'code': 'bn', 'label': context.l.langBengali,  'flag': '🇧🇩'},
      {'code': 'as', 'label': context.l.langAssamese, 'flag': '🇮🇳'},
      {'code': 'ne', 'label': context.l.langNepali,   'flag': '🇳🇵'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l.readMemorizeTitle),
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
                    context.l.readMemorizeSubtitle,
                    style: const TextStyle(
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
          const SizedBox(height: 24),

          // ── Game language selector ────────────────────────────────────────────
          _SectionLabel(label: '1. ${context.l.choosePracticeLanguage}'),
          const SizedBox(height: 4),
          Text(
            context.l.gameLanguageHint,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: langOptions.map((l) {
              final selected = _gameLanguage == l['code'];
              return GestureDetector(
                onTap: () => setState(() => _gameLanguage = l['code'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.divider,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l['flag'] as String,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        l['label'] as String,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Category
          _SectionLabel(label: '2. ${context.l.selectCategory}'),
          const SizedBox(height: 10),
          ...categoryOptions.map((c) {
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
          _SectionLabel(label: '3. ${context.l.selectLength}'),
          const SizedBox(height: 10),
          Row(
            children: lengthOptions.asMap().entries.map((entry) {
              final l = entry.value;
              final selected = _length == l['value'];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: entry.key < lengthOptions.length - 1 ? 10 : 0),
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
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  if (_loadingStatus.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _loadingStatus,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            AnimatedOpacity(
              opacity: _canStart ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                onPressed: _canStart ? _startSession : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(context.l.startButton),
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
