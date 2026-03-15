import 'package:flutter/foundation.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

import 'line_mapper.dart';
import 'models.dart';

class InkService {
  InkService() : _modelManager = DigitalInkRecognizerModelManager();

  final DigitalInkRecognizerModelManager _modelManager;
  static const String _primaryOcrTag = 'zxx-Zsym-x-math';
  static const String _fallbackOcrTag = 'en-US';
  static const int _topCandidates = 5;
  static const double _writingPadding = 12;
  static const int _minUsableMathScore = 3;

  Future<OcrBundle> recognize(List<StrokePath> userStrokes) async {
    if (userStrokes.isEmpty) {
      return const OcrBundle(rawJoinedText: '', lines: <String>[], lineResults: <OcrLineResult>[]);
    }

    final List<LineBand> lineBands = buildLineBands(
      strokes: userStrokes,
      targetLineCount: 1,
    );
    final List<List<StrokePath>> grouped = groupStrokesByLineBands(
      userStrokes,
      lineBands,
    );

    List<OcrLineResult> lineResults = <OcrLineResult>[];
    for (final String tag in <String>[_primaryOcrTag, _fallbackOcrTag]) {
      final bool ok = await _tryEnsureModelDownloaded(tag);
      if (!ok) {
        continue;
      }
      debugPrint('OCR_MODEL_USED: $tag');
      lineResults = await _recognizeGrouped(
        grouped,
        languageCode: tag,
      );
      if (lineResults.isNotEmpty && lineResults.any((OcrLineResult r) => r.bestText.trim().isNotEmpty)) {
        break;
      }
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

  Future<bool> _tryEnsureModelDownloaded(String languageCode) async {
    try {
      final bool downloaded = await _modelManager.isModelDownloaded(languageCode);
      debugPrint('OCR_MODEL_TRY[$languageCode]: downloaded=$downloaded');
      if (!downloaded) {
        await _modelManager.downloadModel(languageCode, isWifiRequired: false);
      }
      return true;
    } catch (error) {
      debugPrint('OCR_MODEL_DOWNLOAD_FAILED[$languageCode]: $error');
      return false;
    }
  }

  Future<List<OcrLineResult>> _recognizeGrouped(
    List<List<StrokePath>> grouped, {
    required String languageCode,
  }) async {
    final DigitalInkRecognizer recognizer = DigitalInkRecognizer(
      languageCode: languageCode,
    );
    final List<OcrLineResult> keptLineResults = <OcrLineResult>[];
    try {
      for (int lineIndex = 0; lineIndex < grouped.length; lineIndex++) {
        final List<StrokePath> lineStrokes = grouped[lineIndex];
        if (lineStrokes.isEmpty) {
          continue;
        }
        final _Bounds bounds = _computeBounds(lineStrokes);
        final Ink lineInk = _buildInk(
          lineStrokes,
          bounds,
          padding: _writingPadding,
        );
        if (lineInk.strokes.isEmpty) {
          continue;
        }
        final double writingWidth =
            (bounds.width + (_writingPadding * 2)).clamp(100, 2400).toDouble();
        final double writingHeight =
            (bounds.height + (_writingPadding * 2)).clamp(40, 1400).toDouble();
        debugPrint(
          'OCR_WRITING_AREA[L${lineIndex + 1}]: '
          'w=${writingWidth.toStringAsFixed(1)} h=${writingHeight.toStringAsFixed(1)} '
          'minX=${bounds.minX.toStringAsFixed(1)} minY=${bounds.minY.toStringAsFixed(1)} '
          'maxX=${bounds.maxX.toStringAsFixed(1)} maxY=${bounds.maxY.toStringAsFixed(1)}',
        );
        final DigitalInkRecognitionContext context = DigitalInkRecognitionContext(
          writingArea: WritingArea(width: writingWidth, height: writingHeight),
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

        final List<OcrCandidate> usableCandidates = candidates
            .where((OcrCandidate c) =>
                looksLikeMathText(c.text) && c.mathScore >= _minUsableMathScore)
            .toList(growable: false);
        _logLineCandidates(
          lineIndex + 1,
          candidates,
          usableCount: usableCandidates.length,
        );
        if (usableCandidates.isEmpty) {
          continue;
        }

        final OcrCandidate best = pickBestMathCandidate(usableCandidates);
        keptLineResults.add(
          OcrLineResult(
            lineIndex: keptLineResults.length + 1,
            bestText: best.text,
            candidates: usableCandidates,
          ),
        );
      }
    } finally {
      recognizer.close();
    }
    return keptLineResults;
  }

  Ink _buildInk(
    List<StrokePath> strokes,
    _Bounds bounds, {
    required double padding,
  }) {
    final Ink ink = Ink();
    final double maxX = bounds.width + (padding * 2);
    final double maxY = bounds.height + (padding * 2);
    for (final StrokePath strokePath in strokes) {
      if (strokePath.points.isEmpty || strokePath.timestamps.isEmpty) {
        continue;
      }
      final List<StrokePoint> points = <StrokePoint>[];
      for (int i = 0; i < strokePath.points.length; i++) {
        final int idx = i < strokePath.timestamps.length ? i : strokePath.timestamps.length - 1;
        final double x = (strokePath.points[i].dx - bounds.minX + padding).clamp(0, maxX).toDouble();
        final double y = (strokePath.points[i].dy - bounds.minY + padding).clamp(0, maxY).toDouble();
        points.add(
          StrokePoint(
            x: x,
            y: y,
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
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      width: (maxX - minX).abs().clamp(100, 2000).toDouble(),
      height: (maxY - minY).abs().clamp(40, 1000).toDouble(),
    );
  }

  void _logLineCandidates(
    int lineIndex,
    List<OcrCandidate> candidates, {
    required int usableCount,
  }) {
    final String joined = candidates
        .map((OcrCandidate c) =>
            '{"text":"${c.text.replaceAll('"', "'")}","score":${c.score.toStringAsFixed(4)},"mathScore":${c.mathScore}}')
        .join(', ');
    debugPrint('OCR_LINE_CANDIDATES[$lineIndex](usable=$usableCount): [$joined]');
  }
}

class _Bounds {
  const _Bounds({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.width,
    required this.height,
  });

  final double minX;
  final double minY;
  final double maxX;
  final double maxY;
  final double width;
  final double height;
}

bool looksLikeMathText(String text) {
  final String t = text.trim().toLowerCase();
  if (t.isEmpty) {
    return false;
  }
  final bool hasDigit = RegExp(r'\d').hasMatch(t);
  final bool hasEquals = t.contains('=');
  final bool hasOperator = RegExp(r'[\+\-\*/()]').hasMatch(t);
  if (hasDigit || hasEquals || hasOperator) {
    return true;
  }
  return false;
}

int scoreMathText(String text) {
  final String t = text.trim().toLowerCase();
  if (t.isEmpty) {
    return -100;
  }
  int score = 0;
  final bool hasDigit = RegExp(r'\d').hasMatch(t);
  final bool hasEquals = t.contains('=');
  final bool hasOperator = RegExp(r'[\+\-\*/()]').hasMatch(t);
  final bool hasAnyMathSignal = hasDigit || hasEquals || hasOperator;

  if (hasEquals) score += 5;
  if (hasDigit) score += 4;
  if (hasOperator) score += 3;
  if (hasAnyMathSignal && RegExp(r'[xy]').hasMatch(t)) score += 3;
  if (!hasAnyMathSignal && RegExp(r'^[a-z\s]+$').hasMatch(t)) score -= 12;
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
