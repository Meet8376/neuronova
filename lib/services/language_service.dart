import 'package:flutter/foundation.dart'; // ChangeNotifier
import '../data/db/database_helper.dart';

/// Manages the user's language preferences for NeuroNova.
///
/// - [currentLanguage]: The primary language used for the UI and game content.
/// - [gameLanguages]: Languages the patient can select in the game setup screen
///   (includes primary + any additional languages they've chosen).
///
/// Language codes used throughout the app:
///   'en' = English  (full offline: ML Kit + device TTS)
///   'hi' = Hindi    (full offline: ML Kit + device TTS)
///   'bn' = Bengali  (full offline: ML Kit + device TTS)
///   'as' = Assamese (offline UI; cloud TTS / no TTS fallback)
///   'ne' = Nepali   (offline UI; device TTS; cloud translation for content)
class LanguageService extends ChangeNotifier {
  LanguageService._internal();
  static final LanguageService instance = LanguageService._internal();

  String _currentLanguage = 'en';
  List<String> _gameLanguages = ['en'];

  /// True only after user has explicitly selected a language during setup.
  /// False on a brand-new install — used to show LanguageSetupScreen.
  bool _isLanguageConfigured = false;

  String get currentLanguage => _currentLanguage;
  List<String> get gameLanguages => _gameLanguages;
  bool get isLanguageConfigured => _isLanguageConfigured;

  // ── Static metadata ────────────────────────────────────────────────────────

  /// Human-readable info for each supported language.
  static const Map<String, LanguageInfo> supportedLanguages = {
    'en': LanguageInfo(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      script: 'Latin',
      ttsLocale: 'en-IN',
      usesMlKit: false,  // No translation needed — it's the source language
      usesCloudApi: false,
    ),
    'hi': LanguageInfo(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिंदी',
      script: 'Devanagari',
      ttsLocale: 'hi-IN',
      usesMlKit: true,
      usesCloudApi: false,
    ),
    'bn': LanguageInfo(
      code: 'bn',
      name: 'Bengali',
      nativeName: 'বাংলা',
      script: 'Eastern Nagari',
      ttsLocale: 'bn-IN',
      usesMlKit: true,
      usesCloudApi: false,
    ),
    'as': LanguageInfo(
      code: 'as',
      name: 'Assamese',
      nativeName: 'অসমীয়া',
      script: 'Eastern Nagari',
      ttsLocale: null,  // No device TTS — cloud TTS or silent fallback
      usesMlKit: false,
      usesCloudApi: true,
    ),
    'ne': LanguageInfo(
      code: 'ne',
      name: 'Nepali',
      nativeName: 'नेपाली',
      script: 'Devanagari',
      ttsLocale: 'ne-NP',
      usesMlKit: false,
      usesCloudApi: true,
    ),
  };

  /// Returns true if the language has a device-level TTS voice.
  bool hasTtsSupport(String langCode) {
    return supportedLanguages[langCode]?.ttsLocale != null;
  }

  /// Returns the TTS locale string (e.g. 'hi-IN') or null if unsupported.
  String? getTtsLocale(String langCode) {
    return supportedLanguages[langCode]?.ttsLocale;
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Load saved preferences from SQLite. Call once in main() before runApp().
  Future<void> init() async {
    final primaryLang = await DatabaseHelper.instance.getSetting('language');
    final gamelangsRaw = await DatabaseHelper.instance.getSetting('game_languages') ?? 'en';

    if (primaryLang != null) {
      _isLanguageConfigured = true;
      _currentLanguage = primaryLang;
    }
    // If null, _isLanguageConfigured stays false — LanguageSetupScreen will show

    _gameLanguages = gamelangsRaw.split(',').where((s) => s.isNotEmpty).toList();

    // Always ensure primary language is in game languages
    if (!_gameLanguages.contains(_currentLanguage)) {
      _gameLanguages.insert(0, _currentLanguage);
    }
  }

  // ── Setters ────────────────────────────────────────────────────────────────

  /// Set the primary UI language and persist to SQLite.
  /// Call [notifyListeners] so MaterialApp locale rebuilds instantly.
  Future<void> setCurrentLanguage(String langCode) async {
    _currentLanguage = langCode;
    _isLanguageConfigured = true;
    await DatabaseHelper.instance.setSetting('language', langCode);

    // Primary language always goes first in game languages
    if (!_gameLanguages.contains(langCode)) {
      _gameLanguages.insert(0, langCode);
      await _persistGameLanguages();
    }
    notifyListeners(); // ← triggers MaterialApp locale rebuild
  }

  /// Set the list of languages available in games and persist to SQLite.
  Future<void> setGameLanguages(List<String> langs) async {
    // Always keep primary language
    if (!langs.contains(_currentLanguage)) {
      langs.insert(0, _currentLanguage);
    }
    _gameLanguages = langs;
    await _persistGameLanguages();
  }

  Future<void> _persistGameLanguages() async {
    await DatabaseHelper.instance.setSetting('game_languages', _gameLanguages.join(','));
  }
}

/// Immutable metadata about a supported language.
class LanguageInfo {
  final String code;
  final String name;
  final String nativeName;
  final String script;
  final String? ttsLocale;   // null = no device TTS support
  final bool usesMlKit;      // true = use google_mlkit_translation offline
  final bool usesCloudApi;   // true = use Google Cloud Translation API (needs internet once)

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.script,
    required this.ttsLocale,
    required this.usesMlKit,
    required this.usesCloudApi,
  });

  bool get hasFullOfflineSupport => !usesCloudApi;
  bool get hasTts => ttsLocale != null;
}
