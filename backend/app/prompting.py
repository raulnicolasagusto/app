from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any

from pydantic import ValidationError

from .schemas import PedagogicalOutput

_GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions"
_GROQ_MODEL = "llama-3.1-8b-instant"


@dataclass(frozen=True)
class FeedbackInput:
    decision: str
    error_type: str | None
    warning_type: str | None
    expected_final: str
    normalized_steps: list[str]
    step_validations: list[dict[str, Any]]
    wrong_lines: list[int]
    warning_lines: list[int]
    final_result_correct: bool
    process_valid: bool
    locale: str
    warning_message: str | None


def _fallback(input_data: FeedbackInput) -> PedagogicalOutput:
    if input_data.decision == "correct":
        return PedagogicalOutput(
            short_feedback="Resultado y proceso correctos.",
            correction_steps=["Buen trabajo, sigue practicando."],
            tone="confirmatory_warning",
        )

    if input_data.decision == "correct_with_warnings":
        message = input_data.warning_message or "Resultado final correcto, pero revisa el paso marcado."
        return PedagogicalOutput(
            short_feedback=message,
            correction_steps=[
                "El resultado final es correcto.",
                "Revisa la linea marcada para reforzar el procedimiento.",
                f"Confirma nuevamente el resultado esperado: {input_data.expected_final}.",
            ],
            tone="confirmatory_warning",
        )

    error = input_data.error_type or "not_equivalent"
    if error == "parse_error":
        return PedagogicalOutput(
            short_feedback="No pude interpretar parte de la escritura.",
            correction_steps=[
                "Escribe los pasos mas claros y separados por linea.",
                f"Objetivo final esperado: {input_data.expected_final}.",
            ],
            tone="unreadable_help",
        )
    if error == "sign_error":
        return PedagogicalOutput(
            short_feedback="Hay un error de signo en uno de los pasos.",
            correction_steps=[
                "Cuando trasladas un termino al otro lado, cambia su signo.",
                f"Revisa y confirma que el resultado final sea {input_data.expected_final}.",
            ],
            tone="corrective",
        )

    return PedagogicalOutput(
        short_feedback="Hay un paso que no conserva la equivalencia matematica.",
        correction_steps=[
            "Revisa el primer paso marcado en rojo.",
            f"Continua hasta obtener {input_data.expected_final}.",
        ],
        tone="corrective",
    )


def _build_messages(input_data: FeedbackInput) -> list[dict[str, str]]:
    system_prompt = (
        "Eres tutor de algebra. No decides correct/incorrect; eso ya lo decidio SymPy. "
        "Solo explicas pedagogicamente. Devuelve solo JSON valido con short_feedback, correction_steps, tone."
    )

    few_shot = [
        {
            "role": "user",
            "content": json.dumps(
                {
                    "decision": "correct_with_warnings",
                    "warning_type": "process_inconsistent",
                    "warning_lines": [2],
                    "expected_final": "x=6",
                    "normalized_steps": ["2*x+5=17", "2*x=17-5", "x=12/2", "x=6"],
                }
            ),
        },
        {
            "role": "assistant",
            "content": json.dumps(
                {
                    "short_feedback": "Resultado final correcto, pero revisa el paso marcado.",
                    "correction_steps": [
                        "El resultado final coincide.",
                        "Revisa la linea marcada para asegurar equivalencia en cada paso.",
                    ],
                    "tone": "confirmatory_warning",
                }
            ),
        },
    ]

    user_payload = {
        "task": "genera feedback pedagogico",
        "locale": input_data.locale,
        "decision": input_data.decision,
        "error_type": input_data.error_type,
        "warning_type": input_data.warning_type,
        "warning_message": input_data.warning_message,
        "final_result_correct": input_data.final_result_correct,
        "process_valid": input_data.process_valid,
        "wrong_lines": input_data.wrong_lines,
        "warning_lines": input_data.warning_lines,
        "expected_final": input_data.expected_final,
        "normalized_steps": input_data.normalized_steps,
        "step_validations": input_data.step_validations[:4],
        "output_schema": {
            "short_feedback": "string",
            "correction_steps": ["string"],
            "tone": "confirmatory_warning | corrective | unreadable_help",
        },
    }
    return [
        {"role": "system", "content": system_prompt},
        *few_shot,
        {"role": "user", "content": json.dumps(user_payload, ensure_ascii=False)},
    ]


def _call_groq(messages: list[dict[str, str]], api_key: str) -> str:
    payload = {
        "model": _GROQ_MODEL,
        "temperature": 0.2,
        "response_format": {"type": "json_object"},
        "messages": messages,
    }
    req = urllib.request.Request(
        _GROQ_ENDPOINT,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=12) as response:
        body = response.read().decode("utf-8")
    decoded = json.loads(body)
    return (
        decoded.get("choices", [{}])[0]
        .get("message", {})
        .get("content", "")
        .replace("```json", "")
        .replace("```", "")
        .strip()
    )


def generate_pedagogical_feedback(input_data: FeedbackInput) -> PedagogicalOutput:
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        return _fallback(input_data)

    messages = _build_messages(input_data)
    try:
        raw = _call_groq(messages, api_key)
        return PedagogicalOutput.model_validate(json.loads(raw))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, ValidationError, KeyError):
        pass

    repair_messages = messages + [
        {
            "role": "user",
            "content": "Reintenta. Devuelve exclusivamente JSON valido con schema exacto: "
            '{"short_feedback":"string","correction_steps":["string"],'
            '"tone":"confirmatory_warning|corrective|unreadable_help"}',
        }
    ]
    try:
        raw = _call_groq(repair_messages, api_key)
        return PedagogicalOutput.model_validate(json.loads(raw))
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, ValidationError, KeyError):
        return _fallback(input_data)

