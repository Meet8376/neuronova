import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/content_item.dart';
import '../../../data/models/game_session.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../services/tts_service.dart';
import '../../../services/stt_service.dart';
import '../../../services/scoring_service.dart';
import 'results_screen.dart';

/// The core game screen with 3 phases:
///   Phase 1: READ — text visible, TTS available, patient can play/pause/restart
///   Phase 2: SPEAK — text hidden, patient records or types what they remember
///   Phase 3: RESULT — score shown (handled by ResultsScreen)
class ReadingSessionScreen extends StatefulWidget {
  final ContentItem content;
  final String language; // 'en' or 'hi'

  const ReadingSessionScreen({
    super.key,
    required this.content,
    required this.language,
  });

  @override
  State<ReadingSessionScreen> createState() => _ReadingSessionScreenState();
}

enum _Phase { read, speak }

class _ReadingSessionScreenState extends State<ReadingSessionScreen> {
  final _tts = TtsService.instance;
  final _stt = SttService.instance;
  final _scoring = ScoringService.instance;
  final _repo = GameRepository();

  _Phase _phase = _Phase.read;

  // TTS state
  bool _ttsPlaying = false;
  int _highlightStart = 0;
  int _highlightEnd = 0;

  // STT state
  bool _sttAvailable = false;
  bool _listening = false;
  // _displayText: the full live display (partial or committed).
  // SttService now owns buffer accumulation — we just display what it gives us.
  String _displayText = '';     // shown to user at all times (updated by both onPartial and onFinal)
  String _committedText = '';   // the final confirmed transcript (used for scoring)
  bool _editingTranscript = false; // user tapped 'Edit' to fix STT text
  bool _useManualInput = false;
  final _manualCtrl = TextEditingController();
  final _editCtrl = TextEditingController(); // for edit-mode correction

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initStt();
  }

  Future<void> _initTts() async {
    await _tts.init(
      language: TtsService.ttsLocale(widget.language),
      speed: 0.5,
    );
    _tts.onWordProgress = (word, start, end) {
      if (!mounted) return;
      setState(() {
        _highlightStart = start;
        _highlightEnd = end;
      });
    };
    _tts.onComplete = () {
      if (!mounted) return;
      setState(() => _ttsPlaying = false);
    };
  }

  Future<void> _initStt() async {
    final available = await _stt.initialize();
    if (!mounted) return;
    setState(() {
      _sttAvailable = available;
      _useManualInput = !available; // fall back to text if no mic
    });
  }

  // ── Phase 1: TTS controls ─────────────────────────────────────────────────

  Future<void> _toggleTts() async {
    if (_ttsPlaying) {
      await _tts.pause();
      setState(() => _ttsPlaying = false);
    } else {
      await _tts.speak(widget.content.text);
      setState(() => _ttsPlaying = true);
    }
  }

  Future<void> _restartTts() async {
    await _tts.restart();
    setState(() {
      _ttsPlaying = true;
      _highlightStart = 0;
      _highlightEnd = 0;
    });
  }

  Future<void> _stopTts() async {
    await _tts.stop();
    setState(() {
      _ttsPlaying = false;
      _highlightStart = 0;
      _highlightEnd = 0;
    });
  }

  void _proceedToSpeak() {
    _stopTts();
    setState(() {
      _phase = _Phase.speak;
      _committedText = '';
      _displayText = '';
    });
  }

  // ── Phase 2: STT controls ─────────────────────────────────────────────────

  Future<void> _toggleListening() async {
    if (_listening) {
      // User tapped Stop — SttService.stop() delivers onFinal with full buffer
      await _stt.stop();
      setState(() {
        _listening = false;
        // _committedText and _displayText are already updated by onFinal callback
      });
      return;
    }

    setState(() {
      _listening = true;
      _editingTranscript = false;
      // Keep _displayText as-is — SttService starts fresh buffer for this tap
      // but we want to preserve whatever the user already said (if they tapped
      // Stop and Start again to add more). We pass the existing committedText
      // as a seed by NOT clearing — SttService has its own buffer reset in startListening.
      // On a fresh tap after a stop, _committedText holds what was confirmed,
      // and onPartial will build on top of the new buffer.
    });

    final started = await _stt.startListening(
      language: SttService.sttLocale(widget.language),
      seedText: _committedText,  // preserve previously spoken words
      onPartial: (text) {
        // SttService delivers: previousBuffer + current live segment
        // Just display it — no local accumulation needed
        if (!mounted) return;
        setState(() {
          _displayText = text;
        });
      },
      onFinal: (text) {
        // Full accumulated transcript for this mic session
        if (!mounted) return;
        setState(() {
          _committedText = text;
          _displayText = text;
          _listening = false;
        });
      },
    );

    if (!started) {
      setState(() {
        _listening = false;
        _useManualInput = true;
      });
    }
  }

  // ❌ Only explicit clear button erases transcript
  void _clearTranscript() {
    _stt.cancel(); // also cancel any active listening
    setState(() {
      _committedText = '';
      _displayText = '';
      _listening = false;
      _editingTranscript = false;
    });
  }

  void _startEditingTranscript() {
    _editCtrl.text = _committedText;
    setState(() => _editingTranscript = true);
  }

  void _finishEditingTranscript() {
    setState(() {
      _committedText = _editCtrl.text.trim();
      _displayText = _committedText;
      _editingTranscript = false;
    });
  }

  Future<void> _submit() async {
    // Use accumulated transcript or manual text
    final spoken = _useManualInput ? _manualCtrl.text.trim() : _committedText.trim();
    if (spoken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please speak or type something first!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final result = _scoring.score(widget.content.text, spoken);
    final session = await _repo.saveSession(GameSession(
      id: '', // assigned by repo
      gameType: 'read_memorize_speak',
      playedAt: DateTime.now(),
      category: widget.content.category,
      language: widget.language,
      length: widget.content.length,
      difficultyTier: widget.content.difficultyTier,
      contentId: widget.content.id,
      textTitle: widget.content.title,
      sourceText: widget.content.text,
      spokenText: spoken,
      scorePercent: result.percent,
      wordMatchCount: result.matched,
      totalWords: result.total,
    ));

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          session: session,
          scoringResult: result,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.cancel();
    _manualCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content.title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            final nav = Navigator.of(context);
            await _tts.stop();
            if (!mounted) return;
            nav.pop();
          },
        ),
      ),
      body: _phase == _Phase.read ? _buildReadPhase() : _buildSpeakPhase(),
    );
  }

  // ── Phase 1: Read ─────────────────────────────────────────────────────────

  Widget _buildReadPhase() {
    final text = widget.content.text;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Phase indicator
        const _PhaseIndicator(phase: 1, total: 2, label: 'Read & Memorize'),
        const SizedBox(height: 20),

        // The text passage with word highlighting
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBgWarm,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: _ttsPlaying
              ? _HighlightedText(
                  text: text,
                  highlightStart: _highlightStart,
                  highlightEnd: _highlightEnd,
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    height: 1.7,
                    color: AppColors.textPrimary,
                  ),
                ),
        ),
        const SizedBox(height: 28),

        // TTS controls
        const Text(
          'Listen to the passage:',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Play/pause
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _toggleTts,
                icon: Icon(_ttsPlaying ? Icons.pause_rounded : Icons.volume_up_rounded, size: 26),
                label: Text(_ttsPlaying ? 'Pause' : 'Listen'),
              ),
            ),
            const SizedBox(width: 10),
            // Restart
            SizedBox(
              width: 60,
              height: 60,
              child: ElevatedButton(
                onPressed: _restartTts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.primary,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Icon(Icons.replay_rounded, size: 26),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Category badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.content.category.displayName} • ${widget.content.length.displayName}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Proceed button
        OutlinedButton.icon(
          onPressed: _proceedToSpeak,
          icon: const Icon(Icons.mic_rounded, size: 26),
          label: const Text("I'm Ready to Speak!"),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 64),
            textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'The text will disappear. Speak from memory.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 15, color: AppColors.textHint),
        ),
      ],
    );
  }

  // ── Phase 2: Speak ────────────────────────────────────────────────────────

  Widget _buildSpeakPhase() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _PhaseIndicator(phase: 2, total: 2, label: 'Say What You Remember'),
        const SizedBox(height: 20),

        // "Text is hidden" placeholder
        Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            children: [
              Icon(Icons.psychology_rounded, size: 52, color: AppColors.primary),
              SizedBox(height: 12),
              Text(
                'The passage is hidden now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Speak what you remember!',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // STT or manual input
        if (!_useManualInput) ...[
          // ── Transcript box ────────────────────────────────────────────────
          // Shows accumulated text + live partial. Never auto-clears.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBgWarm,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _listening
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: _editingTranscript
                // ── Edit mode: transcript is a text field ─────────────────
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('Correct what I heard:',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _editCtrl,
                        maxLines: null,
                        autofocus: true,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 19,
                            height: 1.5),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _finishEditingTranscript,
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44)),
                        child: const Text('Save Changes'),
                      ),
                    ],
                  )
                // ── Normal mode: show transcript ──────────────────────────
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _listening ? 'Listening…' : 'What I heard:',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: _listening
                                      ? AppColors.error
                                      : AppColors.textHint),
                            ),
                          ),
                          // ❌ Clear button — only way to erase transcript
                          if (_committedText.isNotEmpty && !_listening)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ✏ Edit option
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded,
                                      size: 20, color: AppColors.textHint),
                                  tooltip: 'Fix what I said',
                                  onPressed: _startEditingTranscript,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 22, color: AppColors.error),
                                  tooltip: 'Clear and start over',
                                  onPressed: _clearTranscript,
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Single display text — SttService owns the buffer,
                      // we just show what it gives us (no double-tracking)
                      if (_displayText.isNotEmpty)
                        Text(
                          _displayText,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 19,
                            // Grey/italic while listening (partial), solid when committed
                            color: _listening
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontStyle: _listening
                                ? FontStyle.italic
                                : FontStyle.normal,
                            height: 1.5,
                          ),
                        ),
                      if (_displayText.isEmpty)
                        Text(
                          _listening
                              ? 'Speak now…'
                              : 'Tap the mic below and start speaking',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          // ── Mic button ────────────────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _editingTranscript ? null : _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _editingTranscript
                      ? AppColors.textHint
                      : _listening
                          ? AppColors.error
                          : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (_listening ? AppColors.error : AppColors.primary)
                          .withValues(alpha: _editingTranscript ? 0.0 : 0.3),
                      blurRadius: _listening ? 24 : 8,
                      spreadRadius: _listening ? 6 : 1,
                    ),
                  ],
                ),
                child: Icon(
                  _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 46,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _editingTranscript
                  ? 'Finish editing before speaking again'
                  : _listening
                      ? 'Listening… tap ■ to stop'
                      : _committedText.isEmpty
                          ? 'Tap mic to start speaking'
                          : 'Tap mic to add more',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: _listening ? AppColors.error : AppColors.textSecondary,
                fontWeight:
                    _listening ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Type instead — secondary option
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _useManualInput = true),
              icon: const Icon(Icons.keyboard_rounded, size: 18),
              label: const Text('Type instead'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.textHint,
                  textStyle: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 15)),
            ),
          ),
        ] else ...[
          // Manual text input (fallback / for those who prefer typing)
          TextFormField(
            controller: _manualCtrl,
            maxLines: 6,
            style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 19, height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Type what you remember…',
              alignLabelWithHint: true,
            ),
          ),
          if (_sttAvailable) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _useManualInput = false),
                icon: const Icon(Icons.mic_rounded, size: 18),
                label: const Text('Use microphone instead'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 15)),
              ),
            ),
          ],
        ],

        // Submit button — full width
        if (_submitting)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_rounded, size: 28),
            label: const Text('Check My Answer'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

// ─── Phase indicator ────────────────────────────────────────────────────────────

class _PhaseIndicator extends StatelessWidget {
  final int phase;
  final int total;
  final String label;
  const _PhaseIndicator({required this.phase, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(total, (i) {
          final active = i + 1 == phase;
          final done = i + 1 < phase;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    decoration: BoxDecoration(
                      color: done || active ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < total - 1) const SizedBox(width: 6),
              ],
            ),
          );
        }),
        const SizedBox(width: 12),
        Text('$phase/$total',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

// ─── Word-by-word TTS highlight ────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final int highlightStart;
  final int highlightEnd;
  const _HighlightedText(
      {required this.text, required this.highlightStart, required this.highlightEnd});

  @override
  Widget build(BuildContext context) {
    if (highlightStart >= text.length || highlightEnd > text.length) {
      return Text(text,
          style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 22, height: 1.7, color: AppColors.textPrimary));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 22, height: 1.7, color: AppColors.textPrimary),
        children: [
          if (highlightStart > 0)
            TextSpan(text: text.substring(0, highlightStart)),
          TextSpan(
            text: text.substring(highlightStart, highlightEnd),
            style: const TextStyle(
              backgroundColor: AppColors.wordHighlight,
              color: AppColors.wordHighlightText,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (highlightEnd < text.length)
            TextSpan(text: text.substring(highlightEnd)),
        ],
      ),
    );
  }
}
