import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/connectivity.dart';
import '../../../services/language_service.dart';
import '../../../services/secure_settings_service.dart';
import '../../role_select/presentation/role_select_screen.dart';
import '../../auth/login_screen.dart';
import '../../language/presentation/language_change_sheet.dart';

/// Profile tab — shows name, role, switch role button, settings.
/// Shared by patient and admin (just different current-role display).
class ProfileScreen extends StatefulWidget {
  final bool isAdmin;
  const ProfileScreen({super.key, required this.isAdmin});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final _secure = SecureSettingsService.instance;
  String _patientName = '';
  String _adminName = '';
  String _caregiverPhone = '';
  String _currentLangCode = LanguageService.instance.currentLanguage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _secure.getPatientName();
    final a = await _secure.getAdminName();
    final ph = await _secure.getCaregiverPhone();
    if (!mounted) return;
    setState(() {
      _patientName = p ?? '';
      _adminName = a ?? '';
      _caregiverPhone = ph;
      _currentLangCode = LanguageService.instance.currentLanguage;
    });
  }

  /// Clears UUID session token → returns to LoginScreen.
  /// Names and task/game history are preserved.
  Future<void> _logout() async {
    await _secure.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _changeLanguage() async {
    // Language ARBs are compiled into the app — no internet needed
    final newLang = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageChangeSheet(currentCode: _currentLangCode),
    );

    if (newLang != null && newLang != _currentLangCode) {
      await LanguageService.instance.setCurrentLanguage(newLang);
      if (!mounted) return;
      setState(() => _currentLangCode = newLang);
      // No need to restart — ListenableBuilder in main.dart already rebuilds MaterialApp
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Language changed to ${LanguageService.supportedLanguages[newLang]?.name ?? newLang}',
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _resetSetup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset App?'),
        content: const Text(
            'This will erase all names and setup. Task and game history will be kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirm != true) return;
    await _secure.clearAll();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
      (_) => false,
    );
  }

  Future<void> _editPhone() async {
    final ctrl = TextEditingController(text: _caregiverPhone);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Contact Number',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            helperText: 'Patients use this for the "Call for Help" button',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _secure.setCaregiverPhone(result);
      if (!mounted) return;
      setState(() => _caregiverPhone = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final displayName = widget.isAdmin ? _adminName : _patientName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),

            // Profile header
            Center(
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName.isEmpty ? 'Profile' : displayName,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.isAdmin
                          ? AppColors.accent.withOpacity(0.15)
                          : AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isAdmin ? Icons.shield_outlined : Icons.elderly,
                          size: 16,
                          color: widget.isAdmin ? AppColors.accent : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isAdmin ? 'Caregiver View' : 'Patient View',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.isAdmin ? AppColors.accent : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // People section
            _Section(label: 'People'),
            _InfoRow(
              icon: Icons.elderly,
              label: 'Patient',
              value: _patientName.isEmpty ? 'Not set' : _patientName,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.shield_outlined,
              label: 'Caregiver',
              value: _adminName.isEmpty ? 'Not set' : _adminName,
            ),
            // Admin-only: editable emergency contact number
            if (widget.isAdmin) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.phone_rounded,
                label: 'Emergency number',
                value: _caregiverPhone.isEmpty ? 'Not set' : _caregiverPhone,
                onTap: _editPhone,
              ),
            ],
            const SizedBox(height: 20),

            // Language
            _Section(label: 'Language'),
            Builder(builder: (context) {
              final info = LanguageService.supportedLanguages[_currentLangCode];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.translate_rounded,
                      color: AppColors.primary, size: 26),
                  title: Text(
                    info?.nativeName ?? _currentLangCode,
                    style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    info?.name ?? '',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: AppColors.textHint),
                  ),
                  trailing: TextButton.icon(
                    onPressed: _changeLanguage,
                    icon: const Icon(Icons.wifi_rounded, size: 16),
                    label: const Text('Change'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(
                          fontFamily: 'Nunito', fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Logout
            _Section(label: 'Account'),
            Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.logout_rounded,
                    color: AppColors.primary, size: 28),
                title: const Text('Log Out',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Return to the login screen',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppColors.textHint),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 18, color: AppColors.textHint),
                onTap: _logout,
              ),
            ),
            const SizedBox(height: 20),

            // Danger Zone — caregiver only
            if (widget.isAdmin) ...[
              _Section(label: 'Danger Zone'),
              Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.refresh_rounded,
                      color: AppColors.error, size: 28),
                  title: const Text('Reset App Setup',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error)),
                  subtitle: const Text(
                      'Clear names and setup — keeps game history',
                      style: TextStyle(
                          fontFamily: 'Nunito', fontSize: 13)),
                  onTap: _resetSetup,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 0.8,
          )),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 16, color: AppColors.textSecondary)),
              const Spacer(),
              Text(value,
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.edit_rounded, size: 16, color: AppColors.textHint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
