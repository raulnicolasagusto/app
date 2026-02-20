import 'package:app/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BackendValidationResult parses response payload', () {
    final BackendValidationResult result = BackendValidationResult.fromJson(
      <String, dynamic>{
        'decision': 'incorrect',
        'is_correct': false,
        'final_result_correct': false,
        'process_valid': false,
        'warning_lines': <int>[1],
        'wrong_lines': <int>[2, 3],
        'final_result_line': 3,
        'first_error_index': 1,
        'error_type': 'sign_error',
        'warning_type': 'ocr_ambiguous',
        'warning_message': 'Ambiguedad OCR',
        'validation_status': 'invalid',
        'equivalence_mode': 'solution_set',
        'previous_solution_set': '{2}',
        'current_solution_set': '{-2}',
        'normalized_steps': <String>['2*x+3=7', '2*x=7+3', 'x=5'],
        'step_validations': <Map<String, dynamic>>[
          <String, dynamic>{
            'from_step': '2x+3=7',
            'to_step': '2x=7+3',
            'from_normalized': '2*x+3=7',
            'to_normalized': '2*x=7+3',
            'equivalent': false,
            'validation_status': 'invalid',
            'equivalence_mode': 'solution_set',
            'reason': 'not_equivalent_solution_set',
          },
        ],
        'pedagogical_feedback': 'Hay un error de signo.',
        'suggested_correction_steps': <String>['2x=7-3', '2x=4', 'x=2'],
        'debug': <String, dynamic>{'request_id': 'abc'},
      },
    );

    expect(result.decision, 'incorrect');
    expect(result.warningLines, <int>[1]);
    expect(result.wrongLines, <int>[2, 3]);
    expect(result.warningType, 'ocr_ambiguous');
    expect(result.validationStatus, 'invalid');
    expect(result.equivalenceMode, 'solution_set');
    expect(result.stepValidations.first.equivalent, isFalse);
    expect(result.suggestedCorrectionSteps.length, 3);
  });
}
