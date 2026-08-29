import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/secure_settings_service.dart';
import '../../auth/login_screen.dart';

/// First-time setup screen — patient and admin each enter their name
/// and choose their role. This runs once; after that, the app goes
/// straight to the last-used shell.
///
/// For prototype purposes, no password is used — just a name.
/// Role-switching is possible via Profile tab later.
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  final _patientNameCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _adminNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final secure = SecureSettingsService.instance;
    await secure.setPatientName(_patientNameCtrl.text.trim());
    await secure.setAdminName(_adminNameCtrl.text.trim());
    await secure.markSetupDone();

    if (!mounted) return;

    // Names saved — now go to Login so each user authenticates with their PIN
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NeuroNova',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            )),
                        Text('Setup',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Patient name
                Text('Patient\'s name',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _patientNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 20),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Rajan Kumar',
                    prefixIcon: Icon(Icons.person_outline, size: 26),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter the patient\'s name' : null,
                ),
                const SizedBox(height: 28),

                // Admin name
                Text('Caregiver\'s name',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _adminNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 20),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Priya (daughter)',
                    prefixIcon: Icon(Icons.shield_outlined, size: 26),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter the caregiver\'s name' : null,
                ),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'After saving, each person will log in with their own PIN.',
                          style: AppTextStyles.label(context)
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Single continue button
                if (_saving)
                  const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                    label: const Text('Continue to Login'),
                    onPressed: _saveAndContinue,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
