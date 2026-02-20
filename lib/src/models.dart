import 'dart:ui';

class EquationItem {
  const EquationItem({
    required this.id,
    required this.prompt,
    required this.expectedFinal,
    this.contextHint,
  });

  final String id;
  final String prompt;
  final String expectedFinal;
  final String? contextHint;
}

class StrokePath {
  StrokePath({
    required this.points,
    required this.timestamps,
  });

  final List<Offset> points;
  final List<int> timestamps;
}

class LineBand {
  const LineBand({
    required this.index,
    required this.top,
    required this.bottom,
  });

  final int index;
  final double top;
  final double bottom;

  double get center => (top + bottom) / 2;
}

class OcrCandidate {
  const OcrCandidate({
    required this.text,
    required this.score,
    required this.mathScore,
  });

  final String text;
  final double score;
  final int mathScore;
}

class OcrLineResult {
  const OcrLineResult({
    required this.lineIndex,
    required this.bestText,
    required this.candidates,
  });

  final int lineIndex;
  final String bestText;
  final List<OcrCandidate> candidates;
}

class OcrBundle {
  const OcrBundle({
    required this.rawJoinedText,
    required this.lines,
    required this.lineResults,
  });

  final String rawJoinedText;
  final List<String> lines;
  final List<OcrLineResult> lineResults;
}

class LLMLineResult {
  const LLMLineResult({
    required this.linea,
    required this.texto,
    required this.ok,
    required this.motivo,
  });

  factory LLMLineResult.fromJson(Map<String, dynamic> json) {
    return LLMLineResult(
      linea: (json['linea'] as num?)?.toInt() ?? 0,
      texto: (json['texto'] ?? '').toString(),
      ok: json['ok'] == true,
      motivo: (json['motivo'] ?? '').toString(),
    );
  }

  final int linea;
  final String texto;
  final bool ok;
  final String motivo;
}

class LocalStepCheck {
  const LocalStepCheck({
    required this.linea,
    required this.ok,
    required this.reason,
  });

  final int linea;
  final bool ok;
  final String reason;
}

class LocalValidationResult {
  const LocalValidationResult({
    required this.correcto,
    required this.wrongLines,
    required this.finalLine,
    required this.reason,
    required this.normalizedLines,
    required this.stepChecks,
  });

  final bool correcto;
  final List<int> wrongLines;
  final int finalLine;
  final String reason;
  final List<String> normalizedLines;
  final List<LocalStepCheck> stepChecks;
}

class LLMAnalysis {
  const LLMAnalysis({
    required this.ocrLegible,
    required this.resultadoFinalTexto,
    required this.resultadoFinalCorrecto,
    required this.correctoGlobal,
    required this.lineasIncorrectas,
    required this.explicacionBreve,
    required this.transcripcionReconstruida,
    required this.correcto,
    required this.pasos,
    required this.primerErrorLinea,
    required this.resultadoFinalOk,
    required this.lineaResultadoFinal,
    required this.correccionDesdeError,
    required this.aiFeedback,
    required this.pasosSugeridos,
    required this.correccion,
    required this.transcripcionRecibida,
    required this.rawContent,
    required this.rawJson,
    required this.sanitizedJson,
    required this.decodedJson,
  });

  factory LLMAnalysis.fromJson(
    Map<String, dynamic> json, {
    String transcripcionRecibida = '',
    String rawContent = '',
    String rawJson = '',
    String sanitizedJson = '',
  }) {
    final rawPasos = (json['pasos'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(LLMLineResult.fromJson)
        .toList(growable: false);

    final rawCorreccion = (json['correccion'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic line) => line.toString())
        .toList(growable: false);
    final rawLineasIncorrectas =
        (json['lineas_incorrectas'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic line) => (line as num?)?.toInt() ?? 0)
            .where((int line) => line > 0)
            .toList(growable: false);
    final rawCorreccionDesdeError =
        (json['correccion_desde_error'] as List<dynamic>? ??
                json['pasos_sugeridos'] as List<dynamic>? ??
                rawCorreccion)
            .map((dynamic line) => line.toString())
            .toList(growable: false);
    final List<String> rawReconstruida =
        (json['transcripcion_reconstruida'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic line) => line.toString())
            .toList(growable: false);

    final String transcripcion =
        (json['transcripcion_recibida'] ?? transcripcionRecibida).toString();
    final bool ocrLegible = json['ocr_legible'] is bool
        ? json['ocr_legible'] == true
        : _looksMathLike(transcripcion);
    final bool resultadoFinalCorrecto = json['resultado_final_correcto'] is bool
        ? json['resultado_final_correcto'] == true
        : json['resultado_final_ok'] == true;
    final bool correctoGlobal = json['correcto_global'] is bool
        ? json['correcto_global'] == true
        : (json['correcto'] == true || resultadoFinalCorrecto);

    return LLMAnalysis(
      ocrLegible: ocrLegible,
      resultadoFinalTexto: (json['resultado_final_texto'] ?? '').toString(),
      resultadoFinalCorrecto: resultadoFinalCorrecto,
      correctoGlobal: correctoGlobal,
      lineasIncorrectas: rawLineasIncorrectas,
      explicacionBreve: (json['explicacion_breve'] ?? '').toString(),
      transcripcionReconstruida: rawReconstruida,
      correcto: json['correcto'] == true,
      pasos: rawPasos,
      primerErrorLinea: (json['primer_error_linea'] as num?)?.toInt(),
      resultadoFinalOk: json['resultado_final_ok'] == true,
      lineaResultadoFinal: (json['linea_resultado_final'] as num?)?.toInt(),
      correccionDesdeError: rawCorreccionDesdeError,
      aiFeedback: (json['ai_feedback'] ?? '').toString(),
      pasosSugeridos: (json['pasos_sugeridos'] as List<dynamic>? ??
              rawCorreccionDesdeError)
          .map((dynamic line) => line.toString())
          .toList(growable: false),
      correccion: rawCorreccion,
      transcripcionRecibida: transcripcion,
      rawContent: rawContent,
      rawJson: rawJson,
      sanitizedJson: sanitizedJson,
      decodedJson: Map<String, dynamic>.from(json),
    );
  }

  final bool correcto;
  final List<LLMLineResult> pasos;
  final int? primerErrorLinea;
  final bool resultadoFinalOk;
  final int? lineaResultadoFinal;
  final List<String> correccionDesdeError;
  final String aiFeedback;
  final List<String> pasosSugeridos;
  final List<String> correccion;
  final String transcripcionRecibida;
  final String rawContent;
  final String rawJson;
  final String sanitizedJson;
  final Map<String, dynamic> decodedJson;
  final bool ocrLegible;
  final String resultadoFinalTexto;
  final bool resultadoFinalCorrecto;
  final bool correctoGlobal;
  final List<int> lineasIncorrectas;
  final String explicacionBreve;
  final List<String> transcripcionReconstruida;

  static bool _looksMathLike(String text) {
    final String t = text.toLowerCase();
    return t.contains('=') ||
        RegExp(r'\d').hasMatch(t) ||
        RegExp(r'[\+\-\*/]').hasMatch(t);
  }
}

class BackendStepValidation {
  const BackendStepValidation({
    required this.fromStep,
    required this.toStep,
    required this.fromNormalized,
    required this.toNormalized,
    required this.equivalent,
    required this.validationStatus,
    required this.equivalenceMode,
    required this.reason,
    required this.previousSolutionSet,
    required this.currentSolutionSet,
  });

  factory BackendStepValidation.fromJson(Map<String, dynamic> json) {
    return BackendStepValidation(
      fromStep: (json['from_step'] ?? '').toString(),
      toStep: (json['to_step'] ?? '').toString(),
      fromNormalized: (json['from_normalized'] ?? '').toString(),
      toNormalized: (json['to_normalized'] ?? '').toString(),
      equivalent: json['equivalent'] == true,
      validationStatus: (json['validation_status'] ?? 'invalid').toString(),
      equivalenceMode: (json['equivalence_mode'] ?? 'algebraic').toString(),
      reason: (json['reason'] ?? '').toString(),
      previousSolutionSet: json['previous_solution_set']?.toString(),
      currentSolutionSet: json['current_solution_set']?.toString(),
    );
  }

  final String fromStep;
  final String toStep;
  final String fromNormalized;
  final String toNormalized;
  final bool equivalent;
  final String validationStatus;
  final String equivalenceMode;
  final String reason;
  final String? previousSolutionSet;
  final String? currentSolutionSet;
}

class BackendValidationResult {
  const BackendValidationResult({
    required this.decision,
    required this.isCorrect,
    required this.finalResultCorrect,
    required this.processValid,
    required this.warningLines,
    required this.wrongLines,
    required this.finalResultLine,
    required this.firstErrorIndex,
    required this.errorType,
    required this.warningType,
    required this.warningMessage,
    required this.validationStatus,
    required this.equivalenceMode,
    required this.previousSolutionSet,
    required this.currentSolutionSet,
    required this.normalizedSteps,
    required this.stepValidations,
    required this.pedagogicalFeedback,
    required this.suggestedCorrectionSteps,
    required this.debug,
  });

  factory BackendValidationResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawWarningLines =
        json['warning_lines'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawWrongLines =
        json['wrong_lines'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawNormalizedSteps =
        json['normalized_steps'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawStepValidations =
        json['step_validations'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawSuggestionSteps =
        json['suggested_correction_steps'] as List<dynamic>? ?? <dynamic>[];

    return BackendValidationResult(
      decision: (json['decision'] ?? 'incorrect').toString(),
      isCorrect: json['is_correct'] == true,
      finalResultCorrect: json['final_result_correct'] == true,
      processValid: json['process_valid'] == true,
      warningLines: rawWarningLines
          .map((dynamic line) => (line as num?)?.toInt() ?? 0)
          .where((int line) => line > 0)
          .toList(growable: false),
      wrongLines: rawWrongLines
          .map((dynamic line) => (line as num?)?.toInt() ?? 0)
          .where((int line) => line > 0)
          .toList(growable: false),
      finalResultLine: (json['final_result_line'] as num?)?.toInt() ?? 1,
      firstErrorIndex: (json['first_error_index'] as num?)?.toInt(),
      errorType: json['error_type']?.toString(),
      warningType: json['warning_type']?.toString(),
      warningMessage: json['warning_message']?.toString(),
      validationStatus: (json['validation_status'] ?? 'invalid').toString(),
      equivalenceMode: (json['equivalence_mode'] ?? 'algebraic').toString(),
      previousSolutionSet: json['previous_solution_set']?.toString(),
      currentSolutionSet: json['current_solution_set']?.toString(),
      normalizedSteps:
          rawNormalizedSteps.map((dynamic line) => line.toString()).toList(growable: false),
      stepValidations: rawStepValidations
          .whereType<Map<String, dynamic>>()
          .map(BackendStepValidation.fromJson)
          .toList(growable: false),
      pedagogicalFeedback: (json['pedagogical_feedback'] ?? '').toString(),
      suggestedCorrectionSteps:
          rawSuggestionSteps.map((dynamic line) => line.toString()).toList(growable: false),
      debug: Map<String, dynamic>.from(
        json['debug'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }

  final String decision;
  final bool isCorrect;
  final bool finalResultCorrect;
  final bool processValid;
  final List<int> warningLines;
  final List<int> wrongLines;
  final int finalResultLine;
  final int? firstErrorIndex;
  final String? errorType;
  final String? warningType;
  final String? warningMessage;
  final String validationStatus;
  final String equivalenceMode;
  final String? previousSolutionSet;
  final String? currentSolutionSet;
  final List<String> normalizedSteps;
  final List<BackendStepValidation> stepValidations;
  final String pedagogicalFeedback;
  final List<String> suggestedCorrectionSteps;
  final Map<String, dynamic> debug;
}
