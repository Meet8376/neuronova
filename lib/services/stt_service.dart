import 'package:speech_to_text/speech_to_text.dart' as stt;

/// STT service wrapping speech_to_text.
///
/// Continuous dictation mode — designed for dementia patients who speak slowly
/// with long pauses. The service:
///   1. Uses [ListenMode.dictation] to suppress the Android "finalResult on silence" behaviour.
///   2. Sets a generous [pauseFor] so the OS waits longer before auto-stopping.
///   3. Maintains [_userRequestedListening] — set true when user taps Record,
///      false only when they explicitly tap Stop. If the OS fires a done/finalResult
///      event while the user still wants to record, we immediately re-arm and
///      accumulate the buffer, giving a seamless "tap once → speak freely → tap once"
///      experience.
///
/// Falls back gracefully: if init fails, callers show a text field instead.
class SttService {
  SttService._();
  static final SttService instance = SttService._();

  final _stt = stt.SpeechToText();
  bool _available = false;

  /// True while the OS recognizer is actively listening.
  bool _listening = false;

  /// True from user's "Start Recording" tap until "Stop Recording" tap.
  /// The re-arm loop checks this flag — it keeps listening even if the OS
  /// fires an unwanted "done" event in the middle of the session.
  bool _userRequestedListening = false;

  /// Accumulates all speech segments across re-arm cycles.
  /// Reset to empty each time [startListening] is called fresh.
  String _buffer = '';

  // Callbacks stored so the re-arm loop can pass them on each restart.
  late String _language;
  late Function(String) _onPartial;
  late Function(String) _onFinal;

  /// Must be called before any other method.
  /// Returns true if STT is available on this device.
  Future<bool> initialize() async {
    _available = await _stt.initialize(
      onError: (error) {
        // On error while user still wants to listen → re-arm
        if (_userRequestedListening) {
          _reArm();
        } else {
          _listening = false;
        }
      },
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') &&
            _userRequestedListening) {
          // OS stopped us prematurely — restart immediately
          _reArm();
        } else if (status == 'done' || status == 'notListening') {
          _listening = false;
        }
      },
    );
    return _available;
  }

  bool get isAvailable => _available;
  bool get isListening => _listening;

  /// Starts a new dictation session.
  ///
  /// [seedText] — pass any text already committed so this session's buffer
  /// starts from there. Used when the patient taps Stop → Start again to
  /// add more words (so the new session builds on top of what was already said).
  ///
  /// [onPartial] receives the full accumulated+live text as the user speaks.
  /// [onFinal] receives the complete accumulated transcript when [stop] is called.
  Future<bool> startListening({
    required String language, // 'en_US' or 'hi_IN'
    required Function(String text) onPartial,
    required Function(String text) onFinal,
    String seedText = '',      // prior committed text to build on
  }) async {
    if (!_available) return false;

    _language = language;
    _onPartial = onPartial;
    _onFinal = onFinal;
    _buffer = seedText;        // seed with already-committed text if any
    _userRequestedListening = true;

    return await _startOsListening();
  }

  /// Re-arms the OS recognizer mid-session without resetting the buffer.
  /// Called automatically on premature OS stop events.
  Future<void> _reArm() async {
    if (!_userRequestedListening || !_available) return;
    // Small delay to let the OS recognizer fully release resources
    await Future.delayed(const Duration(milliseconds: 150));
    if (!_userRequestedListening) return; // user tapped stop during delay
    await _startOsListening();
  }

  /// Internal: calls _stt.listen with our preferred options.
  Future<bool> _startOsListening() async {
    _listening = true;
    final started = await _stt.listen(
      onResult: (result) {
        final words = result.recognizedWords;

        if (result.finalResult) {
          // Append this segment to the accumulated buffer
          if (words.trim().isNotEmpty) {
            _buffer = _buffer.isEmpty ? words : '$_buffer $words';
          }
          // Show the full accumulated transcript as partial (so UI stays updated)
          _onPartial(_buffer);

          if (_userRequestedListening) {
            // Re-arm — user hasn't tapped Stop yet
            _reArm();
          } else {
            // User tapped Stop before this finalResult arrived — deliver final
            _listening = false;
            _onFinal(_buffer);
          }
        } else {
          // Show buffer + current in-progress segment in real time
          final live = _buffer.isEmpty ? words : '$_buffer $words';
          _onPartial(live);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: _language,
        listenFor: const Duration(minutes: 10),
        // Generous pause threshold — dementia patients pause for 5–15 seconds
        pauseFor: const Duration(seconds: 30),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
    if (!started) {
      _listening = false;
      if (_userRequestedListening) {
        // Failed to start — try re-arm after short delay
        await Future.delayed(const Duration(milliseconds: 300));
        _reArm();
      }
    }
    return started;
  }

  /// Called when user explicitly taps "Stop Recording".
  /// Delivers the full accumulated transcript via [onFinal].
  Future<void> stop() async {
    _userRequestedListening = false;
    await _stt.stop();
    _listening = false;
    // Deliver whatever we have accumulated
    _onFinal(_buffer);
    _buffer = '';
  }

  /// Cancel without delivering a result (e.g. user taps "Try Again").
  Future<void> cancel() async {
    _userRequestedListening = false;
    await _stt.cancel();
    _listening = false;
    _buffer = '';
  }

  /// STT locale code from our app language code.
  static String sttLocale(String appLanguage) {
    switch (appLanguage) {
      case 'hi':
        return 'hi_IN';
      default:
        return 'en_US';
    }
  }
}
