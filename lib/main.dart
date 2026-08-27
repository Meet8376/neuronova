import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/patient/presentation/patient_shell.dart';
import 'features/admin/presentation/admin_shell.dart';
import 'services/secure_settings_service.dart';
import 'services/notification_service.dart';
import 'data/repositories/task_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — dementia patients don't need landscape
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize notification/alarm system
  await NotificationService.instance.init();

  // Run missed-task sweep on every app open
  await TaskRepository().sweepMissedTasks();

  runApp(const CogniCareApp());
}

class CogniCareApp extends StatelessWidget {
  const CogniCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CogniCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _AppRoot(),
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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.psychology_rounded, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'CogniCare',
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
                color: Colors.white.withOpacity(0.8),
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
