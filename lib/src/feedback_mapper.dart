import 'models.dart';

enum UiDecision {
  unreadable,
  correct,
  incorrect,
}

UiDecision decideUiDecision(
  LLMAnalysis analysis, {
  required bool hasUsableMathCandidates,
}) {
  if (!analysis.ocrLegible && !hasUsableMathCandidates) {
    return UiDecision.unreadable;
  }
  if (analysis.resultadoFinalCorrecto) {
    return UiDecision.correct;
  }
  return UiDecision.incorrect;
}

List<int> buildWrongLineNumbers({
  required List<int> wrongLines,
  required int lineBandCount,
  required int finalResultLine,
  required bool includeFinalLine,
}) {
  final int safeLineCount = lineBandCount <= 0 ? 1 : lineBandCount;
  final Set<int> lines = <int>{};
  for (final int raw in wrongLines) {
    lines.add(raw.clamp(1, safeLineCount));
  }
  if (includeFinalLine) {
    lines.add(finalResultLine.clamp(1, safeLineCount));
  }
  final List<int> sorted = lines.toList()..sort();
  return sorted;
}
