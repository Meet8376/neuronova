import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/offline_location_service.dart';
import '../../../services/secure_settings_service.dart';
import '../../../services/tts_service.dart';

class SafeZoneSheet extends StatefulWidget {
  const SafeZoneSheet({super.key});

  @override
  State<SafeZoneSheet> createState() => _SafeZoneSheetState();
}

class _SafeZoneSheetState extends State<SafeZoneSheet> {
  final _locationService = OfflineLocationService.instance;
  final _secure = SecureSettingsService.instance;
  final _tts = TtsService.instance;

  StreamSubscription<LocationPoint>? _subscription;
  String _patientName = 'Patient';
  String _caregiverPhone = '';

  @override
  void initState() {
    super.initState();
    _loadInfo();
    _subscription = _locationService.locationStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    final pName = await _secure.getPatientName();
    final phone = await _secure.getCaregiverPhone();
    if (!mounted) return;
    setState(() {
      _patientName = pName ?? 'Patient';
      _caregiverPhone = phone;
    });
  }

  void _guideHomeVoice() {
    final dist = _locationService.distanceToHomeMeters.round();
    final bearing = _locationService.calculateBearing(
      _locationService.currentLat,
      _locationService.currentLng,
      _locationService.homeLat,
      _locationService.homeLng,
    );
    final dir = _locationService.getCardinalDirection(bearing);

    if (_locationService.safeZoneStatus == SafeZoneStatus.inside) {
      _tts.speak('You are safe at home! You are $dist meters from your home base.');
    } else {
      _tts.speak(
        'Guide Me Home: You are $dist meters away from home. '
        'Turn towards $dir and walk straight to return to your family.',
      );
    }
  }

  Future<void> _sendSmsAlert() async {
    final msg = _locationService.generateSmsLocationMessage(_patientName);
    final Uri smsUri = Uri.parse('sms:$_caregiverPhone?body=${Uri.encodeComponent(msg)}');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (!mounted) return;
        await Clipboard.setData(ClipboardData(text: msg));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency message copied to clipboard!\nCaregiver: $_caregiverPhone'),
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: msg));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency message copied to clipboard!\n$msg'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dist = _locationService.distanceToHomeMeters.round();
    final isOutside = _locationService.safeZoneStatus == SafeZoneStatus.outside;
    final bearing = _locationService.calculateBearing(
      _locationService.currentLat,
      _locationService.currentLng,
      _locationService.homeLat,
      _locationService.homeLng,
    );
    final directionStr = _locationService.getCardinalDirection(bearing);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBgWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.share_location_rounded, color: AppColors.primary, size: 26),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Safe Return 🏡',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOutside ? AppColors.error.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOutside ? AppColors.error : AppColors.success,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOutside ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                        color: isOutside ? AppColors.error : AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOutside ? 'Outside Safe Zone' : 'Safe at Home',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isOutside ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Offline GPS tracking & directional safe return compass',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Offline Custom Vector Radar Map Widget
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Dark tactical map canvas
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.card,
              border: Border.all(color: isOutside ? AppColors.error : AppColors.primary, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(
                painter: _OfflineRadarPainter(
                  homeLat: _locationService.homeLat,
                  homeLng: _locationService.homeLng,
                  currentLat: _locationService.currentLat,
                  currentLng: _locationService.currentLng,
                  safeRadiusMeters: _locationService.safeRadiusMeters,
                  distanceMeters: dist.toDouble(),
                  bearingDegrees: bearing,
                  isOutside: isOutside,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Distance & Direction Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Distance to Home', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      '$dist m',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),
                Container(height: 30, width: 1, color: AppColors.divider),
                Column(
                  children: [
                    const Text('Direction', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      directionStr,
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Container(height: 30, width: 1, color: AppColors.divider),
                Column(
                  children: [
                    const Text('Safe Radius', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      '${_locationService.safeRadiusMeters.round()} m',
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Guide Me Home & Caregiver SMS
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _guideHomeVoice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.volume_up_rounded, size: 22),
                  label: const Text('Guide Me Home', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sendSmsAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.sms_rounded, size: 20),
                  label: const Text('SMS Caregiver', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Demo GPS Simulation Button
          TextButton.icon(
            onPressed: () {
              _locationService.toggleDemoMovementSimulation();
              setState(() {});
            },
            icon: Icon(
              _locationService.isTracking ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            label: Text(
              _locationService.isTracking ? 'Stop GPS Movement Simulation' : 'Simulate Walking Outside Safe Zone (Demo)',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _OfflineRadarPainter extends CustomPainter {
  final double homeLat;
  final double homeLng;
  final double currentLat;
  final double currentLng;
  final double safeRadiusMeters;
  final double distanceMeters;
  final double bearingDegrees;
  final bool isOutside;

  _OfflineRadarPainter({
    required this.homeLat,
    required this.homeLng,
    required this.currentLat,
    required this.currentLng,
    required this.safeRadiusMeters,
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.isOutside,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxDrawRadius = min(size.width, size.height) / 2 - 20;

    // Grid lines (Tactical offline radar look)
    final gridPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, maxDrawRadius * 0.33, gridPaint);
    canvas.drawCircle(center, maxDrawRadius * 0.66, gridPaint);
    canvas.drawCircle(center, maxDrawRadius, gridPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxDrawRadius), Offset(center.dx, center.dy + maxDrawRadius), gridPaint);
    canvas.drawLine(Offset(center.dx - maxDrawRadius, center.dy), Offset(center.dx + maxDrawRadius, center.dy), gridPaint);

    // Safe Radius Ring
    final safeRingRadius = maxDrawRadius * 0.6;
    final safeRingPaint = Paint()
      ..color = isOutside ? const Color(0xFFEF4444) : const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final safeFillPaint = Paint()
      ..color = (isOutside ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, safeRingRadius, safeFillPaint);
    canvas.drawCircle(center, safeRingRadius, safeRingPaint);

    // Home Base Pin (Center)
    final homePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, homePaint);

    TextPainter(
      text: const TextSpan(
        text: '🏠 HOME',
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, Offset(center.dx - 18, center.dy + 12));

    // Patient Position
    final scale = safeRingRadius / safeRadiusMeters;
    final drawDist = min(distanceMeters * scale, maxDrawRadius - 10);
    final radAngle = (bearingDegrees - 90) * pi / 180;

    final patientX = center.dx + drawDist * cos(radAngle);
    final patientY = center.dy + drawDist * sin(radAngle);
    final patientPos = Offset(patientX, patientY);

    // Dotted line connecting Home to Patient
    final linePaint = Paint()
      ..color = isOutside ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, patientPos, linePaint);

    // Patient Pin
    final patientPaint = Paint()
      ..color = isOutside ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(patientPos, 10, patientPaint);

    final patientPulsePaint = Paint()
      ..color = (isOutside ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(patientPos, 18, patientPulsePaint);

    TextPainter(
      text: TextSpan(
        text: '📍 YOU (${distanceMeters.round()}m)',
        style: TextStyle(
          color: isOutside ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          fontFamily: 'Nunito',
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, Offset(patientPos.dx - 30, patientPos.dy - 28));
  }

  @override
  bool shouldRepaint(covariant _OfflineRadarPainter oldDelegate) => true;
}
