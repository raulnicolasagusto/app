import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'backend_validation_service.dart';
import 'canvas_painter.dart';
import 'equation_bank.dart';
import 'feedback_mapper.dart';
import 'ink_service.dart';
import 'line_mapper.dart';
import 'models.dart';

class MathCanvasScreen extends StatefulWidget {
  const MathCanvasScreen({super.key});

  @override
  State<MathCanvasScreen> createState() => _MathCanvasScreenState();
}

class _MathCanvasScreenState extends State<MathCanvasScreen>
    with TickerProviderStateMixin {
  final EquationBank _equationBank = EquationBank();
  final InkService _inkService = InkService();
  final BackendValidationService _validationService = BackendValidationService();

  late EquationItem _currentEquation;
  final List<StrokePath> _userStrokes = <StrokePath>[];
  StrokePath? _activeStroke;

  bool _isLoading = false;
  bool _showCheck = false;
  bool _showFinalX = false;
  List<int> _wrongLineNumbers = <int>[];
  int _finalResultLine = 1;
  List<LineBand> _lineBands = <LineBand>[];
  String _animatedCorrectionText = '';
  Timer? _typeTimer;

  late final AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _currentEquation = _equationBank.next();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _checkController.dispose();
    _validationService.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isLoading) return;
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    _activeStroke = StrokePath(
      points: <Offset>[details.localPosition],
      timestamps: <int>[timestamp],
    );
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeStroke == null || _isLoading) return;
    _activeStroke!.points.add(details.localPosition);
    _activeStroke!.timestamps.add(DateTime.now().millisecondsSinceEpoch);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeStroke == null || _isLoading) return;
    _userStrokes.add(_activeStroke!);
    _activeStroke = null;
    setState(() {});
  }

  void _resetCanvasForNextEquation() {
    _typeTimer?.cancel();
    _checkController.reset();
    _showCheck = false;
    _showFinalX = false;
    _wrongLineNumbers = <int>[];
    _finalResultLine = 1;
    _lineBands = <LineBand>[];
    _animatedCorrectionText = '';
    _activeStroke = null;
    _userStrokes.clear();
  }

  void _pickNewEquation() {
    setState(() {
      final String oldId = _currentEquation.id;
      _resetCanvasForNextEquation();
      _currentEquation = _equationBank.next(oldId);
    });
  }

  void _clearCanvasOnly() {
    if (_isLoading) return;
    setState(() {
      _resetCanvasForNextEquation();
    });
  }

  Future<void> _analyze() async {
    if (_isLoading) return;
    if (_userStrokes.isEmpty) {
      _showMessage('Escribí tu resolución antes de presionar Listo.');
      return;
    }

    setState(() {
      _isLoading = true;
      _showCheck = false;
      _showFinalX = false;
      _wrongLineNumbers = <int>[];
      _finalResultLine = 1;
      _lineBands = <LineBand>[];
      _animatedCorrectionText = '';
      _checkController.reset();
      _typeTimer?.cancel();
    });

    try {
      final OcrBundle ocrBundle = await _inkService.recognize(_userStrokes);
      if (ocrBundle.rawJoinedText.trim().isEmpty) {
        throw const BackendValidationException(
          'No pudimos leer la escritura. Intenta nuevamente.',
        );
      }
      _logLarge('OCR_RAW', ocrBundle.rawJoinedText);
      final List<String> ocrLines = ocrBundle.lines;

      final BackendValidationResult result = await _validationService.validate(
        equation: _currentEquation,
        ocrBundle: ocrBundle,
      );
      _logLarge(
        'BACKEND_VALIDATION',
        jsonEncode(<String, dynamic>{
          'decision': result.decision,
          'is_correct': result.isCorrect,
          'final_result_correct': result.finalResultCorrect,
          'process_valid': result.processValid,
          'validation_status': result.validationStatus,
          'equivalence_mode': result.equivalenceMode,
          'error_type': result.errorType,
          'warning_type': result.warningType,
          'warning_lines': result.warningLines,
          'wrong_lines': result.wrongLines,
        }),
      );

      final int inferredLineCount = ocrLines.isEmpty ? 1 : ocrLines.length;
      final List<int> backendMarkedLines = <int>[
        ...result.warningLines,
        ...result.wrongLines,
      ];
      final int maxBackendLine = backendMarkedLines.isEmpty
          ? inferredLineCount
          : backendMarkedLines.reduce((int a, int b) => a > b ? a : b);
      final int finalLineFromBackend = result.finalResultLine <= 0
          ? inferredLineCount
          : result.finalResultLine;
      final int targetLineCount = <int>[
        inferredLineCount,
        maxBackendLine,
        finalLineFromBackend,
        1,
      ].reduce((int a, int b) => a > b ? a : b);
      final List<LineBand> mappedBands = buildLineBands(
        strokes: _userStrokes,
        targetLineCount: targetLineCount,
      );
      final int effectiveLineCount = mappedBands.isEmpty ? targetLineCount : mappedBands.length;
      final int finalLine = finalLineFromBackend.clamp(1, effectiveLineCount);

      if (!mounted) return;
      setState(() {
        _lineBands = mappedBands;
        _finalResultLine = finalLine;
      });

      final UiDecision decision = (result.decision == 'correct' ||
              result.decision == 'correct_with_warnings')
          ? UiDecision.correct
          : (result.decision == 'unreadable' ? UiDecision.unreadable : UiDecision.incorrect);

      if (decision == UiDecision.unreadable) {
        _logLarge('FINAL_UI_DECISION', 'unreadable');
        setState(() {
          _showCheck = false;
          _showFinalX = false;
          _wrongLineNumbers = <int>[];
          _animatedCorrectionText = '';
        });
        _showMessage('No pude leer tu escritura. Intenta más claro.');
      } else if (decision == UiDecision.correct) {
        _logLarge('FINAL_UI_DECISION', 'correct');
        final bool hasWarnings = result.decision == 'correct_with_warnings';
        final List<int> markedLines = buildWrongLineNumbers(
          wrongLines: backendMarkedLines,
          lineBandCount: effectiveLineCount,
          finalResultLine: _finalResultLine,
          includeFinalLine: false,
        );
        setState(() {
          _showCheck = true;
          _showFinalX = false;
          _wrongLineNumbers = hasWarnings ? markedLines : <int>[];
          _animatedCorrectionText = '';
        });
        _checkController.forward(from: 0);
        if (hasWarnings) {
          final List<String> warningLines = result.suggestedCorrectionSteps.isNotEmpty
              ? result.suggestedCorrectionSteps
              : <String>[
                  result.warningMessage ??
                      'Resultado final correcto. Revisa el paso marcado en rojo.',
                  'El procedimiento necesita una revision.',
                ];
          _startTypewriter(warningLines.join('\n'));
          _showMessage(
            'Resultado final correcto. Revisa el paso marcado en rojo.',
          );
        } else {
          _showMessage('Correcto. Resolucion valida.');
        }
      } else {
        _logLarge('FINAL_UI_DECISION', 'incorrect');
        final List<int> wrongLines = buildWrongLineNumbers(
          wrongLines: result.wrongLines,
          lineBandCount: effectiveLineCount,
          finalResultLine: _finalResultLine,
          includeFinalLine: false,
        );
        final List<String> correctionLines = result.suggestedCorrectionSteps.isNotEmpty
            ? result.suggestedCorrectionSteps
            : (result.pedagogicalFeedback.trim().isNotEmpty
                  ? <String>[result.pedagogicalFeedback]
                  : <String>[
                      'Revisa las lineas tachadas.',
                      'Resultado esperado: ${_currentEquation.expectedFinal}',
                    ]);
        setState(() {
          _showCheck = false;
          _showFinalX = true;
          _wrongLineNumbers = wrongLines;
          _animatedCorrectionText = '';
        });
        _startTypewriter(correctionLines.join('\n'));
        _showMessage(
          result.validationStatus == 'undetermined'
              ? 'No pude confirmar un paso con precision. Revisa tu escritura.'
              : 'Incorrecto. Revisa pasos tachados y correccion.',
        );
      }
    } on BackendValidationException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Error procesando ejercicio: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startTypewriter(String text) {
    _typeTimer?.cancel();
    if (text.trim().isEmpty) return;
    int index = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 30), (Timer timer) {
      index++;
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index > text.length) {
        timer.cancel();
        return;
      }
      setState(() {
        _animatedCorrectionText = text.substring(0, index);
      });
    });
  }

  List<StrokePath> get _strokesForPaint {
    if (_activeStroke == null) return List<StrokePath>.unmodifiable(_userStrokes);
    return List<StrokePath>.unmodifiable(<StrokePath>[..._userStrokes, _activeStroke!]);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _logLarge(String tag, String text) {
    const int chunk = 700;
    if (text.isEmpty) {
      debugPrint('$tag: <empty>');
      return;
    }
    for (int i = 0; i < text.length; i += chunk) {
      final int end = (i + chunk < text.length) ? i + chunk : text.length;
      debugPrint('$tag: ${text.substring(i, end)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Fight MVP'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double headerHeight = constraints.maxHeight * 0.2;
            final double footerHeight = constraints.maxHeight * 0.15;

            return Column(
              children: <Widget>[
                SizedBox(
                  height: headerHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    _currentEquation.prompt,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_currentEquation.contextHint != null)
                                    Text(
                                      'Dato: ${_currentEquation.contextHint}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _isLoading ? null : _pickNewEquation,
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Actualizar ecuación',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: MathCanvasPainter(
                            userStrokes: _strokesForPaint,
                            wrongLineNumbers: _wrongLineNumbers,
                            lineBands: _lineBands,
                            finalResultLine: _finalResultLine,
                            showCheck: _showCheck,
                            showFinalX: _showFinalX,
                            checkProgress: _checkController.value,
                            correctionText: _animatedCorrectionText,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: footerHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        onPressed: _isLoading ? null : _clearCanvasOnly,
                        tooltip: 'Borrar canvas',
                        icon: const Icon(Icons.auto_fix_normal),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _analyze,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isLoading ? 'Analizando...' : 'Listo'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
