import 'package:app/src/feedback_mapper.dart';
import 'package:app/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decision is correct when resultado_final_correcto=true', () {
    final LLMAnalysis analysis = LLMAnalysis.fromJson(
      <String, dynamic>{
        'ocr_legible': true,
        'resultado_final_correcto': true,
      },
    );
    expect(
      decideUiDecision(analysis, hasUsableMathCandidates: true),
      UiDecision.correct,
    );
  });

  test('decision is incorrect when final is wrong and legible', () {
    final LLMAnalysis analysis = LLMAnalysis.fromJson(
      <String, dynamic>{
        'ocr_legible': true,
        'resultado_final_correcto': false,
      },
    );
    expect(
      decideUiDecision(analysis, hasUsableMathCandidates: true),
      UiDecision.incorrect,
    );
  });

  test('decision is unreadable when ocr_legible=false', () {
    final LLMAnalysis analysis = LLMAnalysis.fromJson(
      <String, dynamic>{
        'ocr_legible': false,
        'resultado_final_correcto': true,
      },
    );
    expect(
      decideUiDecision(analysis, hasUsableMathCandidates: false),
      UiDecision.unreadable,
    );
  });
}
