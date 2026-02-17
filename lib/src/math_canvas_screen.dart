import 'dart:async';

import 'package:flutter/material.dart';

import 'canvas_painter.dart';
import 'equation_bank.dart';
import 'ink_service.dart';
import 'llm_service.dart';
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
  final LlmService _llmService = LlmService();

  late EquationItem _currentEquation;
  final List<StrokePath> _userStrokes = <StrokePath>[];
  StrokePath? _activeStroke;

  bool _isLoading = false;
  bool _showCheck = false;
  List<int> _wrongLineNumbers = <int>[];
  int _recognizedLineCount = 0;
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
    _llmService.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isLoading) {
      return;
    }
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    _activeStroke = StrokePath(
      points: <Offset>[details.localPosition],
      timestamps: <int>[timestamp],
    );
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeStroke == null || _isLoading) {
      return;
    }
    _activeStroke!.points.add(details.localPosition);
    _activeStroke!.timestamps.add(DateTime.now().millisecondsSinceEpoch);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeStroke == null || _isLoading) {
      return;
    }
    _userStrokes.add(_activeStroke!);
    _activeStroke = null;
    setState(() {});
  }

  void _resetCanvasForNextEquation() {
    _typeTimer?.cancel();
    _checkController.reset();
    _showCheck = false;
    _wrongLineNumbers = <int>[];
    _recognizedLineCount = 0;
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

  Future<void> _analyze() async {
    if (_isLoading) {
      return;
    }
    if (_userStrokes.isEmpty) {
      _showMessage('Escribí tu resolución antes de presionar Listo.');
      return;
    }

    setState(() {
      _isLoading = true;
      _showCheck = false;
      _wrongLineNumbers = <int>[];
      _recognizedLineCount = 0;
      _animatedCorrectionText = '';
      _checkController.reset();
      _typeTimer?.cancel();
    });

    try {
      final String transcription = await _inkService.recognize(_userStrokes);
      if (transcription.trim().isEmpty) {
        throw const LlmException(
          'No pudimos leer la escritura. Intenta nuevamente.',
        );
      }

      final List<String> lines = transcription
          .split('\n')
          .map((String line) => line.trim())
          .where((String line) => line.isNotEmpty)
          .toList(growable: false);

      final LLMAnalysis analysis = await _llmService.analyze(
        equation: _currentEquation.prompt,
        expectedFinal: _currentEquation.expectedFinal,
        contextHint: _currentEquation.contextHint,
        transcription: transcription,
      );
      final bool fallbackCorrect = _matchesExpectedResult(
        transcription: transcription,
        expectedFinal: _currentEquation.expectedFinal,
      );
      final bool finalCorrect = analysis.correcto || fallbackCorrect;

      if (!mounted) {
        return;
      }

      setState(() {
        _recognizedLineCount = lines.isEmpty
            ? (analysis.pasos.isEmpty ? 1 : analysis.pasos.length)
            : lines.length;
      });

      if (finalCorrect) {
        setState(() {
          _showCheck = true;
          _wrongLineNumbers = <int>[];
          _animatedCorrectionText = '';
        });
        _checkController.forward(from: 0);
        _showMessage('Correcto. Tu resultado coincide con la ecuacion.');
      } else {
        final List<int> wrongLines = analysis.pasos
            .where((LLMLineResult step) => !step.ok)
            .map((LLMLineResult step) => step.linea <= 0 ? 1 : step.linea)
            .toList(growable: false);
        final String correctionBlock = analysis.correccion.join('\n');
        setState(() {
          _showCheck = false;
          _wrongLineNumbers = wrongLines;
          _animatedCorrectionText = '';
        });
        _startTypewriter(correctionBlock);
        _showMessage('Incorrecto. Revisa las correcciones en verde.');
      }
    } on LlmException catch (error) {
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
    if (text.trim().isEmpty) {
      return;
    }
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

  bool _matchesExpectedResult({
    required String transcription,
    required String expectedFinal,
  }) {
    final RegExp expectedPattern = RegExp(
      r'^\s*([a-zA-Z])\s*=\s*(-?\d+(?:\.\d+)?)\s*$',
    );
    final Match? expectedMatch = expectedPattern.firstMatch(expectedFinal);
    if (expectedMatch == null) {
      return false;
    }
    final String expectedVar = expectedMatch.group(1)!.toLowerCase();
    final String expectedValue = expectedMatch.group(2)!;

    final RegExp foundAssignments = RegExp(
      r'([a-zA-Z])\s*=\s*(-?\d+(?:\.\d+)?)',
      multiLine: true,
    );
    for (final Match match in foundAssignments.allMatches(transcription)) {
      final String varName = (match.group(1) ?? '').toLowerCase();
      final String value = match.group(2) ?? '';
      if (varName == expectedVar && value == expectedValue) {
        return true;
      }
    }
    return false;
  }

  List<StrokePath> get _strokesForPaint {
    if (_activeStroke == null) {
      return List<StrokePath>.unmodifiable(_userStrokes);
    }
    return List<StrokePath>.unmodifiable(<StrokePath>[
      ..._userStrokes,
      _activeStroke!,
    ]);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            final double canvasHeight = constraints.maxHeight * 0.65;
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
                SizedBox(
                  height: canvasHeight,
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
                            totalLines: _recognizedLineCount,
                            showCheck: _showCheck,
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
                  child: Center(
                    child: FilledButton.icon(
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
