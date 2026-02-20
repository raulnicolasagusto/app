import 'package:app/src/line_mapper.dart';
import 'package:app/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StrokePath strokeAtY(double y) {
    return StrokePath(
      points: <Offset>[
        Offset(10, y),
        Offset(40, y + 4),
      ],
      timestamps: <int>[0, 1],
    );
  }

  test('buildLineBands returns sorted bands for separated lines', () {
    final List<LineBand> bands = buildLineBands(
      strokes: <StrokePath>[
        strokeAtY(20),
        strokeAtY(22),
        strokeAtY(80),
        strokeAtY(82),
        strokeAtY(140),
      ],
      targetLineCount: 3,
    );

    expect(bands.length, 3);
    expect(bands[0].center < bands[1].center, isTrue);
    expect(bands[1].center < bands[2].center, isTrue);
    expect(bands[0].index, 1);
    expect(bands[2].index, 3);
  });

  test('buildLineBands does not invent extra lines when target is bigger', () {
    final List<LineBand> bands = buildLineBands(
      strokes: <StrokePath>[
        strokeAtY(20),
        strokeAtY(100),
      ],
      targetLineCount: 4,
    );

    expect(bands.length, 2);
  });

  test('buildLineBands falls back safely with empty strokes', () {
    final List<LineBand> bands = buildLineBands(
      strokes: <StrokePath>[],
      targetLineCount: 3,
    );

    expect(bands.length, 3);
    expect(bands[0].center < bands[1].center, isTrue);
  });

  test('buildLineBands avoids over-segmentation in fraction-like strokes', () {
    final List<LineBand> bands = buildLineBands(
      strokes: <StrokePath>[
        strokeAtY(60),
        strokeAtY(62),
        strokeAtY(95),
        strokeAtY(122),
      ],
      targetLineCount: 4,
    );

    expect(bands.length, lessThanOrEqualTo(3));
  });
}
