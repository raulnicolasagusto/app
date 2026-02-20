import 'package:app/src/ink_service.dart';
import 'package:app/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StrokePath strokeAtY(double y) {
    return StrokePath(
      points: <Offset>[
        Offset(10, y),
        Offset(80, y + 2),
      ],
      timestamps: <int>[0, 1],
    );
  }

  test('groupStrokesByLineBands segments into separate lines', () {
    final List<LineBand> bands = <LineBand>[
      const LineBand(index: 1, top: 10, bottom: 40),
      const LineBand(index: 2, top: 80, bottom: 120),
    ];
    final List<List<StrokePath>> grouped = groupStrokesByLineBands(
      <StrokePath>[strokeAtY(20), strokeAtY(100)],
      bands,
    );

    expect(grouped.length, 2);
    expect(grouped[0].length, 1);
    expect(grouped[1].length, 1);
  });

  test('pickBestMathCandidate prefers math-like text', () {
    final OcrCandidate best = pickBestMathCandidate(
      const <OcrCandidate>[
        OcrCandidate(text: 'animal migration', score: 0.9, mathScore: -6),
        OcrCandidate(text: 'x=15/3', score: 1.3, mathScore: 12),
      ],
    );
    expect(best.text, 'x=15/3');
    expect(scoreMathText('x=15/3') > scoreMathText('blackberry'), isTrue);
  });
}
