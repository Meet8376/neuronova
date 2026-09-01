import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/secure_settings_service.dart';

class HydrationSheet extends StatefulWidget {
  const HydrationSheet({super.key});

  @override
  State<HydrationSheet> createState() => _HydrationSheetState();
}

class _HydrationSheetState extends State<HydrationSheet> {
  final _secure = SecureSettingsService.instance;
  int _cups = 0;
  final int _goal = 6;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final count = await _secure.getHydrationCups();
    if (!mounted) return;
    setState(() {
      _cups = count;
      _loading = false;
    });
  }

  Future<void> _addCup() async {
    final newCount = _cups + 1;
    await _secure.setHydrationCups(newCount);
    if (!mounted) return;
    setState(() => _cups = newCount);
  }

  Future<void> _reset() async {
    await _secure.setHydrationCups(0);
    if (!mounted) return;
    setState(() => _cups = 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_cups / _goal).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: _loading
          ? const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),

                // Icon & Title
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF81D4FA), width: 2),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Color(0xFF0288D1),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Daily Hydration Tracker',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Drinking water helps keep your brain refreshed and focused',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Cup Count Display & Progress Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFB3E5FC)),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_drink_rounded, color: Color(0xFF0288D1), size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Water Intake',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$_cups / $_goal Glasses',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0288D1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: const Color(0xFFE0F7FA),
                          color: const Color(0xFF0288D1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cup icons grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_goal, (index) {
                          final drank = index < _cups;
                          return Icon(
                            drank ? Icons.water_drop_rounded : Icons.water_drop_outlined,
                            size: 28,
                            color: drank ? const Color(0xFF0288D1) : AppColors.divider,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Button: Add a glass
                ElevatedButton.icon(
                  onPressed: _addCup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
                  label: const Text(
                    '🥛 I Drank a Glass of Water!',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),

                if (_cups > 0) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _reset,
                    child: const Text(
                      'Reset count for today',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
