import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_image_view.dart';
import '../../../data/db/database_helper.dart';
import '../../../services/secure_settings_service.dart';
import '../../../services/tts_service.dart';

/// Modal sheet for Dementia Reality Orientation & Reminiscence ("Who Am I?").
///
/// Designed with compassionate UX for dementia/Alzheimer's patients experiencing
/// moments of confusion, disorientation, or identity anxiety.
class IdentityCardSheet extends StatefulWidget {
  const IdentityCardSheet({super.key});

  @override
  State<IdentityCardSheet> createState() => _IdentityCardSheetState();
}

class _IdentityCardSheetState extends State<IdentityCardSheet> {
  final _secure = SecureSettingsService.instance;
  final _tts = TtsService.instance;

  String _patientName = 'Rajan';
  String _caregiverName = 'Priya';
  String _caregiverPhone = '';
  String _village = 'Barabanki';
  String _familyNotes = 'Son: Rajesh · Daughter: Meena';
  String? _avatarPath;
  bool _loading = true;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _load();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.init();
    _tts.onComplete = () {
      if (mounted) setState(() => _speaking = false);
    };
  }

  Future<void> _load() async {
    final pName = await _secure.getPatientName();
    final cName = await _secure.getAdminName();
    final cPhone = await _secure.getCaregiverPhone();
    final vil = await _secure.getPatientVillage();
    final fam = await _secure.getFamilyNotes();
    final av = await DatabaseHelper.instance.getSetting('patient_avatar_path');

    if (!mounted) return;
    setState(() {
      _patientName = pName ?? 'Rajan';
      _caregiverName = cName ?? 'Priya';
      _caregiverPhone = cPhone;
      _village = vil;
      _familyNotes = fam;
      _avatarPath = av;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakIdentity() async {
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
      return;
    }

    setState(() => _speaking = true);
    final text =
        "Hello $_patientName. You are safe. Your name is $_patientName. "
        "You are currently at home in $_village. Your caregiver $_caregiverName is looking after you today. "
        "Your family details: $_familyNotes. You have nothing to worry about. Everything is okay.";

    await _tts.speak(text);
  }

  Future<void> _callCaregiver() async {
    final uri = Uri(scheme: 'tel', path: _caregiverPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: _loading
          ? const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle bar
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),

                // Reassurance Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are safe and at home. Everything is well.',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Big Avatar & Identity Title
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.hero,
                    shape: BoxShape.circle,
                  ),
                  child: _avatarPath != null && _avatarPath!.isNotEmpty
                      ? ClipOval(
                          child: AppImageView(
                            imagePath: _avatarPath!,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            _patientName.isNotEmpty ? _patientName[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your name is $_patientName',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Home: $_village',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailItem(
                        icon: Icons.person_pin_rounded,
                        title: 'Caregiver',
                        subtitle: '$_caregiverName (Looking after you)',
                      ),
                      const Divider(height: 20),
                      _DetailItem(
                        icon: Icons.family_restroom_rounded,
                        title: 'Your Family',
                        subtitle: _familyNotes,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Voice Read Aloud Button
                ElevatedButton.icon(
                  onPressed: _speakIdentity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(
                    _speaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  label: Text(
                    _speaking ? 'Stop Reading' : '🔊 Listen to My Story',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Emergency phone button
                if (_caregiverPhone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _callCaregiver,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: AppColors.primary, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 22),
                    label: Text(
                      'Call $_caregiverName ($_caregiverPhone)',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
