import 'package:app/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LLMAnalysis parses new decision fields', () {
    final LLMAnalysis analysis = LLMAnalysis.fromJson(
      <String, dynamic>{
        'transcripcion_recibida': 'x=8',
        'ocr_legible': true,
        'resultado_final_texto': 'x=8',
        'resultado_final_correcto': true,
        'correcto_global': true,
        'transcripcion_reconstruida': <String>['x=8'],
        'lineas_incorrectas': <int>[],
        'explicacion_breve': 'ok',
        'correccion_desde_error': <String>[],
      },
    );

    expect(analysis.ocrLegible, isTrue);
    expect(analysis.resultadoFinalCorrecto, isTrue);
    expect(analysis.correctoGlobal, isTrue);
    expect(analysis.lineasIncorrectas, isEmpty);
    expect(analysis.transcripcionReconstruida, <String>['x=8']);
  });

  test('LLMAnalysis applies fallback when fields are missing', () {
    final LLMAnalysis analysis = LLMAnalysis.fromJson(
      <String, dynamic>{
        'transcripcion_recibida': 'cherry blossom',
        'correcto': false,
      },
    );

    expect(analysis.ocrLegible, isFalse);
    expect(analysis.resultadoFinalCorrecto, isFalse);
    expect(analysis.correctoGlobal, isFalse);
  });
}
