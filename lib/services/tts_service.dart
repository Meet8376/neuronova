import 'package:flutter_tts/flutter_tts.dart';

/// TTS service wrapping flutter_tts.
///
/// Supports play, pause (via stop+track position workaround), restart,
/// and word-by-word highlighting via setProgressHandler.
///
/// NOTE: flutter_tts.pause() is unreliable on some Android devices.
/// We work around this by stopping and resuming from the last word offset.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final _tts = FlutterTts();
  bool _initialised = false;
  bool _isPlaying = false;
  String _currentText = '';
  int _lastWordEnd = 0;

  /// Callbacks set by the UI
  Function(String word, int start, int end)? onWordProgress;
  Function()? onComplete;

  Future<void> init({String language = 'en-US', double speed = 0.55}) async {
    if (_initialised) return;
    _initialised = true;

    await _tts.setLanguage(language);
    await _tts.setSpeechRate(speed);
    await _tts.setPitch(0.9); // slightly lower pitch — easier on elderly ears
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() => _isPlaying = true);
    _tts.setCancelHandler(() => _isPlaying = false);
    _tts.setCompletionHandler(() {
      _isPlaying = false;
      _lastWordEnd = 0;
      onComplete?.call();
    });

    _tts.setProgressHandler((text, startOffset, endOffset, word) {
      _lastWordEnd = endOffset;
      onWordProgress?.call(word, startOffset, endOffset);
    });
  }

  Future<void> speak(String text) async {
    _currentText = text;
    _lastWordEnd = 0;
    await _tts.stop();
    await _tts.speak(text);
    _isPlaying = true;
  }

  /// Pause-like behavior: stop and remember position.
  /// On resume, we re-speak from the last tracked word boundary.
  Future<void> pause() async {
    await _tts.stop();
    _isPlaying = false;
  }

  /// Resume from approximately where we stopped.
  Future<void> resume() async {
    if (_currentText.isEmpty) return;
    if (_lastWordEnd > 0 && _lastWordEnd < _currentText.length) {
      await speak(_currentText.substring(_lastWordEnd).trim());
    } else {
      await speak(_currentText);
    }
  }

  Future<void> restart() async {
    await speak(_currentText);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
    _lastWordEnd = 0;
  }

  bool get isPlaying => _isPlaying;

  Future<void> setLanguage(String language) async {
    await _tts.setLanguage(language);
  }

  Future<void> setSpeed(double speed) async {
    await _tts.setSpeechRate(speed);
  }

  /// Returns the language code for flutter_tts based on our app language code.
  static String ttsLocale(String appLanguage) {
    switch (appLanguage) {
      case 'hi': return 'hi-IN';
      default: return 'en-US';
    }
  }
}
