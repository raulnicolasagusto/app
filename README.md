# Math Fight (Flutter MVP)

Aplicación Flutter para practicar resolución de ecuaciones lineales escritas a mano.
El usuario resuelve en un canvas, se reconoce el texto con OCR y luego se evalúa la resolución con un LLM para dar feedback visual inmediato.

## Objetivo del proyecto

Construir un MVP de corrección asistida para ejercicios de álgebra básica:
- Entrada manuscrita en canvas.
- OCR por líneas de resolución.
- Evaluación de pasos y resultado final con IA.
- Feedback pedagógico visual (check, tachado de líneas, corrección sugerida).

## Flujo funcional (end-to-end)

1. Se muestra una ecuación aleatoria del banco de ejercicios.
2. El usuario escribe sus pasos en el canvas.
3. Al presionar `Listo`, se ejecuta OCR con Google ML Kit Digital Ink.
4. El OCR se organiza por líneas y se seleccionan candidatos más "matemáticos".
5. Se envía al LLM (Groq) la ecuación, resultado esperado, OCR y candidatos alternativos.
6. El LLM devuelve JSON estructurado con legibilidad, líneas incorrectas y corrección.
7. La UI decide uno de tres estados:
   - `correct`: check verde.
   - `incorrect`: tacha líneas erróneas + muestra corrección tipeada.
   - `unreadable`: mensaje de escritura ilegible.

## Arquitectura del código

### Entrada y UI
- `lib/main.dart`: inicializa Flutter, carga `.env`, monta `MathFightApp`.
- `lib/src/math_canvas_screen.dart`: pantalla principal; captura trazos, dispara análisis y actualiza estado visual.
- `lib/src/canvas_painter.dart`: dibuja hoja, trazos, check/X, tachados y texto de corrección animado.

### Dominio y modelos
- `lib/src/models.dart`: entidades de ecuaciones, trazos, OCR, análisis LLM y validación local.
- `lib/src/equation_bank.dart`: banco de ecuaciones de práctica y selección aleatoria sin repetir inmediata.

### OCR y mapeo de líneas
- `lib/src/line_mapper.dart`: agrupa trazos en bandas/“líneas” según posición vertical.
- `lib/src/ink_service.dart`: OCR con `google_mlkit_digital_ink_recognition` por línea + ranking de candidatos por score matemático.

### Evaluación y decisión de feedback
- `lib/src/llm_service.dart`: llamada HTTP a Groq, prompt de evaluación y parseo/sanitizado de JSON.
- `lib/src/feedback_mapper.dart`: reglas para decisión UI (`unreadable/correct/incorrect`) y líneas a marcar.
- `lib/src/local_validator.dart`: validador algebraico local (ecuaciones lineales en `x`, con soporte de contexto `y`) útil como chequeo determinista/fallback.

## Stack y dependencias clave

- Flutter / Dart
- `google_mlkit_digital_ink_recognition` (OCR manuscrito)
- `http` (llamadas API)
- `flutter_dotenv` (variables de entorno)
- `google_fonts` (tipografía en feedback dibujado)

## Configuración

### 1) Requisitos
- Flutter SDK compatible con `sdk: ^3.10.1`.
- Dispositivo/emulador con servicios necesarios para ML Kit.

### 2) Variables de entorno
Crear archivo `.env` en la raíz con:

```env
GROQ_API_KEY=tu_api_key
BACKEND_BASE_URL=http://127.0.0.1:8000
```

> La app carga `.env` en `main.dart`. `BACKEND_BASE_URL` apunta al backend FastAPI.

### 3) Instalar dependencias

```bash
flutter pub get
```

## Ejecutar la app

```bash
flutter run
```

## Ejecutar backend SymPy

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Ejecutar tests

```bash
flutter test
```

Cobertura actual de tests (`test/`):
- Decisión de UI según resultado del análisis.
- Parseo de respuesta LLM.
- Validación algebraica local.
- Mapeo de líneas de trazos.
- Selección de candidatos OCR matemáticos.

## Estado actual del MVP

- Enfoque en ecuaciones lineales simples de práctica.
- Corrección prioriza `resultado_final_correcto` para marcar acierto global.
- Si OCR top-1 es malo, se aprovechan candidatos alternativos por línea.
- Hay logging amplio (`debugPrint`) para depurar OCR, request/response del LLM y decisión final UI.

## Posibles mejoras siguientes

- Expandir banco de ejercicios y niveles de dificultad.
- Añadir modo offline usando más validación local cuando no haya red.
- Reducir latencia y robustecer parsing contra respuestas LLM no ideales.
- Mejorar analytics/telemetría pedagógica por tipo de error.
