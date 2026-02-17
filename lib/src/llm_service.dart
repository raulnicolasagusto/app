import 'dart:convert';

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
    required String transcription,
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

    final Map<String, dynamic> body = <String, dynamic>{
      'model': _model,
      'temperature': 0.2,
      'response_format': <String, dynamic>{'type': 'json_object'},
      'messages': <Map<String, String>>[
        <String, String>{
          'role': 'system',
          'content':
              'Sos un profesor de matematicas y evaluas pasos de resolucion. '
                  'Respond ONLY with valid JSON, no markdown, no extra text, no code fences',
        },
        <String, String>{
          'role': 'user',
          'content': '''
Problema dado al alumno: $equation$hintLine
Resultado final esperado: $expectedFinal

Transcripcion del alumno:
$transcription

Analiza cada paso y responde EXCLUSIVAMENTE este JSON:
{
  "correcto": true/false,
  "pasos": [
    { "linea": 1, "texto": "linea del alumno", "ok": true/false }
  ],
  "correccion": ["paso correcto 1", "paso correcto 2", "resultado final"]
}

Reglas:
- Si el alumno llega al resultado esperado y sus pasos son matematicamente coherentes, "correcto" debe ser true.
- Si "correcto" es true, devuelve "correccion" como lista vacia.
- Si "correcto" es false, marca las lineas incorrectas y completa "correccion".
''',
        },
      ],
    };

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

    final String sanitized = _sanitizeJson(content);
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(sanitized) as Map<String, dynamic>;
      return LLMAnalysis.fromJson(decoded);
    } catch (error) {
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
}

class LlmException implements Exception {
  const LlmException(this.message);

  final String message;

  @override
  String toString() => message;
}
