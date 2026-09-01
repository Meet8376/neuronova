import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_ext.dart';
import '../../../core/widgets/app_image_view.dart';
import '../../../data/db/database_helper.dart';
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
  final _db = DatabaseHelper.instance;
  final _picker = ImagePicker();

  String _patientName = '';
  String _adminName = '';
  String _caregiverPhone = '';
  String? _avatarPath;

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
    final av = await _db.getSetting(widget.isAdmin ? 'admin_avatar_path' : 'patient_avatar_path');
    if (!mounted) return;
    setState(() {
      _patientName = p ?? '';
      _adminName = a ?? '';
      _caregiverPhone = ph;
      _avatarPath = av;
    });
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Profile Photo',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
              onTap: () async {
                Navigator.pop(ctx);
                _processPickedImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              ),
              title: const Text('Take a Photo with Camera', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
              onTap: () async {
                Navigator.pop(ctx);
                _processPickedImage(ImageSource.camera);
              },
            ),
            if (_avatarPath != null && _avatarPath!.isNotEmpty) ...[
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                ),
                title: const Text('Remove Photo', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _db.setSetting(widget.isAdmin ? 'admin_avatar_path' : 'patient_avatar_path', '');
                  _load();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _processPickedImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 88,
      );
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final avatarsDir = Directory(p.join(appDir.path, 'avatars'));
        if (!await avatarsDir.exists()) await avatarsDir.create(recursive: true);
        final ext = p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.jpg';
        final rolePrefix = widget.isAdmin ? 'admin' : 'patient';
        final destPath = p.join(avatarsDir.path, 'avatar_${rolePrefix}_${DateTime.now().millisecondsSinceEpoch}$ext');
        final savedFile = await File(picked.path).copy(destPath);

        await _db.setSetting(
          widget.isAdmin ? 'admin_avatar_path' : 'patient_avatar_path',
          savedFile.path,
        );
        _load();
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
    }
  }

  /// Clears UUID session token → returns to LoginScreen.
  /// Names and task/game history are preserved.
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.cardBgWarm,
        title: Text(
          context.l.logoutButton,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          context.l.logoutConfirm,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.l.cancelButton,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.l.logoutButton,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _secure.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _changeLanguage() async {
    final currentLang = LanguageService.instance.currentLanguage;
    final newLang = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageChangeSheet(currentCode: currentLang),
    );

    if (newLang != null && newLang != currentLang) {
      await LanguageService.instance.setCurrentLanguage(newLang);
      if (!mounted) return;

      // Fire-and-forget: pre-translate all game content for the new language.
      LanguageService.instance.preTranslateIfOnline(newLang);

      final langName =
          LanguageService.supportedLanguages[newLang]?.nativeName ?? newLang;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Language changed to $langName',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetSetup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.cardBgWarm,
        title: Text(
          context.l.resetTitle,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          context.l.resetAppConfirm,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.l.cancelButton,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.l.resetAppSetup,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.cardBgWarm,
        title: Text(
          context.l.emergencyContactLabel,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l.phoneNumberLabel,
            helperText: context.l.phoneHelper,
            prefixIcon: const Icon(Icons.phone_rounded),
          ),
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.l.cancelButton,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.l.saveButton,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
              ),
            ),
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
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

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
                  // Avatar with upload option
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: _avatarPath != null && _avatarPath!.isNotEmpty
                              ? ClipOval(
                                  child: AppImageView(
                                    imagePath: _avatarPath!,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 42,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName.isEmpty ? context.l.profileTitle : displayName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                          widget.isAdmin
                              ? Icons.shield_outlined
                              : Icons.elderly,
                          size: 16,
                          color: widget.isAdmin
                              ? AppColors.accent
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isAdmin
                              ? context.l.caregiverViewBadge
                              : context.l.patientViewBadge,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.isAdmin
                              ? AppColors.accent
                              : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // People section
            _Section(label: context.l.profileTitle),
            _InfoRow(
              icon: Icons.elderly,
              label: context.l.patientNameLabel,
              value: _patientName.isEmpty ? context.l.notSet : _patientName,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.shield_outlined,
              label: context.l.caregiverNameLabel,
              value: _adminName.isEmpty ? context.l.notSet : _adminName,
            ),
            // Admin-only: editable emergency contact number
            if (widget.isAdmin) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.phone_rounded,
                label: context.l.emergencyContactLabel,
                value:
                    _caregiverPhone.isEmpty ? context.l.notSet : _caregiverPhone,
                onTap: _editPhone,
              ),
            ],
            const SizedBox(height: 20),

            // Language Settings
            _Section(label: context.l.languageSettingsTitle),
            ListenableBuilder(
              listenable: LanguageService.instance,
              builder: (context, _) {
                final currentCode = LanguageService.instance.currentLanguage;
                final info = LanguageService.supportedLanguages[currentCode];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    onTap: _changeLanguage,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      info?.nativeName ?? currentCode,
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        context.l.primaryLanguageLabel,
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${info?.name ?? ''} (${info?.script ?? ''})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Account / Logout
            _Section(label: context.l.accountSection),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.primary, size: 22),
                ),
                title: Text(
                  context.l.logoutButton,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  context.l.returnToLogin,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textHint,
                ),
                onTap: _logout,
              ),
            ),
            const SizedBox(height: 20),

            // Danger Zone — caregiver only
            if (widget.isAdmin) ...[
              _Section(label: context.l.dangerZone),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: AppColors.error, size: 22),
                  ),
                  title: Text(
                    context.l.resetAppSetup,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: Text(
                    context.l.clearNamesSetupHint,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                    ),
                  ),
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
            fontWeight: FontWeight.w800,
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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.edit_rounded,
                    size: 16, color: AppColors.textHint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
