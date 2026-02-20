import 'package:flutter/foundation.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

import 'line_mapper.dart';
import 'models.dart';

class InkService {
  InkService() : _modelManager = DigitalInkRecognizerModelManager();

  final DigitalInkRecognizerModelManager _modelManager;
  static const String _ocrTag = 'en-US';
  static const int _topCandidates = 5;

  Future<OcrBundle> recognize(List<StrokePath> userStrokes) async {
    if (userStrokes.isEmpty) {
      return const OcrBundle(rawJoinedText: '', lines: <String>[], lineResults: <OcrLineResult>[]);
    }

    await _ensureModelDownloaded();
    final List<LineBand> lineBands = buildLineBands(strokes: userStrokes, targetLineCount: 1);
    final List<List<StrokePath>> grouped = groupStrokesByLineBands(userStrokes, lineBands);
    final DigitalInkRecognizer recognizer = DigitalInkRecognizer(languageCode: _ocrTag);

    final List<OcrLineResult> lineResults = <OcrLineResult>[];
    try {
      for (int lineIndex = 0; lineIndex < grouped.length; lineIndex++) {
        final List<StrokePath> lineStrokes = grouped[lineIndex];
        if (lineStrokes.isEmpty) {
          continue;
        }
        final Ink lineInk = _buildInk(lineStrokes);
        if (lineInk.strokes.isEmpty) {
          continue;
        }
        final _Bounds bounds = _computeBounds(lineStrokes);
        final DigitalInkRecognitionContext context = DigitalInkRecognitionContext(
          writingArea: WritingArea(width: bounds.width, height: bounds.height),
        );
        final List<RecognitionCandidate> raw =
            await recognizer.recognize(lineInk, context: context);
        if (raw.isEmpty) {
          continue;
        }
        final List<OcrCandidate> candidates = raw
            .take(_topCandidates)
            .map((RecognitionCandidate c) => OcrCandidate(
                  text: c.text.trim(),
                  score: c.score,
                  mathScore: scoreMathText(c.text),
                ))
            .toList(growable: false);
        _logLineCandidates(lineIndex + 1, candidates);
        final OcrCandidate best = pickBestMathCandidate(candidates);
        lineResults.add(
          OcrLineResult(
            lineIndex: lineIndex + 1,
            bestText: best.text,
            candidates: candidates,
          ),
        );
      }
    } finally {
      recognizer.close();
    }

    lineResults.sort((OcrLineResult a, OcrLineResult b) => a.lineIndex.compareTo(b.lineIndex));
    final List<String> lines = lineResults
        .map((OcrLineResult line) => line.bestText)
        .where((String text) => text.trim().isNotEmpty)
        .toList(growable: false);
    return OcrBundle(
      rawJoinedText: lines.join('\n'),
      lines: lines,
      lineResults: lineResults,
    );
  }

  Future<void> _ensureModelDownloaded() async {
    final bool downloaded = await _modelManager.isModelDownloaded(_ocrTag);
    if (!downloaded) {
      await _modelManager.downloadModel(_ocrTag, isWifiRequired: false);
    }
  }

  Ink _buildInk(List<StrokePath> strokes) {
    final Ink ink = Ink();
    for (final StrokePath strokePath in strokes) {
      if (strokePath.points.isEmpty || strokePath.timestamps.isEmpty) {
        continue;
      }
      final List<StrokePoint> points = <StrokePoint>[];
      for (int i = 0; i < strokePath.points.length; i++) {
        final int idx = i < strokePath.timestamps.length ? i : strokePath.timestamps.length - 1;
        points.add(
          StrokePoint(
            x: strokePath.points[i].dx,
            y: strokePath.points[i].dy,
            t: idx >= 0 ? strokePath.timestamps[idx] : 0,
          ),
        );
      }
      if (points.isNotEmpty) {
        final Stroke stroke = Stroke()..points = points;
        ink.strokes.add(stroke);
      }
    }
    return ink;
  }

  _Bounds _computeBounds(List<StrokePath> strokes) {
    double minX = strokes.first.points.first.dx;
    double minY = strokes.first.points.first.dy;
    double maxX = minX;
    double maxY = minY;
    for (final StrokePath stroke in strokes) {
      for (final point in stroke.points) {
        if (point.dx < minX) minX = point.dx;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dy > maxY) maxY = point.dy;
      }
    }
    return _Bounds(
      width: (maxX - minX).abs().clamp(100, 2000).toDouble(),
      height: (maxY - minY).abs().clamp(40, 1000).toDouble(),
    );
  }

  void _logLineCandidates(int lineIndex, List<OcrCandidate> candidates) {
    final String joined = candidates
        .map((OcrCandidate c) =>
            '{"text":"${c.text.replaceAll('"', "'")}","score":${c.score.toStringAsFixed(4)},"mathScore":${c.mathScore}}')
        .join(', ');
    debugPrint('OCR_LINE_CANDIDATES[$lineIndex]: [$joined]');
  }
}

class _Bounds {
  const _Bounds({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;
}

int scoreMathText(String text) {
  final String t = text.trim().toLowerCase();
  if (t.isEmpty) {
    return -100;
  }
  int score = 0;
  if (t.contains('=')) score += 5;
  if (RegExp(r'\d').hasMatch(t)) score += 4;
  if (RegExp(r'[xy]').hasMatch(t)) score += 3;
  if (RegExp(r'[\+\-\*/()]').hasMatch(t)) score += 3;
  if (RegExp(r'^[a-z\s]+$').hasMatch(t)) score -= 8;
  return score;
}

OcrCandidate pickBestMathCandidate(List<OcrCandidate> candidates) {
  OcrCandidate best = candidates.first;
  for (int i = 1; i < candidates.length; i++) {
    final OcrCandidate c = candidates[i];
    if (c.mathScore > best.mathScore) {
      best = c;
      continue;
    }
    if (c.mathScore == best.mathScore && c.score < best.score) {
      best = c;
    }
  }
  return best;
}

List<List<StrokePath>> groupStrokesByLineBands(List<StrokePath> strokes, List<LineBand> bands) {
  if (bands.isEmpty) {
    return <List<StrokePath>>[List<StrokePath>.from(strokes)];
  }
  final List<List<StrokePath>> grouped =
      List<List<StrokePath>>.generate(bands.length, (_) => <StrokePath>[]);
  for (final StrokePath stroke in strokes) {
    if (stroke.points.isEmpty) {
      continue;
    }
    double centerY = 0;
    for (final point in stroke.points) {
      centerY += point.dy;
    }
    centerY /= stroke.points.length;
    int bestIndex = 0;
    double bestDistance = (centerY - bands.first.center).abs();
    for (int i = 1; i < bands.length; i++) {
      final double distance = (centerY - bands[i].center).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    grouped[bestIndex].add(stroke);
  }
  return grouped.where((List<StrokePath> line) => line.isNotEmpty).toList(growable: false);
}
