import 'package:flutter_test/flutter_test.dart';
import 'package:neuronova/services/scoring_service.dart';

void main() {
  group('ScoringService Tests', () {
    final scoring = ScoringService.instance;

    test('Exact match returns 100%', () {
      const source = 'The quick brown fox jumps over the lazy dog';
      const spoken = 'The quick brown fox jumps over the lazy dog';
      final result = scoring.score(source, spoken);

      expect(result.percent, 100);
      expect(result.matched, result.total);
    });

    test('Empty spoken text returns 0%', () {
      const source = 'The quick brown fox';
      const spoken = '';
      final result = scoring.score(source, spoken);

      expect(result.percent, 0);
      expect(result.matched, 0);
    });

    test('Empty source text returns 0%', () {
      const source = '';
      const spoken = 'Some spoken words';
      final result = scoring.score(source, spoken);

      expect(result.percent, 0);
    });

    test('Partial match with correct ordering gives appropriate score', () {
      const source = 'Remember to take your medicine after breakfast every morning';
      const spoken = 'Remember to take medicine after breakfast';
      final result = scoring.score(source, spoken);

      expect(result.percent, greaterThan(60));
      expect(result.matched, greaterThan(4));
    });

    test('Fuzzy matching handles small typos or STT phoneme inaccuracies', () {
      const source = 'beautiful garden flowers blooming';
      const spoken = 'beautifull graden flowers blooming'; // minor edit distance
      final result = scoring.score(source, spoken);

      expect(result.percent, greaterThanOrEqualTo(75));
    });

    test('Devanagari (Hindi) script is preserved and scored correctly', () {
      const source = 'नमस्ते आप कैसे हैं। आज का दिन बहुत सुंदर है।';
      const spoken = 'नमस्ते आप कैसे हैं आज का दिन बहुत सुंदर है';
      final result = scoring.score(source, spoken);

      expect(result.percent, greaterThanOrEqualTo(90));
    });

    test('Motivational messages are appropriately tiered', () {
      expect(const ScoringResult(percent: 85, matched: 8, total: 10).motivationalMessage, contains('Wonderful'));
      expect(const ScoringResult(percent: 55, matched: 5, total: 10).motivationalMessage, contains('Good effort'));
      expect(const ScoringResult(percent: 20, matched: 2, total: 10).motivationalMessage, contains('Every attempt helps'));
    });
  });
}
