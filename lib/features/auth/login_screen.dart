import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/secure_settings_service.dart';
import '../patient/presentation/patient_shell.dart';
import '../admin/presentation/admin_shell.dart';
import 'register_screen.dart';

/// Login screen — username + password form.
///
/// Static demo accounts (always available):
///   Patient:   username = patient   / password = care1234
///   Caregiver: username = caregiver / password = admin1234
///
/// DB-registered users (created via RegisterScreen) work automatically.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _secure = SecureSettingsService.instance;
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final role = await _secure.loginWithCredentials(
      _userCtrl.text,
      _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (role == null) {
      setState(() => _errorMessage = 'Wrong username or password.');
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            role == 'patient' ? const PatientShell() : const AdminShell(),
      ),
      (_) => false,
    );
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App logo ─────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CogniCare',
                            style: AppTextStyles.appTitle(context)),
                        Text('Your memory companion',
                            style: AppTextStyles.appTagline(context)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // ── Headline ──────────────────────────────────────────────────
                Text('Welcome back',
                    style: AppTextStyles.loginHeadline(context)),
                const SizedBox(height: 6),
                Text('Sign in to continue',
                    style: AppTextStyles.loginSubtitle(context)),
                const SizedBox(height: 32),

                // ── Form ──────────────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username
                      _LargeTextField(
                        controller: _userCtrl,
                        label: 'Username',
                        hint: 'Enter your username',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Enter username'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _LargeTextField(
                        controller: _passCtrl,
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Enter password'
                                : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textHint,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Error message ─────────────────────────────────────────────
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // ── Sign In button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Create Account link ───────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _goToRegister,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: "New here? "),
                          TextSpan(
                            text: 'Create Account',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Demo hint (collapsed, subtle) ─────────────────────────────
                _DemoHint(onPatient: () {
                  _userCtrl.text = 'patient';
                  _passCtrl.text = 'care1234';
                  _login();
                }, onCaregiver: () {
                  _userCtrl.text = 'caregiver';
                  _passCtrl.text = 'admin1234';
                  _login();
                }),

                const SizedBox(height: 24),

                Center(
                  child: Text(
                    'CogniCare • Prototype v0.1',
                    style: AppTextStyles.label(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Demo hint (expandable) ───────────────────────────────────────────────────

class _DemoHint extends StatefulWidget {
  final VoidCallback onPatient;
  final VoidCallback onCaregiver;
  const _DemoHint({required this.onPatient, required this.onCaregiver});
  @override
  State<_DemoHint> createState() => _DemoHintState();
}

class _DemoHintState extends State<_DemoHint> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                'Demo accounts',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DemoButton(
                  label: '👴  Patient',
                  color: AppColors.primary,
                  onTap: widget.onPatient,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DemoButton(
                  label: '🩺  Caregiver',
                  color: const Color(0xFF2E7D6B),
                  onTap: widget.onCaregiver,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DemoButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DemoButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border:
              Border.all(color: color.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              )),
        ),
      ),
    );
  }
}

// ─── Large touch-friendly text field ─────────────────────────────────────────

class _LargeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;

  const _LargeTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 24),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 17,
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          color: AppColors.textHint,
        ),
        filled: true,
        fillColor: AppColors.cardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}
