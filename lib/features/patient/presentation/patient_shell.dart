import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../tasks/presentation/patient_dashboard_screen.dart';
import '../../health/presentation/health_screen.dart';
import '../../game/presentation/game_hub_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../profile/presentation/profile_screen.dart';

/// Patient shell — 5-tab bottom nav:
/// Home | Health | Games | Practice | Profile
///
/// Per specs/screens/screens.md:
///   - "Home" replaces "Dashboard" — warmer word
///   - "Practice" replaces "Progress" — forward-looking, not backward
///   - Health is now a primary tab, not buried as a sub-tab under Home
///   - FAB (+ Add Task) lives ONLY in PatientDashboardScreen (Home tab)
///
/// Uses IndexedStack to preserve scroll + state when switching tabs.
class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _currentIndex = 0;

  // Keep all pages alive when switching tabs
  final _pages = const [
    PatientDashboardScreen(),   // Home
    HealthScreen(standalone: true),  // Health — now standalone (has own Scaffold)
    GameHubScreen(),            // Games
    ProgressScreen(),           // Practice
    ProfileScreen(isAdmin: false), // Profile
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
          type: BottomNavigationBarType.fixed, // needed for 5+ items to show labels
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
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Practice',
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
