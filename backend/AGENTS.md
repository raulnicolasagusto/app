## Project context
App name: MathInk
Target: Android físico (recomendado; evitar depender del emulador)
Flutter/Dart: Dart `^3.10.1` (ver `pubspec.yaml`)
State management: setState (no Provider/BLoC in MVP)

## Critical architecture decisions
- Canvas input uses GestureDetector + CustomPainter
- OCR: Google ML Kit Digital Ink Recognition
- Math validation: Python backend with SymPy (POST request)
- LLM feedback: Groq API, model llama-3.1-8b-instant
- Secrets via `--dart-define` (preferido) o `.env` local (solo dev). Nunca hardcodear.
- Two canvas layers: userStrokes vs feedbackElements, never mix them

## File structure
lib/src/
  math_canvas_screen.dart  ← main screen
  canvas_painter.dart      ← CustomPainter render
  ink_service.dart         ← ML Kit OCR
  llm_service.dart         ← Groq API
  equation_bank.dart       ← equation pool
  models.dart              ← domain types
  backend_validation_service.dart ← SymPy backend

## Coding rules
- Never mix userStrokes and feedbackElements in the same list
- Always sanitize Groq JSON response before jsonDecode (remove fences, trim, find first {)
- ML Kit primary model: zxx-Zsym-x-math, fallback: en-US
- StrokePoint timestamps must use DateTime.now().millisecondsSinceEpoch (never 0)
- All network calls have 10s timeout
- Si `correct` sin warnings: no tachar en rojo. Si `correct_with_warnings`: tachar solo líneas con warning.

## Do not
- Do not use Provider, BLoC or Riverpod
- Do not use emulator-dependent features
- Do not hardcode API keys
- Do not add packages without asking first

## Helpful skills (optional)
- [flutter-expert](.agents/skills/flutter-expert/SKILL.md)
- [flutter-animations](.agents/skills/flutter-animations/SKILL.md)
- [prompt-engineering-patterns](.agents/skills/prompt-engineering-patterns/SKILL.md)
