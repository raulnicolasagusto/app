String displayPromptForUi({
  required String prompt,
  required String? levelId,
}) {
  final String level = levelId?.trim() ?? '';
  if (level == 'primary' && !prompt.contains('=')) {
    return '$prompt = ?';
  }
  return prompt;
}

