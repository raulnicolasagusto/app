import 'package:app/src/math_canvas_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Math screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MathCanvasScreen()));

    expect(find.text('MathInk MVP'), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);
  });
}
