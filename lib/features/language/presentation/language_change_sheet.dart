import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/language_service.dart';

/// Bottom sheet for changing language from the Profile screen.
///
/// Returns the selected language code (String) or null if dismissed.
class LanguageChangeSheet extends StatefulWidget {
  final String currentCode;
  const LanguageChangeSheet({super.key, required this.currentCode});

  @override
  State<LanguageChangeSheet> createState() => _LanguageChangeSheetState();
}

class _LanguageChangeSheetState extends State<LanguageChangeSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentCode;
  }

  @override
  Widget build(BuildContext context) {
    final languages = LanguageService.supportedLanguages.values.toList();
    final selectedInfo = LanguageService.supportedLanguages[_selected];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Language',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Select your preferred regional language',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Language options list
            ...languages.map((info) => _SheetOption(
                  info: info,
                  isSelected: _selected == info.code,
                  isCurrent: info.code == widget.currentCode,
                  onTap: () => setState(() => _selected = info.code),
                )),

            const SizedBox(height: 18),

            // Confirm / Apply button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _selected == widget.currentCode
                      ? 'Keep Current Language'
                      : 'Apply ${selectedInfo?.nativeName ?? _selected}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final LanguageInfo info;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;

  const _SheetOption({
    required this.info,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            info.nativeName,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${info.name} (${info.script} Script)',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textHint.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
