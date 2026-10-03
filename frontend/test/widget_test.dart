import 'package:flutter_test/flutter_test.dart';
import 'package:citypulse/main.dart';

void main() {
  testWidgets('CityPulse app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CityPulseApp());
    expect(find.byType(CityPulseApp), findsOneWidget);
  });
}
