import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../services/notification_service.dart';

/// Full-screen alarm overlay shown when a task reminder fires.
///
/// Can be pushed as a route: Navigator.push(context, AlarmScreen.route(task))
/// or shown as a full-screen dialog on notification tap.
class AlarmScreen extends StatefulWidget {
  final Task task;

  const AlarmScreen({super.key, required this.task});

  static Route<void> route(Task task) => MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AlarmScreen(task: task),
      );

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  final _repo = TaskRepository();

  _AlarmPhase _phase = _AlarmPhase.ringing;
  bool _showSnoozeOptions = false;
  bool _loading = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    // Keep screen on while alarm is showing
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _markDone() async {
    setState(() => _loading = true);
    await _repo.updateStatus(widget.task.id, TaskStatus.done);
    await NotificationService.instance.cancel(widget.task.notifId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _markInProgress() async {
    await _repo.updateStatus(widget.task.id, TaskStatus.inProgress);
    await NotificationService.instance.cancel(widget.task.notifId);
    _pulseCtrl.stop();
    setState(() => _phase = _AlarmPhase.inProgress);
  }

  Future<void> _snooze(int minutes) async {
    await NotificationService.instance.snoozeAlarm(
      notifId: widget.task.notifId,
      taskName: widget.task.name,
      snoozeMinutes: minutes,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back button from dismissing — patient must actively act
      canPop: false,
      child: Scaffold(
        backgroundColor: _phase == _AlarmPhase.inProgress
            ? const Color(0xFF1A2E4A)
            : AppColors.primary,
        body: SafeArea(
          child: _phase == _AlarmPhase.ringing
              ? _buildRingingPhase()
              : _buildInProgressPhase(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1: Ringing
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRingingPhase() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Bell icon — pulsing
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.alarm_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Task name — very large
          Text(
            widget.task.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),

          // Time
          Text(
            _formatTime(widget.task.scheduledAt),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),

          const Spacer(flex: 3),

          // ── Snooze section ────────────────────────────────────────────────
          if (_showSnoozeOptions) ...[
            _buildSnoozeOptions(),
            const SizedBox(height: 20),
          ],

          // ── Buttons ───────────────────────────────────────────────────────
          if (!_showSnoozeOptions) ...[
            _ActionButton(
              label: "✅  Done",
              color: const Color(0xFF2ECC71),
              onTap: _loading ? null : _markDone,
            ),
            const SizedBox(height: 14),
            _ActionButton(
              label: "🚀  I'm Starting",
              color: Colors.white,
              textColor: AppColors.primary,
              onTap: _markInProgress,
            ),
            const SizedBox(height: 14),
            _ActionButton(
              label: "⏰  Remind Me Later",
              color: Colors.white.withValues(alpha: 0.18),
              onTap: () => setState(() => _showSnoozeOptions = true),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSnoozeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Remind me in…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _SnoozeChip(label: '5 min',  onTap: () => _snooze(5)),
            const SizedBox(width: 10),
            _SnoozeChip(label: '10 min', onTap: () => _snooze(10)),
            const SizedBox(width: 10),
            _SnoozeChip(label: '15 min', onTap: () => _snooze(15)),
          ],
        ),
        const SizedBox(height: 14),
        _CustomSnoozeRow(onSnooze: _snooze),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _showSnoozeOptions = false),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 17,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 2: In Progress — screen stays open with just task name + Done
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInProgressPhase() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),

          const Icon(
            Icons.play_circle_fill_rounded,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 28),

          const Text(
            'In Progress',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            widget.task.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),

          const Spacer(flex: 3),

          _ActionButton(
            label: "✅  Done",
            color: const Color(0xFF2ECC71),
            onTap: _loading ? null : _markDone,
          ),
          const SizedBox(height: 14),

          // Small "Remind me later" still available
          TextButton.icon(
            onPressed: () => setState(() {
              _phase = _AlarmPhase.ringing;
              _showSnoozeOptions = true;
              _pulseCtrl.repeat(reverse: true);
            }),
            icon: const Icon(Icons.alarm_rounded, size: 18, color: Colors.white70),
            label: const Text(
              'Remind Me Later',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase enum
// ─────────────────────────────────────────────────────────────────────────────

enum _AlarmPhase { ringing, inProgress }

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _SnoozeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SnoozeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomSnoozeRow extends StatefulWidget {
  final void Function(int minutes) onSnooze;
  const _CustomSnoozeRow({required this.onSnooze});

  @override
  State<_CustomSnoozeRow> createState() => _CustomSnoozeRowState();
}

class _CustomSnoozeRowState extends State<_CustomSnoozeRow> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Custom minutes…',
              hintStyle: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            final mins = int.tryParse(_ctrl.text.trim());
            if (mins != null && mins > 0) widget.onSnooze(mins);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Set', style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
