import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../data/repositories/user_repository.dart';

/// Stores sensitive settings using the OS-level keystore (FlutterSecureStorage).
///
/// Auth design (prototype — no registration):
///   Two static accounts: one patient, one caregiver.
///   Username + password entered on login screen → validated here.
///   On success → UUID session token written to encrypted storage.
///   On app open → reads token; routes directly if present.
///   Logout → deletes token only; names kept for display.
class SecureSettingsService {
  SecureSettingsService._();
  static final SecureSettingsService instance = SecureSettingsService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _uuid = Uuid();

  // ── Static credentials ─────────────────────────────────────────────────────
  // Edit these to change the login. No registration needed.
  static const _patientUsername   = 'patient';
  static const _patientPassword   = 'care1234';
  static const _patientDisplayName = 'Rajan';       // shown in greeting

  static const _caregiverUsername  = 'caregiver';
  static const _caregiverPassword  = 'admin1234';
  static const _caregiverDisplayName = 'Priya';     // shown in admin dashboard
  static const _caregiverDefaultPhone = '9999999999'; // placeholder — admin can change

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const _keySessionToken   = 'session_token';
  static const _keySessionRole    = 'session_role';
  static const _keySessionLoginAt = 'session_login_at';
  static const _keyRole           = 'current_role';
  static const _keyPatientName    = 'patient_name';
  static const _keyAdminName      = 'admin_name';
  static const _keySetupDone      = 'setup_done';
  static const _keyCaregiverPhone = 'caregiver_phone';
  static const _keyPatientVillage  = 'patient_village';
  static const _keyFamilyNotes     = 'family_notes';

  // ── Session ────────────────────────────────────────────────────────────────

  /// Returns the session role ('patient' | 'admin') if a valid token exists.
  /// Called on every app open to decide whether to show LoginScreen.
  Future<String?> getSessionRole() async {
    final token = await _storage.read(key: _keySessionToken);
    if (token == null) return null;
    return _storage.read(key: _keySessionRole);
  }

  Future<String?> getSessionToken() => _storage.read(key: _keySessionToken);

  /// Validates username + password against static accounts AND registered DB users.
  /// On success: writes session token + stores display names + returns role.
  /// On failure: returns null.
  Future<String?> loginWithCredentials(String username, String password) async {
    final u = username.trim().toLowerCase();
    final p = password.trim();

    String role;
    String displayName;

    // ── 1. Check static demo accounts first ──────────────────────────────────
    if (u == _patientUsername && p == _patientPassword) {
      role = 'patient';
      displayName = _patientDisplayName;
    } else if (u == _caregiverUsername && p == _caregiverPassword) {
      role = 'admin';
      displayName = _caregiverDisplayName;
    } else {
      // ── 2. Check DB-registered users ───────────────────────────────────────
      final dbUser = await UserRepository().validateUser(u, p);
      if (dbUser == null) return null;
      role = dbUser['role'] as String;
      displayName = dbUser['display_name'] as String;
    }

    final token = _uuid.v4();
    await Future.wait([
      _storage.write(key: _keySessionToken,   value: token),
      _storage.write(key: _keySessionRole,    value: role),
      _storage.write(key: _keySessionLoginAt, value: DateTime.now().toIso8601String()),
      _storage.write(key: _keyRole,           value: role),
      _storage.write(key: _keyPatientName,    value: role == 'patient' ? displayName : _patientDisplayName),
      _storage.write(key: _keyAdminName,      value: role == 'admin'   ? displayName : _caregiverDisplayName),
      _storage.write(key: _keySetupDone,      value: 'true'),
    ]);
    return role;
  }

  /// Clears session (logout). Names + setup data intentionally kept.
  Future<void> logout() => Future.wait([
        _storage.delete(key: _keySessionToken),
        _storage.delete(key: _keySessionRole),
        _storage.delete(key: _keySessionLoginAt),
      ]);

  // ── Role ──────────────────────────────────────────────────────────────────
  Future<String?> getRole() => _storage.read(key: _keyRole);
  Future<void> setRole(String role) =>
      _storage.write(key: _keyRole, value: role);

  // ── Names ─────────────────────────────────────────────────────────────────
  Future<String?> getPatientName() => _storage.read(key: _keyPatientName);
  Future<void> setPatientName(String n) =>
      _storage.write(key: _keyPatientName, value: n);

  Future<String?> getAdminName() => _storage.read(key: _keyAdminName);
  Future<void> setAdminName(String n) =>
      _storage.write(key: _keyAdminName, value: n);

  /// Caregiver phone number shown on patient emergency button.
  /// Returns default placeholder if not yet configured by admin.
  Future<String> getCaregiverPhone() async {
    final stored = await _storage.read(key: _keyCaregiverPhone);
    return stored ?? _caregiverDefaultPhone;
  }
  Future<void> setCaregiverPhone(String phone) =>
      _storage.write(key: _keyCaregiverPhone, value: phone);

  Future<String> getPatientVillage() async {
    final stored = await _storage.read(key: _keyPatientVillage);
    return stored ?? 'Barabanki';
  }
  Future<void> setPatientVillage(String v) =>
      _storage.write(key: _keyPatientVillage, value: v);

  Future<String> getFamilyNotes() async {
    final stored = await _storage.read(key: _keyFamilyNotes);
    return stored ?? 'Son: Rajesh · Daughter: Meena';
  }
  Future<void> setFamilyNotes(String notes) =>
      _storage.write(key: _keyFamilyNotes, value: notes);

  Future<int> getHydrationCups() async {
    final stored = await _storage.read(key: 'hydration_cups');
    return int.tryParse(stored ?? '0') ?? 0;
  }
  Future<void> setHydrationCups(int count) =>
      _storage.write(key: 'hydration_cups', value: count.toString());

  // ── Generic Key-Value Storage ────────────────────────────────────────────────
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  // ── Setup flag ─────────────────────────────────────────────────────────────
  Future<bool> isSetupDone() async {
    final val = await _storage.read(key: _keySetupDone);
    return val == 'true';
  }
  Future<void> markSetupDone() =>
      _storage.write(key: _keySetupDone, value: 'true');

  // ── Full reset (dev/debug use) ─────────────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();
}
