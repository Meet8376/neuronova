import 'dart:async';
import 'dart:math';
import 'secure_settings_service.dart';
import 'tts_service.dart';

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
      };
}

enum SafeZoneStatus { inside, outside, unknown }

class OfflineLocationService {
  static final OfflineLocationService instance = OfflineLocationService._();
  OfflineLocationService._();

  final _secure = SecureSettingsService.instance;
  final _tts = TtsService.instance;

  // Default Home Base (e.g. Barabanki, UP / customizable)
  double _homeLat = 26.9272;
  double _homeLng = 81.1834;
  double _safeRadiusMeters = 300.0; // 300 meters default radius

  // Current Patient position
  double _currentLat = 26.9272;
  double _currentLng = 81.1834;
  
  bool _isTracking = false;
  Timer? _simulationTimer;
  final StreamController<LocationPoint> _locationStreamController =
      StreamController<LocationPoint>.broadcast();

  Stream<LocationPoint> get locationStream => _locationStreamController.stream;

  double get homeLat => _homeLat;
  double get homeLng => _homeLng;
  double get safeRadiusMeters => _safeRadiusMeters;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  bool get isTracking => _isTracking;

  Future<void> init() async {
    final savedLatStr = await _secure.read('home_lat');
    final savedLngStr = await _secure.read('home_lng');
    final savedRadiusStr = await _secure.read('safe_radius_meters');

    if (savedLatStr != null) _homeLat = double.tryParse(savedLatStr) ?? 26.9272;
    if (savedLngStr != null) _homeLng = double.tryParse(savedLngStr) ?? 81.1834;
    if (savedRadiusStr != null) {
      _safeRadiusMeters = double.tryParse(savedRadiusStr) ?? 300.0;
    }

    _currentLat = _homeLat;
    _currentLng = _homeLng;
  }

  Future<void> setHomeLocation(double lat, double lng, {double? radiusMeters}) async {
    _homeLat = lat;
    _homeLng = lng;
    if (radiusMeters != null) _safeRadiusMeters = radiusMeters;

    await _secure.write('home_lat', lat.toString());
    await _secure.write('home_lng', lng.toString());
    await _secure.write('safe_radius_meters', _safeRadiusMeters.toString());
  }

  void updateCurrentLocation(double lat, double lng) {
    _currentLat = lat;
    _currentLng = lng;

    final point = LocationPoint(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
    );
    _locationStreamController.add(point);

    _checkSafeZoneAlert();
  }

  /// Haversine Formula for Offline GPS Distance Calculation
  double calculateDistanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return r * c;
  }

  /// Calculates bearing angle in degrees from current position to target (Home)
  double calculateBearing(
    double startLat,
    double startLng,
    double destLat,
    double destLng,
  ) {
    final startLatRad = _toRadians(startLat);
    final startLngRad = _toRadians(startLng);
    final destLatRad = _toRadians(destLat);
    final destLngRad = _toRadians(destLng);

    final dLng = destLngRad - startLngRad;

    final y = sin(dLng) * cos(destLatRad);
    final x = cos(startLatRad) * sin(destLatRad) -
        sin(startLatRad) * cos(destLatRad) * cos(dLng);

    final brng = atan2(y, x);
    final brngDeg = (brng * 180 / pi + 360) % 360;
    return brngDeg;
  }

  /// Converts bearing angle to human readable cardinal direction
  String getCardinalDirection(double bearingDegrees) {
    const directions = ['North', 'North-East', 'East', 'South-East', 'South', 'South-West', 'West', 'North-West'];
    final index = ((bearingDegrees + 22.5) % 360 / 45).floor();
    return directions[index];
  }

  double get distanceToHomeMeters =>
      calculateDistanceMeters(_currentLat, _currentLng, _homeLat, _homeLng);

  SafeZoneStatus get safeZoneStatus {
    final dist = distanceToHomeMeters;
    if (dist <= _safeRadiusMeters) return SafeZoneStatus.inside;
    return SafeZoneStatus.outside;
  }

  void _checkSafeZoneAlert() {
    if (safeZoneStatus == SafeZoneStatus.outside) {
      final dist = distanceToHomeMeters.round();
      final bearing = calculateBearing(_currentLat, _currentLng, _homeLat, _homeLng);
      final dir = getCardinalDirection(bearing);

      _tts.speak(
        'Alert: You are $dist meters away from home, outside your safe zone. '
        'Please walk $dir towards your home.',
      );
    }
  }

  /// Demo simulator for testing offline GPS movement on Desktop / Emulators
  void toggleDemoMovementSimulation() {
    if (_isTracking) {
      _simulationTimer?.cancel();
      _isTracking = false;
    } else {
      _isTracking = true;
      double offsetAngle = 0;

      _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        offsetAngle += 0.3;
        // Simulate walking 10-400 meters away from home in a circle/path
        final distanceOffset = 50 + (sin(offsetAngle) * 350); 
        final latDelta = (distanceOffset / 111000) * cos(offsetAngle);
        final lngDelta = (distanceOffset / (111000 * cos(_toRadians(_homeLat)))) * sin(offsetAngle);

        updateCurrentLocation(_homeLat + latDelta, _homeLng + lngDelta);
      });
    }
  }

  /// Generate Google Maps location link formatted for offline SMS to Caregiver
  String generateSmsLocationMessage(String patientName) {
    final mapsUrl = 'https://maps.google.com/?q=$_currentLat,$_currentLng';
    final dist = distanceToHomeMeters.round();
    final status = safeZoneStatus == SafeZoneStatus.outside ? 'OUTSIDE SAFE ZONE' : 'IN SAFE ZONE';
    
    return 'EMERGENCY LOCATION ALERT ($status):\n'
        'Patient $patientName is $dist meters from home.\n'
        'Current Position: $mapsUrl\n'
        'Lat: ${_currentLat.toStringAsFixed(5)}, Lng: ${_currentLng.toStringAsFixed(5)}';
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}
