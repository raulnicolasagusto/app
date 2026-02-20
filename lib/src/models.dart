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
