import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class LlmService {
  LlmService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const Duration _timeout = Duration(seconds: 10);
  static const String _model = 'llama-3.1-8b-instant';

  Future<LLMAnalysis> analyze({
    required String equation,
    required String expectedFinal,
    required String? contextHint,
    required OcrBundle ocrBundle,
  }) async {
    final String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw const LlmException(
        'Missing GROQ_API_KEY in .env',
      );
    }

    final String hintLine = contextHint == null || contextHint.trim().isEmpty
        ? ''
        : '\nDato adicional: ${contextHint.trim()}';
    final String ocrLines = ocrBundle.lines.isEmpty
        ? '(sin lineas OCR)'
        : ocrBundle.lines
            .asMap()
            .entries
            .map((MapEntry<int, String> entry) => 'L${entry.key + 1}: ${entry.value}')
            .join('\n');
    final String ocrCandidates = ocrBundle.lineResults.isEmpty
        ? '(sin candidatos)'
        : ocrBundle.lineResults
            .map((OcrLineResult line) =>
                'L${line.lineIndex}: ${line.candidates.map((OcrCandidate c) => '"${c.text}"(m=${c.mathScore},s=${c.score.toStringAsFixed(3)})').join(', ')}')
            .join('\n');

    final Map<String, dynamic> body = <String, dynamic>{
      'model': _model,
      'temperature': 0.2,
      'response_format': <String, dynamic>{'type': 'json_object'},
      'messages': <Map<String, String>>[
        <String, String>{
          'role': 'system',
          'content':
              'Sos un profesor de matematicas y evaluas resoluciones manuscritas. '
                  'No impongas un metodo unico. '
                  'Respond ONLY with valid JSON, no markdown, no extra text, no code fences',
        },
        <String, String>{
          'role': 'user',
          'content': '''
Problema dado al alumno: $equation$hintLine
Resultado final esperado: $expectedFinal

OCR best por linea:
$ocrLines

Candidatos OCR alternativos por linea:
$ocrCandidates

Analiza cada paso y responde EXCLUSIVAMENTE este JSON:
{
  "transcripcion_recibida": "texto exacto que estas evaluando",
  "transcripcion_reconstruida": ["linea reconstruida 1", "linea reconstruida 2"],
  "ocr_legible": true,
  "resultado_final_texto": "x=8",
  "resultado_final_correcto": true,
  "correcto_global": true,
  "lineas_incorrectas": [2],
  "primer_error_linea": 2,
  "explicacion_breve": "resumen",
  "ai_feedback": "explicacion corta y clara",
  "pasos_sugeridos": ["paso sugerido 1", "paso sugerido 2"],
  "correccion_desde_error": ["paso correcto desde primer error", "resultado final"],
  "pasos": [],
  "correcto": true,
  "resultado_final_ok": true,
  "linea_resultado_final": 0,
  "correccion": []
}

Reglas:
- Evalua PRIMERO si el resultado final es correcto.
- Si el resultado final es correcto, marca correcto_global=true y lineas_incorrectas=[].
- No exijas reescribir la ecuacion inicial; eso NO es error.
- Acepta metodos equivalentes validos (ej: 2x=9-5, x=12/2, expresiones no simplificadas).
- Usa los candidatos OCR para reconstruir una transcripcion matematica probable.
- Si OCR top-1 es basura pero hay candidato matematico plausible, usalo.
- Solo marca ocr_legible=false si no hay candidatos matematicos utilizables.
- Proporciona feedback pedagógico y pasos corregidos.
- No agregues markdown ni texto fuera del JSON.
''',
        },
      ],
    };

    _logLarge('GROQ_REQUEST_SUMMARY', jsonEncode(<String, dynamic>{
      'equation': equation,
      'expectedFinal': expectedFinal,
      'ocrLines': ocrBundle.lines,
      'ocrLineCandidates': ocrBundle.lineResults
          .map((OcrLineResult line) => <String, dynamic>{
                'lineIndex': line.lineIndex,
                'candidates': line.candidates
                    .map((OcrCandidate c) => <String, dynamic>{
                          'text': c.text,
                          'score': c.score,
                          'mathScore': c.mathScore,
                        })
                    .toList(),
              })
          .toList(),
    }));

    late final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: <String, String>{
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } catch (error) {
      throw LlmException('Network error calling Groq: $error');
    }

    if (response.statusCode != 200) {
      throw LlmException(
        'Groq error ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> envelope =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> choices = envelope['choices'] as List<dynamic>? ?? <dynamic>[];
    if (choices.isEmpty) {
      throw const LlmException('Groq response did not include choices');
    }
    final Map<String, dynamic> firstChoice =
        choices.first as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> message =
        firstChoice['message'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final String content = (message['content'] ?? '').toString();
    if (content.trim().isEmpty) {
      throw const LlmException('Groq returned empty content');
    }
    _logLarge('GROQ_RAW_CONTENT', content);

    final String sanitized = _sanitizeJson(content);
    _logLarge('GROQ_SANITIZED_JSON', sanitized);
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(sanitized) as Map<String, dynamic>;
      return LLMAnalysis.fromJson(
        decoded,
        transcripcionRecibida: ocrBundle.rawJoinedText,
        rawContent: content,
        rawJson: response.body,
        sanitizedJson: sanitized,
      );
    } catch (error) {
      _logLarge('GROQ_PARSE_ERROR', error.toString());
      throw LlmException('Invalid JSON from Groq: $error');
    }
  }

  String _sanitizeJson(String raw) {
    String cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    if (!cleaned.startsWith('{')) {
      final int firstBrace = cleaned.indexOf('{');
      if (firstBrace >= 0) {
        cleaned = cleaned.substring(firstBrace);
      }
    }
    return cleaned.trim();
  }

  void dispose() {
    _client.close();
  }

  void _logLarge(String tag, String text) {
    const int chunkSize = 700;
    if (text.isEmpty) {
      debugPrint('$tag: <empty>');
      return;
    }
    for (int i = 0; i < text.length; i += chunkSize) {
      final int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint('$tag: ${text.substring(i, end)}');
    }
  }
}

class LlmException implements Exception {
  const LlmException(this.message);

  final String message;

  @override
  String toString() => message;
}
