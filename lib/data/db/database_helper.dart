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

  /// For tests: allow injecting or resetting the database instance.
  void setDatabaseForTesting(Database? db) {
    _db = db;
  }

  /// Initializes a clean in-memory database for isolated unit tests.
  Future<Database> initInMemoryDatabase() async {
    _db = await openDatabase(
      inMemoryDatabasePath,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'neuronova.db');
    return openDatabase(
      path,
      version: 7,
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
          completed_at INTEGER,
          reminder_id TEXT
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

      // ── Registered users ─────────────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          display_name TEXT NOT NULL,
          role TEXT NOT NULL,
          created_at INTEGER NOT NULL
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
          goal_count INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (reminder_id) REFERENCES care_reminders(id)
        )
      ''');

      // ── Cognitive Scores & Trends (PRD FR-2.2) ───────────────────────────
      await txn.execute('''
        CREATE TABLE cognitive_scores (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL DEFAULT 'p1',
          computed_score REAL NOT NULL,
          trend_direction TEXT NOT NULL,
          accuracy_avg REAL NOT NULL,
          response_time_avg REAL NOT NULL,
          timestamp INTEGER NOT NULL,
          sync_status INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // ── Patients list for ASHA / Health Worker (PRD FR-5.4) ─────────────
      await txn.execute('''
        CREATE TABLE patients (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          age INTEGER NOT NULL,
          village TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'stable',
          cognitive_index INTEGER NOT NULL DEFAULT 75,
          last_active INTEGER NOT NULL,
          missed_meds INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // ── Sync Queue (PRD FR-6.2) ───────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE sync_queue (
          id TEXT PRIMARY KEY,
          entity_type TEXT NOT NULL,
          payload TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // ── Content translations cache (offline-first) ──────────────────────
      await txn.execute('''
        CREATE TABLE content_translations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content_id TEXT NOT NULL,
          language_code TEXT NOT NULL,
          translated_text TEXT NOT NULL,
          translated_title TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          UNIQUE(content_id, language_code)
        )
      ''');

      // Seed default settings
      await txn.insert('app_settings', {'key': 'text_size', 'value': 'medium'});
      await txn.insert('app_settings', {'key': 'tts_speed', 'value': 'normal'});
      await txn.insert('app_settings', {'key': 'language', 'value': 'en'});
      await txn.insert('app_settings', {'key': 'difficulty_rms', 'value': '1'});
      await txn.insert('app_settings', {'key': 'game_languages', 'value': 'en'});

      // ── Memories (Memory Album) ──────────────────────────────────────────
      await txn.execute('''
        CREATE TABLE memories (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          image_path TEXT NOT NULL,
          date_label TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      // Seed initial patient records for ASHA Worker Demo
      final now = DateTime.now().millisecondsSinceEpoch;
      await txn.insert('patients', {
        'id': 'p1',
        'name': 'Rajan Kumar (Primary)',
        'age': 72,
        'village': 'Guwahati, Assam',
        'status': 'stable',
        'cognitive_index': 78,
        'last_active': now,
        'missed_meds': 0,
      });
      await txn.insert('patients', {
        'id': 'p2',
        'name': 'Aita Borah',
        'age': 78,
        'village': 'Majuli, Assam',
        'status': 'attention_needed',
        'cognitive_index': 62,
        'last_active': now - (86400000 * 2),
        'missed_meds': 2,
      });
      await txn.insert('patients', {
        'id': 'p3',
        'name': 'Ibotombi Singh',
        'age': 81,
        'village': 'Imphal West, Manipur',
        'status': 'stable',
        'cognitive_index': 84,
        'last_active': now - 3600000,
        'missed_meds': 0,
      });

      // Seed initial memories
      await txn.insert('memories', {
        'id': 'mem_1',
        'title': 'Family Garden Reunion',
        'description': 'You and your loving family sitting together in the sunny garden at Barabanki.',
        'image_path': 'assets/images/memory_family.png',
        'date_label': 'Family Moment',
        'created_at': now,
      });
      await txn.insert('memories', {
        'id': 'mem_2',
        'title': 'Teatime with Meena',
        'description': 'A cozy morning cup of hot tea and fresh cookies by the window.',
        'image_path': 'assets/images/memory_tea.png',
        'date_label': 'Comfort Moment',
        'created_at': now,
      });
      await txn.insert('memories', {
        'id': 'mem_3',
        'title': 'Bruno the Dog',
        'description': 'Your gentle Golden Retriever resting lovingly on your lap at home.',
        'image_path': 'assets/images/memory_pet.png',
        'date_label': 'Pet Memory',
        'created_at': now,
      });
    });
  }

  // onUpgrade: increment version and add ALTER TABLE / CREATE TABLE here.
  // Never drop tables or data — always migrate forward.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
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
          goal_count INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (reminder_id) REFERENCES care_reminders(id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cognitive_scores (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL DEFAULT 'p1',
          computed_score REAL NOT NULL,
          trend_direction TEXT NOT NULL,
          accuracy_avg REAL NOT NULL,
          response_time_avg REAL NOT NULL,
          timestamp INTEGER NOT NULL,
          sync_status INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS patients (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          age INTEGER NOT NULL,
          village TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'stable',
          cognitive_index INTEGER NOT NULL DEFAULT 75,
          last_active INTEGER NOT NULL,
          missed_meds INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id TEXT PRIMARY KEY,
          entity_type TEXT NOT NULL,
          payload TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          display_name TEXT NOT NULL,
          role TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS content_translations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content_id TEXT NOT NULL,
          language_code TEXT NOT NULL,
          translated_text TEXT NOT NULL,
          translated_title TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          UNIQUE(content_id, language_code)
        )
      ''');
      // Seed game_languages setting (primary language only by default)
      await db.insert(
        'app_settings',
        {'key': 'game_languages', 'value': 'en'},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN reminder_id TEXT');
      } catch (_) {
        // Column might already exist in fresh or custom installs
      }
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS memories (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          image_path TEXT NOT NULL,
          date_label TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      final existing = await db.query('memories', limit: 1);
      if (existing.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.insert('memories', {
          'id': 'mem_1',
          'title': 'Family Garden Reunion',
          'description': 'You and your loving family sitting together in the sunny garden at Barabanki.',
          'image_path': 'assets/images/memory_family.png',
          'date_label': 'Family Moment',
          'created_at': now,
        });
        await db.insert('memories', {
          'id': 'mem_2',
          'title': 'Teatime with Meena',
          'description': 'A cozy morning cup of hot tea and fresh cookies by the window.',
          'image_path': 'assets/images/memory_tea.png',
          'date_label': 'Comfort Moment',
          'created_at': now,
        });
        await db.insert('memories', {
          'id': 'mem_3',
          'title': 'Bruno the Dog',
          'description': 'Your gentle Golden Retriever resting lovingly on your lap at home.',
          'image_path': 'assets/images/memory_pet.png',
          'date_label': 'Pet Memory',
          'created_at': now,
        });
      }
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
