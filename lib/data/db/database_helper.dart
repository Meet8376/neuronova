import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Everything here lives entirely on-device. No server calls anywhere.
/// The caregiver dashboard can sync it later, but the app never depends
/// on that sync happening — offline-first by design (PS requirement).
///
/// Schema versioning: always implement onUpgrade from day one.
/// Adding columns later without onUpgrade causes crashes on existing installs.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cognicare.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // ── Tasks ──────────────────────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE tasks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          scheduled_at INTEGER NOT NULL,
          created_by TEXT NOT NULL,
          is_private INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'upcoming',
          notif_id INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          completed_at INTEGER
        )
      ''');

      // ── Medicine schedules (admin-configured, recurring) ──────────────────
      await txn.execute('''
        CREATE TABLE medicine_schedules (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          dose_note TEXT,
          frequency TEXT NOT NULL,
          times TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL
        )
      ''');

      // ── Individual medicine doses (generated from schedule) ───────────────
      await txn.execute('''
        CREATE TABLE medicine_doses (
          id TEXT PRIMARY KEY,
          medicine_id TEXT NOT NULL,
          scheduled_at INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'upcoming',
          taken_at INTEGER,
          notif_id INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (medicine_id) REFERENCES medicine_schedules(id)
        )
      ''');

      // ── Hydration config (single row) ─────────────────────────────────────
      await txn.execute('''
        CREATE TABLE hydration_config (
          id INTEGER PRIMARY KEY DEFAULT 1,
          mode TEXT NOT NULL DEFAULT 'goal',
          daily_goal INTEGER DEFAULT 8,
          interval_hours REAL DEFAULT 2.0,
          reminder_start TEXT DEFAULT '08:00',
          reminder_end TEXT DEFAULT '22:00',
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // ── Hydration daily logs ──────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE hydration_logs (
          date TEXT PRIMARY KEY,
          glass_count INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // ── Game sessions ─────────────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE game_sessions (
          id TEXT PRIMARY KEY,
          game_type TEXT NOT NULL,
          played_at INTEGER NOT NULL,
          category TEXT NOT NULL,
          language TEXT NOT NULL,
          length TEXT NOT NULL,
          difficulty_tier INTEGER NOT NULL DEFAULT 1,
          content_id TEXT NOT NULL,
          text_title TEXT NOT NULL,
          source_text TEXT NOT NULL,
          spoken_text TEXT NOT NULL,
          score_percent INTEGER NOT NULL DEFAULT 0,
          word_match_count INTEGER NOT NULL DEFAULT 0,
          total_words INTEGER NOT NULL DEFAULT 0,
          recording_path TEXT
        )
      ''');

      // ── App settings (key-value) ──────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      // ── Care reminders (admin-configured per-category) ───────────────────
      await txn.execute('''
        CREATE TABLE care_reminders (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          name TEXT NOT NULL,
          schedule_mode TEXT NOT NULL DEFAULT 'specific_times',
          config_data TEXT NOT NULL DEFAULT '{}',
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL
        )
      ''');

      // ── Care logs (today's scheduled instances) ───────────────────────────
      await txn.execute('''
        CREATE TABLE care_logs (
          id TEXT PRIMARY KEY,
          reminder_id TEXT NOT NULL,
          reminder_name TEXT NOT NULL,
          type TEXT NOT NULL,
          scheduled_at INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'upcoming',
          started_at INTEGER,
          done_at INTEGER,
          FOREIGN KEY (reminder_id) REFERENCES care_reminders(id)
        )
      ''');

      // Seed default settings
      await txn.insert('app_settings', {'key': 'text_size', 'value': 'medium'});
      await txn.insert('app_settings', {'key': 'tts_speed', 'value': 'normal'});
      await txn.insert('app_settings', {'key': 'language', 'value': 'en'});
      await txn.insert('app_settings', {'key': 'difficulty_rms', 'value': '1'});
    });
  }

  // onUpgrade: increment version and add ALTER TABLE / CREATE TABLE here.
  // Never drop tables or data — always migrate forward.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2: add care_reminders and care_logs tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS care_reminders (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          name TEXT NOT NULL,
          schedule_mode TEXT NOT NULL DEFAULT 'specific_times',
          config_data TEXT NOT NULL DEFAULT '{}',
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS care_logs (
          id TEXT PRIMARY KEY,
          reminder_id TEXT NOT NULL,
          reminder_name TEXT NOT NULL,
          type TEXT NOT NULL,
          scheduled_at INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'upcoming',
          started_at INTEGER,
          done_at INTEGER,
          FOREIGN KEY (reminder_id) REFERENCES care_reminders(id)
        )
      ''');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
