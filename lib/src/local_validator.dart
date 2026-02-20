import 'dart:math';

import 'models.dart';

class LocalValidator {
  LocalValidationResult validate({
    required String equation,
    required String expectedFinal,
    required String? contextHint,
    required List<String> ocrLines,
  }) {
    final List<String> lines = ocrLines
        .map(_normalizeLine)
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      return const LocalValidationResult(
        correcto: false,
        wrongLines: <int>[1],
        finalLine: 1,
        reason: 'No OCR lines available',
        normalizedLines: <String>[],
        stepChecks: <LocalStepCheck>[],
      );
    }

    final double? yValue = _extractHintValue(contextHint, 'y');
    final _LinearEquation? base = _parseEquation(_normalizeLine(equation), yValue: yValue);
    final double? expected = _extractHintValue(expectedFinal, 'x');
    if (base == null || expected == null) {
      return LocalValidationResult(
        correcto: false,
        wrongLines: List<int>.generate(lines.length, (int i) => i + 1),
        finalLine: max(1, lines.length),
        reason: 'Unable to parse base equation or expected final',
        normalizedLines: lines,
        stepChecks: const <LocalStepCheck>[],
      );
    }

    final double? baseSolution = base.solveForX();
    if (baseSolution == null) {
      return LocalValidationResult(
        correcto: false,
        wrongLines: List<int>.generate(lines.length, (int i) => i + 1),
        finalLine: max(1, lines.length),
        reason: 'Base equation does not have a unique x solution',
        normalizedLines: lines,
        stepChecks: const <LocalStepCheck>[],
      );
    }

    final List<int> wrongLines = <int>[];
    final List<LocalStepCheck> checks = <LocalStepCheck>[];
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final _LinearEquation? parsed = _parseEquation(line, yValue: yValue);
      if (parsed == null) {
        wrongLines.add(i + 1);
        checks.add(LocalStepCheck(linea: i + 1, ok: false, reason: 'line parse failed'));
        continue;
      }
      final double? stepSolution = parsed.solveForX();
      if (stepSolution == null) {
        wrongLines.add(i + 1);
        checks.add(LocalStepCheck(linea: i + 1, ok: false, reason: 'no unique x'));
        continue;
      }
      final bool sameSolution = (stepSolution - baseSolution).abs() <= 1e-6;
      if (!sameSolution) {
        wrongLines.add(i + 1);
      }
      checks.add(
        LocalStepCheck(
          linea: i + 1,
          ok: sameSolution,
          reason: sameSolution ? 'equivalent' : 'solution mismatch',
        ),
      );
    }

    final _LinearEquation? last = _parseEquation(lines.last, yValue: yValue);
    final double? lastSolution = last?.solveForX();
    final bool finalMatchesExpected =
        lastSolution != null && (lastSolution - expected).abs() <= 1e-6;
    final bool sequenceOk = wrongLines.isEmpty;
    final bool correct = sequenceOk && finalMatchesExpected;
    final String reason = correct
        ? 'local validation ok'
        : (!sequenceOk ? 'one or more lines are not equivalent' : 'final value mismatch');

    return LocalValidationResult(
      correcto: correct,
      wrongLines: wrongLines,
      finalLine: lines.length,
      reason: reason,
      normalizedLines: lines,
      stepChecks: checks,
    );
  }
}

class _LinearExpression {
  const _LinearExpression({required this.a, required this.b});

  final double a;
  final double b;

  _LinearExpression operator +(_LinearExpression other) =>
      _LinearExpression(a: a + other.a, b: b + other.b);
  _LinearExpression operator -(_LinearExpression other) =>
      _LinearExpression(a: a - other.a, b: b - other.b);

  _LinearExpression multiply(_LinearExpression other) {
    if (a != 0 && other.a != 0) {
      throw const FormatException('non-linear multiplication');
    }
    if (other.a == 0) {
      return _LinearExpression(a: a * other.b, b: b * other.b);
    }
    return _LinearExpression(a: other.a * b, b: other.b * b);
  }

  _LinearExpression divide(_LinearExpression other) {
    if (other.a != 0 || other.b == 0) {
      throw const FormatException('invalid division');
    }
    return _LinearExpression(a: a / other.b, b: b / other.b);
  }
}

class _LinearEquation {
  const _LinearEquation({
    required this.left,
    required this.right,
  });

  final _LinearExpression left;
  final _LinearExpression right;

  double? solveForX() {
    final double a = left.a - right.a;
    final double b = left.b - right.b;
    if (a.abs() <= 1e-9) {
      return null;
    }
    return -b / a;
  }
}

_LinearEquation? _parseEquation(String source, {double? yValue}) {
  final int equalsIndex = source.indexOf('=');
  if (equalsIndex < 0) {
    return null;
  }
  final String left = source.substring(0, equalsIndex).trim();
  final String right = source.substring(equalsIndex + 1).trim();
  try {
    final _LinearExpression leftExpr = _ExpressionParser(left, yValue: yValue).parse();
    final _LinearExpression rightExpr = _ExpressionParser(right, yValue: yValue).parse();
    return _LinearEquation(left: leftExpr, right: rightExpr);
  } catch (_) {
    return null;
  }
}

double? _extractHintValue(String? source, String variable) {
  if (source == null || source.trim().isEmpty) {
    return null;
  }
  final RegExp regExp = RegExp('$variable\\s*=\\s*(-?\\d+(?:\\.\\d+)?)');
  final Match? match = regExp.firstMatch(source.replaceAll(' ', '').toLowerCase());
  if (match == null) {
    return null;
  }
  return double.tryParse(match.group(1)!);
}

String _normalizeLine(String line) {
  String value = line
      .replaceAll('−', '-')
      .replaceAll('–', '-')
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll(':', '=')
      .replaceAll(' ', '')
      .toLowerCase();
  value = value.replaceAllMapped(
    RegExp(r'(\d)([a-z\(])'),
    (Match m) => '${m.group(1)}*${m.group(2)}',
  );
  value = value.replaceAllMapped(
    RegExp(r'([a-z\)])(\d)'),
    (Match m) => '${m.group(1)}*${m.group(2)}',
  );
  value = value.replaceAllMapped(
    RegExp(r'([a-z])\('),
    (Match m) => '${m.group(1)}*(',
  );
  value = value.replaceAllMapped(
    RegExp(r'\)([a-z\d])'),
    (Match m) => ')*${m.group(1)}',
  );
  return value;
}

class _ExpressionParser {
  _ExpressionParser(this._source, {required this.yValue});

  final String _source;
  final double? yValue;
  int _index = 0;

  _LinearExpression parse() {
    final _LinearExpression expr = _parseExpression();
    if (_index != _source.length) {
      throw const FormatException('trailing chars');
    }
    return expr;
  }

  _LinearExpression _parseExpression() {
    _LinearExpression value = _parseTerm();
    while (_index < _source.length) {
      final String c = _source[_index];
      if (c == '+') {
        _index++;
        value = value + _parseTerm();
      } else if (c == '-') {
        _index++;
        value = value - _parseTerm();
      } else {
        break;
      }
    }
    return value;
  }

  _LinearExpression _parseTerm() {
    _LinearExpression value = _parseFactor();
    while (_index < _source.length) {
      final String c = _source[_index];
      if (c == '*') {
        _index++;
        value = value.multiply(_parseFactor());
      } else if (c == '/') {
        _index++;
        value = value.divide(_parseFactor());
      } else {
        break;
      }
    }
    return value;
  }

  _LinearExpression _parseFactor() {
    if (_index >= _source.length) {
      throw const FormatException('unexpected end');
    }
    final String c = _source[_index];
    if (c == '(') {
      _index++;
      final _LinearExpression expr = _parseExpression();
      if (_index >= _source.length || _source[_index] != ')') {
        throw const FormatException('missing )');
      }
      _index++;
      return expr;
    }
    if (c == '-') {
      _index++;
      final _LinearExpression inner = _parseFactor();
      return _LinearExpression(a: -inner.a, b: -inner.b);
    }
    if (c == 'x') {
      _index++;
      return const _LinearExpression(a: 1, b: 0);
    }
    if (c == 'y') {
      _index++;
      if (yValue == null) {
        throw const FormatException('missing y context');
      }
      return _LinearExpression(a: 0, b: yValue!);
    }
    return _parseNumber();
  }

  _LinearExpression _parseNumber() {
    final int start = _index;
    while (_index < _source.length &&
        (_source[_index] == '.' || RegExp(r'\d').hasMatch(_source[_index]))) {
      _index++;
    }
    if (start == _index) {
      throw const FormatException('number expected');
    }
    final double value = double.parse(_source.substring(start, _index));
    return _LinearExpression(a: 0, b: value);
  }
}
