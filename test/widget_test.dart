import 'package:flutter_test/flutter_test.dart';
import 'package:neuronova/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CogniCareApp());
    // Verify the initial splash screen renders
    expect(find.text('CogniCare'), findsOneWidget);
    expect(find.text('Your memory companion'), findsOneWidget);

    // Pump past the navigation delay
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
  });
}
