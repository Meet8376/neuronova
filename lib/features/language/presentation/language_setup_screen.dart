import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/language_service.dart';
import '../../auth/login_screen.dart';

/// Shown ONLY on first launch (when no language is saved in DB).
///
/// The user picks their primary language here — this sets the app locale
/// and determines which translation strategy will be used for game content.
///
/// Works fully offline (no internet needed to choose a language).
/// For Assamese and Nepali, a note explains that content translations
/// will sync when internet is first available.
class LanguageSetupScreen extends StatefulWidget {
  const LanguageSetupScreen({super.key});

  @override
  State<LanguageSetupScreen> createState() => _LanguageSetupScreenState();
}

class _LanguageSetupScreenState extends State<LanguageSetupScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;
  bool _saving = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);

    // Save language — this also calls notifyListeners() → MaterialApp rebuilds
    await LanguageService.instance.setCurrentLanguage(_selected!);

    if (!mounted) return;

    // Proceed to login — language is now saved, won't come back here
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              const SizedBox(height: 48),
              _buildHeader(),
              const SizedBox(height: 32),
              Expanded(child: _buildLanguageList()),
              _buildContinueButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.translate_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Choose Your Language',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This sets how the app speaks to you.\nYou can change it later with internet.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList() {
    final languages = LanguageService.supportedLanguages.values.toList();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: languages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _LanguageCard(
        info: languages[i],
        isSelected: _selected == languages[i].code,
        onTap: () => setState(() => _selected = languages[i].code),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _selected != null && !_saving;
    return AnimatedScale(
      scale: _selected != null ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isEnabled ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language Card
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  final LanguageInfo info;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.info,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.25),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Language names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.nativeName,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? AppColors.primary : Colors.white,
                      ),
                    ),
                    Text(
                      info.name,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Badge(
                    label: info.hasFullOfflineSupport
                        ? 'Works offline'
                        : 'Needs internet once',
                    isOffline: info.hasFullOfflineSupport,
                    isCardSelected: isSelected,
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool isOffline;
  final bool isCardSelected;

  const _Badge({
    required this.label,
    required this.isOffline,
    required this.isCardSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isOffline
        ? (isCardSelected ? const Color(0xFF1A8A5A) : Colors.green.shade700)
        : (isCardSelected ? const Color(0xFFB8860B) : Colors.amber.shade700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: isCardSelected ? 0.15 : 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: bgColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isCardSelected ? bgColor : Colors.white,
        ),
      ),
    );
  }
}
