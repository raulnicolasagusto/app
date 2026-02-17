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

class LLMLineResult {
  const LLMLineResult({
    required this.linea,
    required this.texto,
    required this.ok,
  });

  factory LLMLineResult.fromJson(Map<String, dynamic> json) {
    return LLMLineResult(
      linea: (json['linea'] as num?)?.toInt() ?? 0,
      texto: (json['texto'] ?? '').toString(),
      ok: json['ok'] == true,
    );
  }

  final int linea;
  final String texto;
  final bool ok;
}

class LLMAnalysis {
  const LLMAnalysis({
    required this.correcto,
    required this.pasos,
    required this.correccion,
  });

  factory LLMAnalysis.fromJson(Map<String, dynamic> json) {
    final rawPasos = (json['pasos'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(LLMLineResult.fromJson)
        .toList(growable: false);

    final rawCorreccion = (json['correccion'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic line) => line.toString())
        .toList(growable: false);

    return LLMAnalysis(
      correcto: json['correcto'] == true,
      pasos: rawPasos,
      correccion: rawCorreccion,
    );
  }

  final bool correcto;
  final List<LLMLineResult> pasos;
  final List<String> correccion;
}
