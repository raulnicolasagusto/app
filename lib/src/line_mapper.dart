import 'dart:math';

import 'models.dart';

class _StrokeBox {
  const _StrokeBox({
    required this.top,
    required this.bottom,
    required this.center,
    required this.height,
  });

  final double top;
  final double bottom;
  final double center;
  final double height;
}

class _LineCluster {
  _LineCluster(this.first) : items = <_StrokeBox>[first];

  final _StrokeBox first;
  final List<_StrokeBox> items;

  double get center => items.map(( _StrokeBox b) => b.center).reduce((a, b) => a + b) / items.length;
}

List<LineBand> buildLineBands({
  required List<StrokePath> strokes,
  required int targetLineCount,
}) {
  final int safeCount = max(1, targetLineCount);
  final List<_StrokeBox> boxes = _buildStrokeBoxes(strokes);
  if (boxes.isEmpty) {
    return _fallbackUniform(safeCount);
  }

  final List<_StrokeBox> sorted = List<_StrokeBox>.from(boxes)
    ..sort((a, b) => a.center.compareTo(b.center));
  final double threshold = _computeThreshold(sorted);

  final List<_LineCluster> clusters = <_LineCluster>[];
  for (final _StrokeBox box in sorted) {
    if (clusters.isEmpty) {
      clusters.add(_LineCluster(box));
      continue;
    }
    final _LineCluster current = clusters.last;
    if ((box.center - current.center).abs() <= threshold) {
      current.items.add(box);
    } else {
      clusters.add(_LineCluster(box));
    }
  }

  final List<LineBand> bands = <LineBand>[];
  for (int i = 0; i < clusters.length; i++) {
    final _LineCluster cluster = clusters[i];
    final _Range trimmed = _trimClusterVertical(cluster.items);
    bands.add(
      LineBand(
        index: i + 1,
        top: trimmed.top - 6,
        bottom: trimmed.bottom + 6,
      ),
    );
  }

  return bands.isEmpty ? _fallbackUniform(safeCount) : bands;
}

List<LineBand> _fallbackUniform(int count) {
  return List<LineBand>.generate(
    count,
    (int i) => LineBand(
      index: i + 1,
      top: (i * 40).toDouble(),
      bottom: (i * 40 + 30).toDouble(),
    ),
    growable: false,
  );
}

List<_StrokeBox> _buildStrokeBoxes(List<StrokePath> strokes) {
  final List<_StrokeBox> boxes = <_StrokeBox>[];
  for (final StrokePath stroke in strokes) {
    if (stroke.points.isEmpty) {
      continue;
    }
    double minY = stroke.points.first.dy;
    double maxY = stroke.points.first.dy;
    for (int i = 1; i < stroke.points.length; i++) {
      final double y = stroke.points[i].dy;
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
    }
    final double height = (maxY - minY).abs();
    boxes.add(
      _StrokeBox(
        top: minY,
        bottom: maxY,
        center: (minY + maxY) / 2,
        height: max(1.0, height),
      ),
    );
  }
  return boxes;
}

double _computeThreshold(List<_StrokeBox> sorted) {
  final List<double> heights = sorted.map(( _StrokeBox b) => b.height).toList()
    ..sort();
  final double median = heights[heights.length ~/ 2];
  final double dynamicValue = median * 2.2;
  return dynamicValue.clamp(36.0, 72.0);
}

class _Range {
  const _Range({
    required this.top,
    required this.bottom,
  });

  final double top;
  final double bottom;
}

_Range _trimClusterVertical(List<_StrokeBox> boxes) {
  final List<double> tops = boxes.map(( _StrokeBox b) => b.top).toList()..sort();
  final List<double> bottoms = boxes.map(( _StrokeBox b) => b.bottom).toList()..sort();
  final int p10 = ((tops.length - 1) * 0.1).round();
  final int p90 = ((tops.length - 1) * 0.9).round();
  final double trimmedTop = tops[p10];
  final double trimmedBottom = bottoms[p90];
  if (trimmedBottom <= trimmedTop) {
    final double minTop = tops.first;
    final double maxBottom = bottoms.last;
    return _Range(top: minTop, bottom: maxBottom);
  }
  return _Range(top: trimmedTop, bottom: trimmedBottom);
}
