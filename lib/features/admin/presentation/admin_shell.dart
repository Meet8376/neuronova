import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_ext.dart';
import 'admin_dashboard_screen.dart';
import 'admin_progress_screen.dart';
import 'care_config_screen.dart';
import 'patient_management_screen.dart';
import '../../profile/presentation/profile_screen.dart';

/// Admin (caregiver & ASHA worker) shell — 5-tab bottom nav:
/// Dashboard | Care Plan | Patients & Sync | Progress | Profile
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final _pages = const [
    AdminDashboardScreen(),
    CareConfigScreen(),
    PatientManagementScreen(),
    AdminProgressScreen(),
    ProfileScreen(isAdmin: true),
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
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard_rounded),
              label: context.l.adminDashTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_outline_rounded),
              activeIcon: const Icon(Icons.favorite_rounded),
              label: context.l.careplanTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline_rounded),
              activeIcon: const Icon(Icons.people_rounded),
              label: context.l.patientsTabLabel,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined),
              activeIcon: const Icon(Icons.bar_chart_rounded),
              label: context.l.progressTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: context.l.profileTitle,
            ),
          ],
        ),
      ),
    );
  }
}
