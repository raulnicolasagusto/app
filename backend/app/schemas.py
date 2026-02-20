from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


class OcrCandidatePayload(BaseModel):
    text: str = ""
    score: float = 0.0
    mathScore: int = 0


class OcrLineCandidatesPayload(BaseModel):
    lineIndex: int = 0
    candidates: list[OcrCandidatePayload] = Field(default_factory=list)


class ValidateSolutionRequest(BaseModel):
    equation_prompt: str
    expected_final: str
    context_hint: str | None = None
    ocr_lines: list[str] = Field(default_factory=list)
    ocr_candidates: list[OcrLineCandidatesPayload] | None = None
    variable: str = "x"
    locale: str = "es"


class StepValidationPayload(BaseModel):
    from_step: str
    to_step: str
    from_normalized: str
    to_normalized: str
    equivalent: bool
    validation_status: Literal["valid", "invalid", "undetermined"]
    equivalence_mode: Literal["solution_set", "algebraic"]
    reason: str
    previous_solution_set: str | None = None
    current_solution_set: str | None = None


class ValidateSolutionResponse(BaseModel):
    decision: Literal["correct", "correct_with_warnings", "incorrect", "unreadable"]
    is_correct: bool
    final_result_correct: bool
    process_valid: bool
    warning_lines: list[int] = Field(default_factory=list)
    wrong_lines: list[int] = Field(default_factory=list)
    final_result_line: int
    first_error_index: int | None = None
    error_type: str | None = None
    warning_type: str | None = None
    warning_message: str | None = None
    validation_status: Literal["valid", "invalid", "undetermined"]
    equivalence_mode: Literal["solution_set", "algebraic"]
    previous_solution_set: str | None = None
    current_solution_set: str | None = None
    normalized_steps: list[str] = Field(default_factory=list)
    step_validations: list[StepValidationPayload] = Field(default_factory=list)
    pedagogical_feedback: str = ""
    suggested_correction_steps: list[str] = Field(default_factory=list)
    debug: dict[str, Any] = Field(default_factory=dict)


class PedagogicalOutput(BaseModel):
    short_feedback: str
    correction_steps: list[str] = Field(default_factory=list)
    tone: Literal["confirmatory_warning", "corrective", "unreadable_help"] = "corrective"
