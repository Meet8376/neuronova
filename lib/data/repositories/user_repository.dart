import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';

/// Handles persistent user accounts stored in SQLite.
///
/// - Passwords stored as SHA-256 hashes — never plaintext.
/// - `role` is either 'patient' or 'admin' (caregiver).
class UserRepository {
  static const _uuid = Uuid();

  String _hash(String password) {
    final bytes = utf8.encode(password.trim());
    return sha256.convert(bytes).toString();
  }

  /// Returns true if username is already taken.
  Future<bool> usernameExists(String username) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Registers a new user. Returns false if username already taken.
  Future<bool> registerUser({
    required String username,
    required String displayName,
    required String password,
    required String role, // 'patient' or 'admin'
  }) async {
    final u = username.trim().toLowerCase();
    if (await usernameExists(u)) return false;

    final db = await DatabaseHelper.instance.database;
    await db.insert('users', {
      'id': _uuid.v4(),
      'username': u,
      'password_hash': _hash(password),
      'display_name': displayName.trim(),
      'role': role,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return true;
  }

  /// Returns the user row (id, username, display_name, role) if credentials
  /// match, or null on failure.
  Future<Map<String, dynamic>?> validateUser(
      String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username.trim().toLowerCase(), _hash(password)],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }
}
