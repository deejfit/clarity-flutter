import 'package:flutter_test/flutter_test.dart';
import 'package:clarity/app.dart';

void main() {
  testWidgets('Home shows Clarity in app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const ClarityApp());
    await tester.pump();
    expect(find.text('Clarity'), findsOneWidget);

    // Allow storage load (or timeout) to complete so no pending timers remain.
    await tester.pumpAndSettle(const Duration(seconds: 6));
    expect(find.text('Clarity'), findsOneWidget);
  });
}
