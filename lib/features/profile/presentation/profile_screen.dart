import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/secure_settings_service.dart';
import '../../role_select/presentation/role_select_screen.dart';
import '../../auth/login_screen.dart';

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
  String _village = '';
  String _familyNotes = '';

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
    final vil = await _secure.getPatientVillage();
    final fam = await _secure.getFamilyNotes();
    if (!mounted) return;
    setState(() {
      _patientName = p ?? '';
      _adminName = a ?? '';
      _caregiverPhone = ph;
      _village = vil;
      _familyNotes = fam;
    });
  }

  Future<void> _logout() async {
    await _secure.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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

  Future<void> _editVillage() async {
    final ctrl = TextEditingController(text: _village);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Patient Home Village/Location',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Village / Town name',
            helperText: 'Used for Dementia Reality Orientation',
            prefixIcon: Icon(Icons.location_on_rounded),
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
      await _secure.setPatientVillage(result);
      if (!mounted) return;
      setState(() => _village = result);
    }
  }

  Future<void> _editFamilyNotes() async {
    final ctrl = TextEditingController(text: _familyNotes);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Family Members & Notes',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 2,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Family details',
            helperText: 'e.g. Son: Rajesh (lives nearby) · Daughter: Meena',
            prefixIcon: Icon(Icons.family_restroom_rounded),
          ),
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 16),
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
      await _secure.setFamilyNotes(result);
      if (!mounted) return;
      setState(() => _familyNotes = result);
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
                    decoration: const BoxDecoration(
                      gradient: AppGradients.hero,
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
                    style: const TextStyle(
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
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.12),
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

            // People & Reminiscence Details
            _Section(label: widget.isAdmin ? 'Patient Reminiscence Details' : 'Identity Details'),
            _InfoRow(
              icon: Icons.elderly,
              label: 'Patient Name',
              value: _patientName.isEmpty ? 'Not set' : _patientName,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'Home Village',
              value: _village.isEmpty ? 'Not set' : _village,
              onTap: widget.isAdmin ? _editVillage : null,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.family_restroom_rounded,
              label: 'Family Members',
              value: _familyNotes.isEmpty ? 'Not set' : _familyNotes,
              onTap: widget.isAdmin ? _editFamilyNotes : null,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.shield_outlined,
              label: 'Caregiver',
              value: _adminName.isEmpty ? 'Not set' : _adminName,
            ),
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

            // Logout
            const _Section(label: 'Account'),
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
                subtitle: const Text(
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
              const _Section(label: 'Danger Zone'),
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
          style: const TextStyle(
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
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, color: AppColors.textSecondary)),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
