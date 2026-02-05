import 'package:flutter_test/flutter_test.dart';
import 'package:clarity/app.dart';

void main() {
  testWidgets('Home shows Clarity in app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const ClarityApp());
    await tester.pump();

    expect(find.text('Clarity'), findsOneWidget);
  });
}
