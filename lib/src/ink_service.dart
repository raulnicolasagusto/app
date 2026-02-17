import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

import 'models.dart';

class InkService {
  InkService() : _modelManager = DigitalInkRecognizerModelManager();

  final DigitalInkRecognizerModelManager _modelManager;

  static const String _mathTag = 'zxx-Zsym-x-math';
  static const String _fallbackTag = 'en-US';

  Future<String> recognize(List<StrokePath> userStrokes) async {
    if (userStrokes.isEmpty) {
      return '';
    }

    final Ink ink = Ink();
    for (final StrokePath stroke in userStrokes) {
      if (stroke.points.isEmpty || stroke.timestamps.isEmpty) {
        continue;
      }
      final List<StrokePoint> points = <StrokePoint>[];
      for (int i = 0; i < stroke.points.length; i++) {
        final int safeIndex = i < stroke.timestamps.length
            ? i
            : stroke.timestamps.length - 1;
        final int timestamp = safeIndex >= 0 ? stroke.timestamps[safeIndex] : 0;
        points.add(
          StrokePoint(
            x: stroke.points[i].dx,
            y: stroke.points[i].dy,
            t: timestamp,
          ),
        );
      }
      if (points.isNotEmpty) {
        final Stroke stroke = Stroke()..points = points;
        ink.strokes.add(stroke);
      }
    }

    if (ink.strokes.isEmpty) {
      return '';
    }

    final String languageCode = await _resolveLanguageCode();
    final DigitalInkRecognizer recognizer = DigitalInkRecognizer(
      languageCode: languageCode,
    );
    try {
      final List<RecognitionCandidate> candidates = await recognizer.recognize(
        ink,
      );
      if (candidates.isEmpty) {
        return '';
      }
      return candidates.first.text.trim();
    } finally {
      recognizer.close();
    }
  }

  Future<String> _resolveLanguageCode() async {
    try {
      final bool downloaded = await _modelManager.isModelDownloaded(_mathTag);
      if (!downloaded) {
        await _modelManager.downloadModel(_mathTag, isWifiRequired: false);
      }
      return _mathTag;
    } catch (_) {
      final bool downloaded = await _modelManager.isModelDownloaded(_fallbackTag);
      if (!downloaded) {
        await _modelManager.downloadModel(_fallbackTag, isWifiRequired: false);
      }
      return _fallbackTag;
    }
  }
}
