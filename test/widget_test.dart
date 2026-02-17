import 'package:app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Math screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MathFightApp());

    expect(find.text('Math Fight MVP'), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);
  });
}
