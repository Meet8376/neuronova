/// API configuration — fill in your keys before running the cloud translation.
///
/// HOW TO GET A GOOGLE CLOUD TRANSLATION API KEY:
/// 1. Go to https://console.cloud.google.com/
/// 2. Create or select a project
/// 3. Enable "Cloud Translation API"
/// 4. Go to APIs & Services → Credentials → Create Credentials → API Key
/// 5. Paste the key below
///
/// For the SIH demo, Assamese and Nepali use this key for first-time setup only.
/// After that, translations are cached in SQLite and never need internet again.
class ApiConfig {
  ApiConfig._();

  /// Google Cloud Translation API key.
  /// Used for: Assamese (as) and Nepali (ne) — languages not supported by ML Kit.
  /// Leave empty string to disable cloud translation (app will use English fallback).
  static const String googleTranslateApiKey = '';
  // TODO: Replace with your key: 'AIza...'

  /// Google Cloud Translation API endpoint
  static const String translateEndpoint =
      'https://translation.googleapis.com/language/translate/v2';

  /// Whether cloud translation is configured
  static bool get isCloudConfigured => googleTranslateApiKey.isNotEmpty;
}
