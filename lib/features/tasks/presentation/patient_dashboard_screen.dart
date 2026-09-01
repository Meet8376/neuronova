import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../services/secure_settings_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/tts_service.dart';
import '../../patient/presentation/identity_card_sheet.dart';
import '../../patient/presentation/memory_gallery_sheet.dart';
import '../../patient/presentation/safe_zone_sheet.dart';
import '../../../services/offline_location_service.dart';
import 'hydration_sheet.dart';
import 'breathing_sheet.dart';
import 'add_task_sheet.dart';
import 'task_card.dart';
import 'all_tasks_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  final _repo   = TaskRepository();
  final _secure = SecureSettingsService.instance;
  final _tts    = TtsService.instance;

  String _patientName    = '';
  String _caregiverName  = 'Caregiver';
  String _caregiverPhone = '';
  List<Task> _todayTasks = [];
  bool _loading          = true;
  bool _ttsSpeaking      = false;

  Timer? _timer;
  DateTime _now = DateTime.now();

  StreamSubscription<LocationPoint>? _locationSub;
  bool _hasShownSafeZoneDialog = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _initTts();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _locationSub = OfflineLocationService.instance.locationStream.listen((point) {
      final isOutside = OfflineLocationService.instance.safeZoneStatus == SafeZoneStatus.outside;
      if (isOutside && !_hasShownSafeZoneDialog && mounted) {
        _hasShownSafeZoneDialog = true;
        _showSafeZoneSheet();
      } else if (!isOutside) {
        _hasShownSafeZoneDialog = false;
      }
    });
  }

  Future<void> _initTts() async {
    await _tts.init();
    _tts.onComplete = () { if (mounted) setState(() => _ttsSpeaking = false); };
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _timer?.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final name   = await _secure.getPatientName();
    final cName  = await _secure.getAdminName();
    final cPhone = await _secure.getCaregiverPhone();
    final tasks  = await _repo.getTodayTasks();
    if (!mounted) return;
    setState(() {
      _patientName    = name ?? '';
      _caregiverName  = cName ?? 'Caregiver';
      _caregiverPhone = cPhone;
      _todayTasks     = tasks;
      _loading        = false;
    });
  }

  // ── TTS ────────────────────────────────────────────────────────────────────

  Future<void> _toggleTts() async {
    if (_ttsSpeaking) {
      await _tts.stop();
      setState(() => _ttsSpeaking = false);
    } else {
      if (_todayTasks.isEmpty) {
        await _tts.speak('You have no tasks for today. Enjoy your day!');
      } else {
        final text = StringBuffer('You have ${_todayTasks.length} tasks today. ');
        for (final t in _todayTasks) {
          text.write('${t.name}. ');
        }
        await _tts.speak(text.toString());
      }
      setState(() => _ttsSpeaking = true);
    }
  }

  void _showIdentitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const IdentityCardSheet(),
    );
  }

  void _showHydrationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HydrationSheet(),
    );
  }

  void _showBreathingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BreathingSheet(),
    );
  }

  void _showMemoryGallerySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MemoryGallerySheet(),
    );
  }

  void _showSafeZoneSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SafeZoneSheet(),
    );
  }

  // ── Greeting ───────────────────────────────────────────────────────────────

  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _greetingEmoji {
    final h = _now.hour;
    if (h < 12) return '🌅';
    if (h < 17) return '☀️';
    return '🌙';
  }

  String get _dateTimeLine =>
      '${DateFormat('EEEE, d MMMM yyyy').format(_now)} · ${DateFormat('h:mm a').format(_now)}';

  // ── Task actions ───────────────────────────────────────────────────────────

  Future<void> _addTask() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(createdBy: TaskCreator.patient),
    );
    if (result == true) _load();
  }

  Future<void> _onTaskAction(Task task, String action) async {
    switch (action) {
      case 'done':
        await _repo.updateStatus(task.id, TaskStatus.done);
        await NotificationService.instance.cancel(task.notifId);
        break;
      case 'in_progress':
        await _repo.updateStatus(task.id, TaskStatus.inProgress);
        await NotificationService.instance.cancel(task.notifId);
        break;
      case 'delete':
        final confirm = await _showDeleteConfirm(task.name);
        if (confirm == true) {
          await _repo.deleteTask(task.id);
          await NotificationService.instance.cancel(task.notifId);
        }
        break;
    }
    _load();
  }

  Future<bool?> _showDeleteConfirm(String name) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete task?'),
          content: Text('Remove "$name"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Yes, Delete'),
            ),
          ],
        ),
      );

  // ── Emergency call ─────────────────────────────────────────────────────────

  Future<void> _callCaregiver() async {
    HapticFeedback.heavyImpact();
    await _tts.speak('Don\'t worry, help is right here. You can call your caregiver or send an emergency location message.');
    
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.emergency_rounded, color: AppColors.emergency, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Emergency SOS', style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.emergency)),
                      Text('Caregiver: $_caregiverName', style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Button 1: Direct Call
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final uri = Uri(scheme: 'tel', path: _caregiverPhone);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please call $_caregiverName manually: $_caregiverPhone'), backgroundColor: AppColors.error),
                  );
                }
              },
              icon: const Icon(Icons.phone_in_talk_rounded, size: 24),
              label: Text('Call $_caregiverName ($_caregiverPhone)', style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergency,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            // Button 2: Send Emergency SMS with GPS
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final msg = OfflineLocationService.instance.generateSmsLocationMessage(_patientName);
                final Uri smsUri = Uri.parse('sms:$_caregiverPhone?body=${Uri.encodeComponent(msg)}');
                try {
                  if (await canLaunchUrl(smsUri)) {
                    await launchUrl(smsUri);
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Emergency Location:\n$msg'), duration: const Duration(seconds: 5)),
                    );
                  }
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Location:\n$msg')),
                  );
                }
              },
              icon: const Icon(Icons.sms_rounded, size: 24, color: AppColors.primary),
              label: const Text('Send Emergency Location SMS', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                side: const BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            // Button 3: Guide Me Home
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showSafeZoneSheet();
              },
              icon: const Icon(Icons.navigation_rounded, color: AppColors.accent),
              label: const Text('Guide Me Home (Voice Compass)', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // ── Gradient hero header ──────────────────────────────────────────
          _HeroHeader(
            greeting: '$_greeting, $_patientName $_greetingEmoji',
            dateTimeLine: _dateTimeLine,
            caregiverName: _caregiverName,
            onSosTap: _callCaregiver,
            onWhoAmITap: _showIdentitySheet,
          ),

          // ── Quick action pills ────────────────────────────────────────────
          _QuickActions(
            onTtsToggle: _toggleTts,
            ttsSpeaking: _ttsSpeaking,
            onWhoAmITap: _showIdentitySheet,
            onHydrationTap: _showHydrationSheet,
            onBreatheTap: _showBreathingSheet,
            onMemoriesTap: _showMemoryGallerySheet,
            onSafeZoneTap: _showSafeZoneSheet,
          ),

          // ── Section header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text("Today's Tasks", style: AppTextStyles.sectionHeader(context)),
                const Spacer(),
                if (!_loading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_todayTasks.length}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Task list ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _todayTasks.isEmpty
                    ? _buildEmpty()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        children: [
                          ...(_todayTasks.map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TaskCard(
                                  task: t,
                                  isPatientView: true,
                                  onAction: (a) => _onTaskAction(t, a),
                                ),
                              ))),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AllTasksScreen()),
                              ).then((_) => _load()),
                              icon: const Icon(Icons.calendar_today_outlined, size: 18),
                              label: const Text('See all tasks'),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: 'add_task_fab',
        onPressed: _addTask,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 18),
          Text('All clear!',
              style: AppTextStyles.sectionHeader(context)
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('No tasks for today — tap + to add one',
              style: AppTextStyles.label(context)),
        ],
      ),
    );
  }
}

// ─── Gradient Hero Header ────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String greeting;
  final String dateTimeLine;
  final String caregiverName;
  final VoidCallback onSosTap;
  final VoidCallback onWhoAmITap;

  const _HeroHeader({
    required this.greeting,
    required this.dateTimeLine,
    required this.caregiverName,
    required this.onSosTap,
    required this.onWhoAmITap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: app name + SOS button
              Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.psychology_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CogniCare',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // SOS button — compact, top-right
                  _SosButton(
                    caregiverName: caregiverName,
                    onTap: onSosTap,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Greeting
              Text(
                greeting,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dateTimeLine,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 14),

              // Compassionate Reality Orientation Pill
              GestureDetector(
                onTap: onWhoAmITap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_pin_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '👤 Who Am I? · Tap for your story',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SOS Button ──────────────────────────────────────────────────────────────

class _SosButton extends StatefulWidget {
  final String caregiverName;
  final VoidCallback onTap;
  const _SosButton({required this.caregiverName, required this.onTap});

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD93025), Color(0xFFE74C3C)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.emergency.withValues(
                    alpha: 0.4 + 0.2 * _pulse.value),
                blurRadius: 10 + 4 * _pulse.value,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_rounded, color: Colors.white, size: 15),
              SizedBox(width: 5),
              Text(
                'SOS',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Action Row ─────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final VoidCallback onTtsToggle;
  final bool ttsSpeaking;
  final VoidCallback onWhoAmITap;
  final VoidCallback onHydrationTap;
  final VoidCallback onBreatheTap;
  final VoidCallback onMemoriesTap;
  final VoidCallback onSafeZoneTap;

  const _QuickActions({
    required this.onTtsToggle,
    required this.ttsSpeaking,
    required this.onWhoAmITap,
    required this.onHydrationTap,
    required this.onBreatheTap,
    required this.onMemoriesTap,
    required this.onSafeZoneTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          _QuickChip(
            icon: Icons.person_pin_rounded,
            label: 'Who Am I?',
            color: AppColors.primary,
            onTap: onWhoAmITap,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.share_location_rounded,
            label: 'Safe Zone',
            color: const Color(0xFFE11D48),
            onTap: onSafeZoneTap,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.photo_library_rounded,
            label: 'Memories',
            color: AppColors.accent,
            onTap: onMemoriesTap,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: ttsSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
            label: ttsSpeaking ? 'Stop' : 'Read tasks',
            color: AppColors.info,
            onTap: onTtsToggle,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.water_drop_outlined,
            label: 'Hydration',
            color: const Color(0xFF0288D1),
            onTap: onHydrationTap,
          ),
          const SizedBox(width: 8),
          _QuickChip(
            icon: Icons.self_improvement_rounded,
            label: 'Breathe',
            color: AppColors.success,
            onTap: onBreatheTap,
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
  }
}
