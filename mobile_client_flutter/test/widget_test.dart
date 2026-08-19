import 'package:flutter_test/flutter_test.dart';
import 'package:devcontrol_mobile/main.dart';

void main() {
  testWidgets('DevControlApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DevControlApp());
    expect(find.text('DevControl'), findsOneWidget);
  });
}
