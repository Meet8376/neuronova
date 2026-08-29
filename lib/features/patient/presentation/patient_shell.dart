import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../tasks/presentation/patient_dashboard_screen.dart';
import '../../health/presentation/health_screen.dart';
import '../../game/presentation/game_hub_screen.dart';
import '../../profile/presentation/profile_screen.dart';

/// Patient shell — 4-tab bottom nav:
/// Home | Health | Games | Profile
///
/// "Practice" tab removed — session history is accessible from inside the
/// Games tab (ReadMemorizeHubScreen shows history, and the game hub gives
/// a "See past sessions" shortcut). Removing it reduces cognitive load
/// for elderly users and avoids over-promoting one specific game.
class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _currentIndex = 0;

  final _pages = const [
    PatientDashboardScreen(),           // Home
    HealthScreen(standalone: true),     // Health
    GameHubScreen(),                    // Games (session history accessible from here)
    ProfileScreen(isAdmin: false),      // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.extension_outlined),
              activeIcon: Icon(Icons.extension_rounded),
              label: 'Games',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
