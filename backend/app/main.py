from __future__ import annotations

import time
from dataclasses import dataclass

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .math_engine import (
    SequenceCandidate,
    choose_candidate_sequences,
    classify_error,
    compare_steps,
    parse_context_substitutions,
    parse_step,
)
from .prompting import FeedbackInput, generate_pedagogical_feedback
from .schemas import StepValidationPayload, ValidateSolutionRequest, ValidateSolutionResponse
from .storage import init_db, load_db_config, save_validation_run

app = FastAPI(title="Math Fight Backend", version="1.1.0")
db_config = load_db_config()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup_event() -> None:
    init_db(db_config)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@dataclass(frozen=True)
class EvalResult:
    lines: list[str]
    normalized_steps: list[str]
    step_validations: list[StepValidationPayload]
    process_valid: bool
    final_result_correct: bool
    validation_status: str
    first_error_index: int | None
    error_type: str | None
    equivalence_mode: str
    previous_solution_set: str | None
    current_solution_set: str | None


def _build_unreadable_response(reason: str, final_result_line: int) -> ValidateSolutionResponse:
    return ValidateSolutionResponse(
        decision="unreadable",
        is_correct=False,
        final_result_correct=False,
        process_valid=False,
        warning_lines=[],
        wrong_lines=[],
        final_result_line=max(1, final_result_line),
        first_error_index=None,
        error_type=reason,
        warning_type=None,
        warning_message="No pude interpretar la escritura con suficiente confianza.",
        validation_status="undetermined",
        equivalence_mode="algebraic",
        previous_solution_set=None,
        current_solution_set=None,
        normalized_steps=[],
        step_validations=[],
        pedagogical_feedback="No pude interpretar la escritura con suficiente confianza.",
        suggested_correction_steps=["Escribe cada paso mas claro y en lineas separadas."],
        debug={"reason": reason},
    )


def _evaluate_sequence(payload: ValidateSolutionRequest, sequence: SequenceCandidate) -> EvalResult:
    full_steps = [payload.equation_prompt, *sequence.lines]
    substitutions = parse_context_substitutions(payload.context_hint)
    parsed = [parse_step(step) for step in full_steps]
    normalized_steps = [step.normalized for step in parsed]

    step_validations: list[StepValidationPayload] = []
    process_valid = True
    validation_status = "valid"
    first_error_index: int | None = None
    error_type: str | None = None
    equivalence_mode = "solution_set"
    prev_set: str | None = None
    curr_set: str | None = None

    for idx in range(len(parsed) - 1):
        previous = parsed[idx]
        current = parsed[idx + 1]
        result = compare_steps(previous, current, payload.variable, substitutions=substitutions)
        step_validations.append(result)
        equivalence_mode = result.equivalence_mode
        prev_set = result.previous_solution_set
        curr_set = result.current_solution_set
        if result.validation_status == "undetermined":
            process_valid = False
            validation_status = "undetermined"
            first_error_index = idx
            error_type = "undetermined"
            break
        if not result.equivalent:
            process_valid = False
            validation_status = "invalid"
            first_error_index = idx
            error_type = classify_error(previous, current)
            break

    expected_step = parse_step(payload.expected_final)
    final_step = parsed[-1]
    expected_check = compare_steps(
        final_step,
        expected_step,
        payload.variable,
        substitutions=substitutions,
    )
    final_result_correct = (
        expected_check.validation_status == "valid" and expected_check.equivalent
    )

    if expected_check.validation_status == "undetermined" and final_result_correct is False:
        validation_status = "undetermined"
        if error_type is None:
            error_type = "undetermined"
        equivalence_mode = expected_check.equivalence_mode
        prev_set = expected_check.previous_solution_set
        curr_set = expected_check.current_solution_set

    return EvalResult(
        lines=sequence.lines,
        normalized_steps=normalized_steps,
        step_validations=step_validations,
        process_valid=process_valid,
        final_result_correct=final_result_correct,
        validation_status=validation_status,
        first_error_index=first_error_index,
        error_type=error_type,
        equivalence_mode=equivalence_mode,
        previous_solution_set=prev_set,
        current_solution_set=curr_set,
    )


def _score_eval(eval_result: EvalResult) -> int:
    score = 0
    if eval_result.final_result_correct:
        score += 100
    if eval_result.process_valid:
        score += 50
    if eval_result.validation_status == "undetermined":
        score -= 20
    if eval_result.error_type == "parse_error":
        score -= 30
    return score


@app.post("/v1/validate-solution", response_model=ValidateSolutionResponse)
def validate_solution(payload: ValidateSolutionRequest) -> ValidateSolutionResponse:
    # Ensures migrations exist even when startup hooks are skipped by some test runners.
    init_db(db_config)
    started = time.perf_counter()
    user_lines = [line for line in payload.ocr_lines if line.strip()]
    final_result_line = max(1, len(user_lines))
    if not user_lines:
        return _build_unreadable_response("parse_error", final_result_line)

    candidates = choose_candidate_sequences(
        user_lines,
        payload.ocr_candidates,
        beam_width=5,
        top_k=3,
    )
    if not candidates:
        return _build_unreadable_response("parse_error", final_result_line)

    best_eval: EvalResult | None = None
    best_candidate: SequenceCandidate | None = None
    best_score = -10_000
    scored_sequences: list[dict[str, object]] = []
    for candidate in candidates:
        evaluated = _evaluate_sequence(payload, candidate)
        score = _score_eval(evaluated) + candidate.score
        scored_sequences.append(
            {
                "lines": candidate.lines,
                "score": score,
                "final_result_correct": evaluated.final_result_correct,
                "process_valid": evaluated.process_valid,
            }
        )
        if score > best_score:
            best_score = score
            best_eval = evaluated
            best_candidate = candidate

    if best_eval is None or best_candidate is None:
        return _build_unreadable_response("parse_error", final_result_line)

    final_result_correct = best_eval.final_result_correct
    process_valid = best_eval.process_valid
    warning_type = best_candidate.warning_type
    warning_message = best_candidate.warning_message

    has_ambiguity_warning = warning_type is not None and warning_type == "ocr_ambiguous"
    if final_result_correct and process_valid and not has_ambiguity_warning:
        decision = "correct"
        is_correct = True
    elif final_result_correct and (not process_valid or has_ambiguity_warning):
        decision = "correct_with_warnings"
        is_correct = True
        if warning_type is None:
            warning_type = "process_inconsistent"
            warning_message = (
                "El resultado final es correcto, pero hay un paso intermedio para revisar."
            )
    elif best_eval.validation_status == "undetermined":
        decision = "unreadable"
        is_correct = False
    else:
        decision = "incorrect"
        is_correct = False

    wrong_lines: list[int] = []
    warning_lines: list[int] = []
    if best_eval.first_error_index is not None:
        line_no = min(max(1, best_eval.first_error_index + 1), final_result_line)
        if decision == "correct_with_warnings":
            warning_lines.append(line_no)
        else:
            wrong_lines.append(line_no)
    warning_lines.extend([line for line in best_candidate.ambiguous_lines if line <= final_result_line])
    wrong_lines = sorted(set(wrong_lines))
    warning_lines = sorted(set(warning_lines))

    feedback = generate_pedagogical_feedback(
        FeedbackInput(
            decision=decision,
            error_type=best_eval.error_type,
            warning_type=warning_type,
            expected_final=payload.expected_final,
            normalized_steps=best_eval.normalized_steps,
            step_validations=[item.model_dump() for item in best_eval.step_validations],
            wrong_lines=wrong_lines,
            warning_lines=warning_lines,
            final_result_correct=final_result_correct,
            process_valid=process_valid,
            locale=payload.locale,
            warning_message=warning_message,
        )
    )

    response = ValidateSolutionResponse(
        decision=decision,  # type: ignore[arg-type]
        is_correct=is_correct,
        final_result_correct=final_result_correct,
        process_valid=process_valid,
        warning_lines=warning_lines,
        wrong_lines=wrong_lines,
        final_result_line=final_result_line,
        first_error_index=best_eval.first_error_index,
        error_type=best_eval.error_type,
        warning_type=warning_type,
        warning_message=warning_message,
        validation_status=best_eval.validation_status,  # type: ignore[arg-type]
        equivalence_mode=best_eval.equivalence_mode,  # type: ignore[arg-type]
        previous_solution_set=best_eval.previous_solution_set,
        current_solution_set=best_eval.current_solution_set,
        normalized_steps=best_eval.normalized_steps,
        step_validations=best_eval.step_validations,
        pedagogical_feedback=feedback.short_feedback,
        suggested_correction_steps=feedback.correction_steps,
        debug={
            "input_steps": [payload.equation_prompt, *user_lines],
            "selected_lines": best_eval.lines,
            "candidate_scores": scored_sequences,
            "has_ocr_candidates": bool(payload.ocr_candidates),
            "tone": feedback.tone,
        },
    )

    elapsed_ms = int((time.perf_counter() - started) * 1000)
    save_validation_run(
        db_config,
        equation_prompt=payload.equation_prompt,
        expected_final=payload.expected_final,
        ocr_lines=user_lines,
        decision=response.decision,
        error_type=response.error_type,
        warning_type=response.warning_type,
        wrong_lines=response.wrong_lines,
        warning_lines=response.warning_lines,
        final_result_correct=response.final_result_correct,
        process_valid=response.process_valid,
        latency_ms=elapsed_ms,
        step_validations=[item.model_dump() for item in response.step_validations],
    )
    return response
