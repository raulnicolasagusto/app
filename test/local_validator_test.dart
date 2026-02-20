import 'package:app/src/local_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final LocalValidator validator = LocalValidator();

  test('validates 3x-4=11 -> x=15/3 -> x=5 as correct', () {
    final result = validator.validate(
      equation: '3x - 4 = 11',
      expectedFinal: 'x=5',
      contextHint: null,
      ocrLines: <String>['x = 15/3', 'x = 5'],
    );
    expect(result.correcto, isTrue);
    expect(result.wrongLines, isEmpty);
  });

  test('validates 6x=42 -> x=42/6 -> x=7 as correct', () {
    final result = validator.validate(
      equation: '6x = 42',
      expectedFinal: 'x=7',
      contextHint: null,
      ocrLines: <String>['x = 42/6', 'x = 7'],
    );
    expect(result.correcto, isTrue);
    expect(result.wrongLines, isEmpty);
  });

  test('validates 2x+5=17 -> x=12/2 -> x=6 as correct', () {
    final result = validator.validate(
      equation: '2x + 5 = 17',
      expectedFinal: 'x=6',
      contextHint: null,
      ocrLines: <String>['x = 12/2', 'x = 6'],
    );
    expect(result.correcto, isTrue);
    expect(result.wrongLines, isEmpty);
  });

  test('detects sign error and marks line', () {
    final result = validator.validate(
      equation: '2x + 5 = 17',
      expectedFinal: 'x=6',
      contextHint: null,
      ocrLines: <String>['2x = 17+5', 'x=22/2', 'x=11'],
    );
    expect(result.correcto, isFalse);
    expect(result.wrongLines, isNotEmpty);
    expect(result.wrongLines.first, 1);
  });

  test('supports y context hint', () {
    final result = validator.validate(
      equation: '2x + 2y = 20',
      expectedFinal: 'x=6',
      contextHint: 'y=4',
      ocrLines: <String>['2x + 8 = 20', '2x = 12', 'x = 6'],
    );
    expect(result.correcto, isTrue);
  });
}
