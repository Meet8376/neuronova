import 'package:flutter_test/flutter_test.dart';
import 'package:neuronova/services/offline_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineLocationService Tests', () {
    final locationService = OfflineLocationService.instance;

    test('Haversine distance returns ~0 meters for identical coordinates', () {
      final distance = locationService.calculateDistanceMeters(
        26.9272, 81.1834,
        26.9272, 81.1834,
      );
      expect(distance, closeTo(0.0, 0.1));
    });

    test('Haversine distance computes accurate distance for known points', () {
      // Barabanki (26.9272, 81.1834) to Lucknow Charbagh (~26.8324, 80.9177) ~28km
      final distance = locationService.calculateDistanceMeters(
        26.9272, 81.1834,
        26.8324, 80.9177,
      );
      expect(distance, greaterThan(25000));
      expect(distance, lessThan(32000));
    });

    test('Cardinal directions are computed correctly from bearings', () {
      expect(locationService.getCardinalDirection(0), 'North');
      expect(locationService.getCardinalDirection(45), 'North-East');
      expect(locationService.getCardinalDirection(90), 'East');
      expect(locationService.getCardinalDirection(135), 'South-East');
      expect(locationService.getCardinalDirection(180), 'South');
      expect(locationService.getCardinalDirection(225), 'South-West');
      expect(locationService.getCardinalDirection(270), 'West');
      expect(locationService.getCardinalDirection(315), 'North-West');
      expect(locationService.getCardinalDirection(360), 'North');
    });

    test('Bearing calculation from south to north returns 0 degrees', () {
      final bearing = locationService.calculateBearing(
        26.0, 81.0,
        27.0, 81.0,
      );
      expect(bearing, closeTo(0.0, 1.0));
    });

    test('SMS emergency message formats Google Maps URL and coordinates', () {
      final msg = locationService.generateSmsLocationMessage('Rajan');
      expect(msg, contains('EMERGENCY LOCATION ALERT'));
      expect(msg, contains('Rajan'));
      expect(msg, contains('https://maps.google.com/?q='));
      expect(msg, contains('Lat:'));
      expect(msg, contains('Lng:'));
    });
  });
}
