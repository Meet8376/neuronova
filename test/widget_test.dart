import 'package:flutter_test/flutter_test.dart';
import 'package:cognicare_prototype/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CogniCareApp());
    // Just verify the app renders without crashing
    expect(find.byType(CogniCareApp), findsOneWidget);
  });
}
