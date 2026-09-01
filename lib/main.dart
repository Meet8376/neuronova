import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/patient/presentation/patient_shell.dart';
import 'features/admin/presentation/admin_shell.dart';
import 'features/language/presentation/language_setup_screen.dart';
import 'services/secure_settings_service.dart';
import 'services/notification_service.dart';
import 'services/offline_location_service.dart';
import 'services/language_service.dart';
import 'data/repositories/task_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI for Linux / Windows / macOS desktop
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Lock to portrait — dementia patients don't need landscape
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize notification/alarm system
  await NotificationService.instance.init();

  // Initialize offline location & safe zone service
  await OfflineLocationService.instance.init();

  // Load saved language preferences before the UI renders
  await LanguageService.instance.init();

  // Migration: fix old stored caregiver name 'Priya' → 'Rahul' for existing sessions.
  // This runs once and is a no-op if name is already updated.
  final storedAdminName = await SecureSettingsService.instance.getAdminName();
  if (storedAdminName == 'Priya') {
    await SecureSettingsService.instance.setAdminName('Rahul');
  }

  // Silently pre-translate game content for all previously chosen languages
  // if internet is available. Fire-and-forget — does not block app startup.
  LanguageService.instance.prefetchAllGameLanguages();

  // Run missed-task sweep on every app open
  await TaskRepository().sweepMissedTasks();

  runApp(const NeuroNovaApp());
}

class NeuroNovaApp extends StatelessWidget {
  const NeuroNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder rebuilds MaterialApp whenever LanguageService.notifyListeners()
    // fires (i.e. when the user changes their language in Profile).
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (_, __) {
        final langCode = LanguageService.instance.currentLanguage;
        return MaterialApp(
          title: 'NeuroNova',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,

          // ── Localisation ───────────────────────────────────────────────────
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(langCode),

          home: const _AppRoot(),
        );
      },
    );
  }
}

/// Checks setup state and routes to the correct starting screen.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // ── Step 1: First-time setup ───────────────────────────────────────────
    if (!LanguageService.instance.isLanguageConfigured) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LanguageSetupScreen()),
      );
      return;
    }

    // ── Step 2: Existing session ──────────────────────────────────────────
    final secure = SecureSettingsService.instance;
    final sessionRole = await secure.getSessionRole();
    if (!mounted) return;

    if (sessionRole == 'patient') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PatientShell()),
      );
    } else if (sessionRole == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
    } else {
      // No active session → show login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.psychology_rounded, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'NeuroNova',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your memory companion',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
