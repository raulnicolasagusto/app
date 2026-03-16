import 'package:app/src/curriculum/prompt_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('displayPromptForUi shows = ? for primary expressions', () {
    expect(
      displayPromptForUi(prompt: '4 + 3', levelId: 'primary'),
      '4 + 3 = ?',
    );
  });

  test('displayPromptForUi does not change equations', () {
    expect(
      displayPromptForUi(prompt: '2x + 5 = 17', levelId: 'primary'),
      '2x + 5 = 17',
    );
  });

  test('displayPromptForUi does not change non-primary prompts', () {
    expect(
      displayPromptForUi(prompt: '4 + 3', levelId: 'secondary'),
      '4 + 3',
    );
  });
}

