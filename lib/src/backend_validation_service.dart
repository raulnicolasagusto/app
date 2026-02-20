import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class BackendValidationService {
  BackendValidationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 12);

  String get _baseUrl =>
      (dotenv.env['BACKEND_BASE_URL'] ?? 'http://127.0.0.1:8000').trim();

  Future<BackendValidationResult> validate({
    required EquationItem equation,
    required OcrBundle ocrBundle,
    String variable = 'x',
    String locale = 'es',
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'equation_prompt': equation.prompt,
      'expected_final': equation.expectedFinal,
      'context_hint': equation.contextHint,
      'ocr_lines': ocrBundle.lines,
      'ocr_candidates': ocrBundle.lineResults
          .map((OcrLineResult line) => <String, dynamic>{
                'lineIndex': line.lineIndex,
                'candidates': line.candidates
                    .map((OcrCandidate c) => <String, dynamic>{
                          'text': c.text,
                          'score': c.score,
                          'mathScore': c.mathScore,
                        })
                    .toList(growable: false),
              })
          .toList(growable: false),
      'variable': variable,
      'locale': locale,
    };

    final Uri uri = Uri.parse('$_baseUrl/v1/validate-solution');
    debugPrint('BACKEND_VALIDATE_URL: $uri');
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } catch (error) {
      debugPrint('BACKEND_VALIDATE_NETWORK_ERROR: $error');
      throw BackendValidationException('Error de red con backend: $error');
    }

    if (response.statusCode != 200) {
      debugPrint('BACKEND_VALIDATE_HTTP_ERROR: ${response.statusCode} ${response.body}');
      throw BackendValidationException(
        'Backend error ${response.statusCode}: ${response.body}',
      );
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    return BackendValidationResult.fromJson(decoded);
  }

  void dispose() {
    _client.close();
  }
}

class BackendValidationException implements Exception {
  const BackendValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
