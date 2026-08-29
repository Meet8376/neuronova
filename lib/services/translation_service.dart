import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../core/config/api_config.dart';
import '../data/db/database_helper.dart';

/// Handles all game content translation for NeuroNova.
///
/// Strategy:
///   English (en): No translation needed — source language from texts.json.
///   Hindi (hi):   ML Kit offline translation (model downloaded once on Wi-Fi).
///   Bengali (bn): ML Kit offline translation (model downloaded once on Wi-Fi).
///   Assamese (as): Google Cloud Translation API (one-time internet call per item,
///                   then cached permanently in SQLite).
///   Nepali (ne):  Google Cloud Translation API (same as Assamese).
///
/// All translations are cached in the [content_translations] SQLite table.
/// Once an item is cached, it is NEVER re-fetched — 100% offline thereafter.
class TranslationService {
  TranslationService._internal();
  static final TranslationService instance = TranslationService._internal();

  // ML Kit translators — created lazily, disposed on language change
  final Map<String, OnDeviceTranslator> _translators = {};
  final _modelManager = OnDeviceTranslatorModelManager();

  // Map our language codes → ML Kit TranslateLanguage enum
  static const Map<String, TranslateLanguage> _mlKitLanguageMap = {
    'hi': TranslateLanguage.hindi,
    'bn': TranslateLanguage.bengali,
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the translated text for a content item in [targetLang].
  /// Checks SQLite cache first. Translates and caches on first call.
  /// Returns the original English text if translation is unavailable.
  Future<TranslationResult> getTranslation({
    required String contentId,
    required String sourceText,
    required String sourceTitle,
    required String targetLang,
  }) async {
    if (targetLang == 'en') {
      return TranslationResult(
        text: sourceText,
        title: sourceTitle,
        fromCache: true,
        langCode: 'en',
      );
    }

    // 1. Check SQLite cache
    final cached = await _getCached(contentId, targetLang);
    if (cached != null) return cached;

    // 2. Translate
    try {
      final translatedText = await _translate(sourceText, targetLang);
      final translatedTitle = await _translate(sourceTitle, targetLang);

      // 3. Cache result
      await _cache(
        contentId: contentId,
        langCode: targetLang,
        translatedText: translatedText,
        translatedTitle: translatedTitle,
      );

      return TranslationResult(
        text: translatedText,
        title: translatedTitle,
        fromCache: false,
        langCode: targetLang,
      );
    } catch (e) {
      // Fallback: return English source text
      return TranslationResult(
        text: sourceText,
        title: sourceTitle,
        fromCache: false,
        langCode: 'en',
        error: e.toString(),
      );
    }
  }

  /// Pre-translates all content items for [targetLang] in one batch.
  /// Call this after the user selects a new language for the first time.
  /// Reports progress via [onProgress] callback (0.0 to 1.0).
  Future<BatchTranslationResult> translateAllContent({
    required String targetLang,
    void Function(double progress, String status)? onProgress,
  }) async {
    if (targetLang == 'en') {
      return BatchTranslationResult(total: 0, translated: 0, failed: 0);
    }

    // Load English content from assets
    final rawJson = await rootBundle.loadString('assets/content/texts.json');
    final List<dynamic> items = json.decode(rawJson) as List<dynamic>;

    int translated = 0;
    int failed = 0;
    final total = items.length;

    // Ensure ML Kit model is ready if needed
    if (_mlKitLanguageMap.containsKey(targetLang)) {
      onProgress?.call(0.0, 'Preparing $targetLang language model...');
      await _ensureMlKitModel(targetLang);
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i] as Map<String, dynamic>;
      final contentId = item['id'] as String;
      final sourceText = item['text'] as String;
      final sourceTitle = item['title'] as String;

      // Skip if already cached
      final existing = await _getCached(contentId, targetLang);
      if (existing != null) {
        translated++;
        onProgress?.call(i / total, 'Already cached: $sourceTitle');
        continue;
      }

      try {
        final translatedText = await _translate(sourceText, targetLang);
        final translatedTitle = await _translate(sourceTitle, targetLang);
        await _cache(
          contentId: contentId,
          langCode: targetLang,
          translatedText: translatedText,
          translatedTitle: translatedTitle,
        );
        translated++;
      } catch (_) {
        failed++;
      }

      onProgress?.call(i / total, 'Translating... ${i + 1} of $total');

      // Small delay between Cloud API calls to avoid rate limiting
      if (_mlKitLanguageMap[targetLang] == null) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
    }

    return BatchTranslationResult(total: total, translated: translated, failed: failed);
  }

  /// Returns true if all content for [targetLang] is already cached in SQLite.
  Future<bool> isContentReady(String targetLang) async {
    if (targetLang == 'en') return true;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM content_translations WHERE language_code = ?',
      [targetLang],
    );
    final count = rows.first['cnt'] as int? ?? 0;
    return count > 0;
  }

  /// Checks if the ML Kit model for [targetLang] is downloaded on-device.
  Future<bool> isMlKitModelReady(String targetLang) async {
    final mlLang = _mlKitLanguageMap[targetLang];
    if (mlLang == null) return false;
    return _modelManager.isModelDownloaded(mlLang.bcpCode);
  }

  /// Triggers the ML Kit model download for [targetLang].
  /// Returns true on success. Requires Wi-Fi (one-time only).
  Future<bool> downloadMlKitModel(String targetLang) async {
    final mlLang = _mlKitLanguageMap[targetLang];
    if (mlLang == null) return false;
    return _modelManager.downloadModel(mlLang.bcpCode);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<String> _translate(String text, String targetLang) async {
    if (_mlKitLanguageMap.containsKey(targetLang)) {
      return _translateWithMlKit(text, targetLang);
    } else {
      return _translateWithCloudApi(text, targetLang);
    }
  }

  Future<String> _translateWithMlKit(String text, String targetLang) async {
    await _ensureMlKitModel(targetLang);
    final translator = _getOrCreateTranslator(targetLang);
    return translator.translateText(text);
  }

  Future<void> _ensureMlKitModel(String targetLang) async {
    final mlLang = _mlKitLanguageMap[targetLang]!;
    final isReady = await _modelManager.isModelDownloaded(mlLang.bcpCode);
    if (!isReady) {
      await _modelManager.downloadModel(mlLang.bcpCode);
    }
  }

  OnDeviceTranslator _getOrCreateTranslator(String targetLang) {
    return _translators.putIfAbsent(
      targetLang,
      () => OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: _mlKitLanguageMap[targetLang]!,
      ),
    );
  }

  Future<String> _translateWithCloudApi(String text, String targetLang) async {
    if (!ApiConfig.isCloudConfigured) {
      throw Exception('Google Cloud Translation API key not configured. '
          'Set ApiConfig.googleTranslateApiKey in lib/core/config/api_config.dart');
    }

    final uri = Uri.parse(
      '${ApiConfig.translateEndpoint}?key=${ApiConfig.googleTranslateApiKey}',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'q': text,
        'source': 'en',
        'target': targetLang,
        'format': 'text',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Cloud Translation API error ${response.statusCode}: ${response.body}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final translations = decoded['data']['translations'] as List<dynamic>;
    return translations.first['translatedText'] as String;
  }

  Future<TranslationResult?> _getCached(String contentId, String langCode) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'content_translations',
      where: 'content_id = ? AND language_code = ?',
      whereArgs: [contentId, langCode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TranslationResult(
      text: rows.first['translated_text'] as String,
      title: rows.first['translated_title'] as String,
      fromCache: true,
      langCode: langCode,
    );
  }

  Future<void> _cache({
    required String contentId,
    required String langCode,
    required String translatedText,
    required String translatedTitle,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'content_translations',
      {
        'content_id': contentId,
        'language_code': langCode,
        'translated_text': translatedText,
        'translated_title': translatedTitle,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Clean up translators when done (call on app dispose or language change)
  Future<void> dispose() async {
    for (final t in _translators.values) {
      t.close();
    }
    _translators.clear();
  }
}

// ── Result models ────────────────────────────────────────────────────────────

class TranslationResult {
  final String text;
  final String title;
  final bool fromCache;
  final String langCode;
  final String? error;

  const TranslationResult({
    required this.text,
    required this.title,
    required this.fromCache,
    required this.langCode,
    this.error,
  });

  bool get hadError => error != null;
}

class BatchTranslationResult {
  final int total;
  final int translated;
  final int failed;

  const BatchTranslationResult({
    required this.total,
    required this.translated,
    required this.failed,
  });

  bool get allSucceeded => failed == 0;
  double get successRate => total == 0 ? 1.0 : translated / total;
}


