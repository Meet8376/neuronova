import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS service wrapping flutter_tts.
///
/// Supports play, pause (via stop+track position workaround), restart,
/// and word-by-word highlighting via setProgressHandler.
///
/// Handles platform availability gracefully (e.g. desktop fallback).
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final _tts = FlutterTts();
  bool _initialised = false;
  bool _isPlaying = false;
  bool _supported = true;
  String _currentText = '';
  int _lastWordEnd = 0;

  /// Callbacks set by the UI
  Function(String word, int start, int end)? onWordProgress;
  Function()? onComplete;

  Future<void> init({String language = 'en-US', double speed = 0.55}) async {
    if (_initialised) return;
    _initialised = true;

    try {
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
    } catch (e) {
      debugPrint('TTS not natively supported on this platform: $e');
      _supported = false;
    }
  }

  Future<void> speak(String text) async {
    _currentText = text;
    _lastWordEnd = 0;
    if (!_supported) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
      _isPlaying = true;
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> pause() async {
    if (!_supported) return;
    try {
      await _tts.stop();
    } catch (_) {}
    _isPlaying = false;
  }

  Future<void> resume() async {
    if (_currentText.isEmpty || !_supported) return;
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
    if (!_supported) return;
    try {
      await _tts.stop();
    } catch (_) {}
    _isPlaying = false;
    _lastWordEnd = 0;
  }

  bool get isPlaying => _isPlaying;

  Future<void> setLanguage(String language) async {
    if (!_supported) return;
    try {
      await _tts.setLanguage(language);
    } catch (_) {}
  }

  Future<void> setSpeed(double speed) async {
    if (!_supported) return;
    try {
      await _tts.setSpeechRate(speed);
    } catch (_) {}
  }

  static String ttsLocale(String appLanguage) {
    switch (appLanguage) {
      case 'hi': return 'hi-IN';
      default: return 'en-US';
    }
  }
}
