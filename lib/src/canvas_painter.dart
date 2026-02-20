import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models.dart';

class MathCanvasPainter extends CustomPainter {
  MathCanvasPainter({
    required this.userStrokes,
    required this.wrongLineNumbers,
    required this.lineBands,
    required this.finalResultLine,
    required this.showCheck,
    required this.showFinalX,
    required this.checkProgress,
    required this.correctionText,
  });

  final List<StrokePath> userStrokes;
  final List<int> wrongLineNumbers;
  final List<LineBand> lineBands;
  final int finalResultLine;
  final bool showCheck;
  final bool showFinalX;
  final double checkProgress;
  final String correctionText;

  @override
  void paint(Canvas canvas, Size size) {
    _paintPaperBackground(canvas, size);
    _paintUserStrokes(canvas);

    final Rect? bounds = _computeStrokeBounds();
    if (bounds == null) {
      return;
    }

    _paintStrikeLines(canvas, bounds);
    _paintCheckMark(canvas, bounds);
    _paintFinalX(canvas, bounds);
    _paintCorrectionText(canvas, size, bounds);
  }

  void _paintPaperBackground(Canvas canvas, Size size) {
    final Paint fill = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, fill);

    final Paint linePaint = Paint()
      ..color = const Color(0xFFE4EAF3)
      ..strokeWidth = 1;
    const double spacing = 34;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _paintUserStrokes(Canvas canvas) {
    final Paint strokePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (final StrokePath stroke in userStrokes) {
      if (stroke.points.length < 2) {
        if (stroke.points.length == 1) {
          canvas.drawCircle(stroke.points.first, 2.5, strokePaint);
        }
        continue;
      }
      final Path path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        final Offset point = stroke.points[i];
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  void _paintStrikeLines(Canvas canvas, Rect bounds) {
    if (wrongLineNumbers.isEmpty) {
      return;
    }
    final Paint strikePaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final int rawLineNumber in wrongLineNumbers) {
      final double y = _lineCenterY(bounds, rawLineNumber);
      final double startX = bounds.left - 10;
      final double endX = bounds.right + 18;
      canvas.drawLine(Offset(startX, y), Offset(endX, y), strikePaint);
    }
  }

  void _paintCheckMark(Canvas canvas, Rect bounds) {
    if (!showCheck || checkProgress <= 0) {
      return;
    }
    final double y = _lineCenterY(bounds, finalResultLine);
    final Offset start = Offset(bounds.right + 16, y + 8);
    final Offset mid = Offset(bounds.right + 24, y + 20);
    final Offset end = Offset(bounds.right + 42, y - 4);

    final Path checkPath = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(mid.dx, mid.dy)
      ..lineTo(end.dx, end.dy);

    final ui.PathMetric metric = checkPath.computeMetrics().first;
    final Path animatedPath = metric.extractPath(
      0,
      metric.length * checkProgress.clamp(0, 1),
    );
    final Paint paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(animatedPath, paint);
  }

  void _paintFinalX(Canvas canvas, Rect bounds) {
    if (!showFinalX) {
      return;
    }
    final double y = _lineCenterY(bounds, finalResultLine);
    final Paint paint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Offset a = Offset(bounds.right + 16, y - 10);
    final Offset b = Offset(bounds.right + 40, y + 14);
    final Offset c = Offset(bounds.right + 40, y - 10);
    final Offset d = Offset(bounds.right + 16, y + 14);
    canvas.drawLine(a, b, paint);
    canvas.drawLine(c, d, paint);
  }

  void _paintCorrectionText(Canvas canvas, Size size, Rect bounds) {
    final String text = correctionText.trimRight();
    if (text.isEmpty) {
      return;
    }
    final TextSpan span = TextSpan(
      text: text,
      style: GoogleFonts.patrickHand(
        color: const Color(0xFF2E7D32),
        fontSize: 26,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    );
    final TextPainter textPainter = TextPainter(
      text: span,
      textDirection: ui.TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: size.width - 24);
    final double anchorBase = lineBands.isEmpty
        ? bounds.bottom
        : lineBands
            .map((LineBand band) => band.bottom)
            .reduce((double a, double b) => a > b ? a : b);
    final Offset anchor = Offset(
      12,
      (anchorBase + 22).clamp(0, size.height - textPainter.height),
    );
    textPainter.paint(canvas, anchor);
  }

  Rect? _computeStrokeBounds() {
    double? left;
    double? top;
    double? right;
    double? bottom;
    for (final StrokePath stroke in userStrokes) {
      for (final Offset point in stroke.points) {
        left = left == null ? point.dx : (point.dx < left ? point.dx : left);
        top = top == null ? point.dy : (point.dy < top ? point.dy : top);
        right = right == null ? point.dx : (point.dx > right ? point.dx : right);
        bottom = bottom == null ? point.dy : (point.dy > bottom ? point.dy : bottom);
      }
    }
    if (left == null || top == null || right == null || bottom == null) {
      return null;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  double _lineCenterY(Rect bounds, int lineNumber) {
    if (lineBands.isNotEmpty) {
      final int clampedLine = lineNumber.clamp(1, lineBands.length);
      return lineBands[clampedLine - 1].center;
    }
    const int fallbackCount = 3;
    final int clampedLine = lineNumber.clamp(1, fallbackCount);
    final double lineHeight = bounds.height <= 0 ? 28 : bounds.height / fallbackCount;
    return bounds.top + ((clampedLine - 0.5) * lineHeight);
  }

  @override
  bool shouldRepaint(covariant MathCanvasPainter oldDelegate) {
    return oldDelegate.userStrokes != userStrokes ||
        oldDelegate.wrongLineNumbers != wrongLineNumbers ||
        oldDelegate.lineBands != lineBands ||
        oldDelegate.finalResultLine != finalResultLine ||
        oldDelegate.showCheck != showCheck ||
        oldDelegate.showFinalX != showFinalX ||
        oldDelegate.checkProgress != checkProgress ||
        oldDelegate.correctionText != correctionText;
  }
}
