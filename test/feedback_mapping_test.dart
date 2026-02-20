import 'package:app/src/feedback_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildWrongLineNumbers clamps deduplicates and adds final line', () {
    final List<int> result = buildWrongLineNumbers(
      wrongLines: <int>[-1, 2, 2, 9],
      lineBandCount: 3,
      finalResultLine: 3,
      includeFinalLine: true,
    );

    expect(result, <int>[1, 2, 3]);
  });

  test('buildWrongLineNumbers skips final line when requested', () {
    final List<int> result = buildWrongLineNumbers(
      wrongLines: <int>[2],
      lineBandCount: 3,
      finalResultLine: 3,
      includeFinalLine: false,
    );

    expect(result, <int>[2]);
  });
}
