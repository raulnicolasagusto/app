from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Literal

from sympy import Eq, S, simplify, solveset, sympify
from sympy.core.expr import Expr
from sympy.parsing.sympy_parser import (
    convert_xor,
    implicit_multiplication_application,
    parse_expr,
    standard_transformations,
)
from sympy.sets.sets import Set

from .schemas import OcrLineCandidatesPayload, StepValidationPayload

ValidationStatus = Literal["valid", "invalid", "undetermined"]
EquivalenceMode = Literal["solution_set", "algebraic"]

_TRANSFORMATIONS = standard_transformations + (
    implicit_multiplication_application,
    convert_xor,
)


@dataclass(frozen=True)
class ParsedStep:
    raw: str
    normalized: str
    is_equation: bool
    expr: Expr | None
    eq: Eq | None
    parse_error: str | None


@dataclass(frozen=True)
class SequenceCandidate:
    lines: list[str]
    score: int
    warning_type: str | None
    warning_message: str | None
    ambiguous_lines: list[int]


def normalize_text(value: str) -> str:
    cleaned = value.strip()
    cleaned = cleaned.replace("−", "-").replace("–", "-")
    cleaned = cleaned.replace("×", "*").replace("÷", "/")
    cleaned = cleaned.replace(",", ".")
    cleaned = cleaned.replace("X", "x")
    cleaned = re.sub(r"\s+", "", cleaned)
    return cleaned


def parse_context_substitutions(context_hint: str | None) -> dict[str, Expr]:
    if context_hint is None or not context_hint.strip():
        return {}
    result: dict[str, Expr] = {}
    normalized = context_hint.replace(";", ",").replace(" ", "")
    for token in normalized.split(","):
        if "=" not in token:
            continue
        name, raw = token.split("=", 1)
        if not re.fullmatch(r"[a-zA-Z]\w*", name):
            continue
        try:
            result[name] = parse_expr(raw, transformations=_TRANSFORMATIONS, evaluate=True)
        except Exception:
            continue
    return result


def parse_step(raw: str) -> ParsedStep:
    normalized = normalize_text(raw)
    if not normalized:
        return ParsedStep(raw, normalized, False, None, None, "empty_step")

    if normalized.count("=") == 1:
        lhs_raw, rhs_raw = normalized.split("=")
        try:
            lhs = parse_expr(lhs_raw, transformations=_TRANSFORMATIONS, evaluate=True)
            rhs = parse_expr(rhs_raw, transformations=_TRANSFORMATIONS, evaluate=True)
            eq = Eq(lhs, rhs, evaluate=False)
        except Exception as exc:
            return ParsedStep(raw, normalized, True, None, None, f"parse_error:{exc}")
        return ParsedStep(raw, normalized, True, None, eq, None)

    if "=" in normalized:
        return ParsedStep(raw, normalized, True, None, None, "invalid_equation_format")

    try:
        expr = parse_expr(normalized, transformations=_TRANSFORMATIONS, evaluate=True)
    except Exception as exc:
        return ParsedStep(raw, normalized, False, None, None, f"parse_error:{exc}")
    return ParsedStep(raw, normalized, False, expr, None, None)


def apply_substitutions(step: ParsedStep, substitutions: dict[str, Expr]) -> ParsedStep:
    if not substitutions:
        return step
    if step.eq is not None:
        return ParsedStep(
            raw=step.raw,
            normalized=step.normalized,
            is_equation=True,
            expr=None,
            eq=Eq(step.eq.lhs.subs(substitutions), step.eq.rhs.subs(substitutions)),
            parse_error=step.parse_error,
        )
    if step.expr is not None:
        return ParsedStep(
            raw=step.raw,
            normalized=step.normalized,
            is_equation=False,
            expr=step.expr.subs(substitutions),
            eq=None,
            parse_error=step.parse_error,
        )
    return step


def _solution_set(eq: Eq, variable: str) -> Set | None:
    symbol = sympify(variable)
    try:
        return solveset(eq, symbol, domain=S.Reals)
    except Exception:
        return None


def _set_to_string(value: Set | None) -> str | None:
    return None if value is None else str(value)


def _has_unknown_symbols(step: ParsedStep, variable: str, substitutions: dict[str, Expr]) -> bool:
    known = {sympify(variable), *[sympify(k) for k in substitutions.keys()]}
    if step.eq is not None:
        if not hasattr(step.eq, "lhs") or not hasattr(step.eq, "rhs"):
            return False
        symbols = step.eq.lhs.free_symbols.union(step.eq.rhs.free_symbols)
    elif step.expr is not None:
        symbols = step.expr.free_symbols
    else:
        return True
    return any(symbol not in known for symbol in symbols)


def classify_error(previous: ParsedStep, current: ParsedStep) -> str:
    if previous.parse_error or current.parse_error:
        return "parse_error"
    if previous.is_equation and current.is_equation:
        p = previous.normalized
        c = current.normalized
        if p.replace("+-", "-") == c.replace("-+", "-"):
            return "not_equivalent"
        if ("+" in p and "+" in c) or ("-" in p and "-" in c):
            return "sign_error"
        if p.count("=") == 1 and c.count("=") == 1:
            pl, pr = p.split("=")
            cl, cr = c.split("=")
            if pl == cl and pr != cr:
                return "not_applied_both_sides"
            if pr == cr and pl != cl:
                return "not_applied_both_sides"
        if "/" in p or "/" in c:
            return "fraction_error"
        if "(" in p or ")" in p or "(" in c or ")" in c:
            return "distribution_error"
        return "arithmetic_error"
    return "not_equivalent"


def compare_steps(
    previous: ParsedStep,
    current: ParsedStep,
    variable: str,
    substitutions: dict[str, Expr] | None = None,
) -> StepValidationPayload:
    effective_subs = substitutions or {}
    prev = apply_substitutions(previous, effective_subs)
    curr = apply_substitutions(current, effective_subs)

    if prev.parse_error or curr.parse_error:
        return StepValidationPayload(
            from_step=prev.raw,
            to_step=curr.raw,
            from_normalized=prev.normalized,
            to_normalized=curr.normalized,
            equivalent=False,
            validation_status="invalid",
            equivalence_mode="algebraic",
            reason="parse_error",
        )

    if _has_unknown_symbols(prev, variable, effective_subs) or _has_unknown_symbols(
        curr,
        variable,
        effective_subs,
    ):
        return StepValidationPayload(
            from_step=prev.raw,
            to_step=curr.raw,
            from_normalized=prev.normalized,
            to_normalized=curr.normalized,
            equivalent=False,
            validation_status="undetermined",
            equivalence_mode="solution_set" if prev.is_equation and curr.is_equation else "algebraic",
            reason="missing_context",
        )

    if prev.is_equation and curr.is_equation and prev.eq is not None and curr.eq is not None:
        mode: EquivalenceMode = "solution_set"
        prev_set = _solution_set(prev.eq, variable)
        curr_set = _solution_set(curr.eq, variable)
        if prev_set is None or curr_set is None:
            return StepValidationPayload(
                from_step=prev.raw,
                to_step=curr.raw,
                from_normalized=prev.normalized,
                to_normalized=curr.normalized,
                equivalent=False,
                validation_status="undetermined",
                equivalence_mode=mode,
                reason="undetermined",
                previous_solution_set=_set_to_string(prev_set),
                current_solution_set=_set_to_string(curr_set),
            )
        if "ConditionSet" in str(prev_set) or "ConditionSet" in str(curr_set):
            return StepValidationPayload(
                from_step=prev.raw,
                to_step=curr.raw,
                from_normalized=prev.normalized,
                to_normalized=curr.normalized,
                equivalent=False,
                validation_status="undetermined",
                equivalence_mode=mode,
                reason="undetermined",
                previous_solution_set=_set_to_string(prev_set),
                current_solution_set=_set_to_string(curr_set),
            )

        equivalent = bool(simplify(prev_set.symmetric_difference(curr_set)) == S.EmptySet)
        return StepValidationPayload(
            from_step=prev.raw,
            to_step=curr.raw,
            from_normalized=prev.normalized,
            to_normalized=curr.normalized,
            equivalent=equivalent,
            validation_status="valid" if equivalent else "invalid",
            equivalence_mode=mode,
            reason="equivalent_solution_set" if equivalent else "not_equivalent_solution_set",
            previous_solution_set=_set_to_string(prev_set),
            current_solution_set=_set_to_string(curr_set),
        )

    mode: EquivalenceMode = "algebraic"
    if prev.expr is None or curr.expr is None:
        return StepValidationPayload(
            from_step=prev.raw,
            to_step=curr.raw,
            from_normalized=prev.normalized,
            to_normalized=curr.normalized,
            equivalent=False,
            validation_status="invalid",
            equivalence_mode=mode,
            reason="mixed_or_invalid_step_type",
        )

    try:
        equivalent = bool(simplify(prev.expr - curr.expr) == 0)
    except Exception:
        return StepValidationPayload(
            from_step=prev.raw,
            to_step=curr.raw,
            from_normalized=prev.normalized,
            to_normalized=curr.normalized,
            equivalent=False,
            validation_status="undetermined",
            equivalence_mode=mode,
            reason="undetermined",
        )
    return StepValidationPayload(
        from_step=prev.raw,
        to_step=curr.raw,
        from_normalized=prev.normalized,
        to_normalized=curr.normalized,
        equivalent=equivalent,
        validation_status="valid" if equivalent else "invalid",
        equivalence_mode=mode,
        reason="equivalent_expression" if equivalent else "not_equivalent_expression",
    )


def build_candidate_lines(
    ocr_lines: list[str],
    ocr_candidates: list[OcrLineCandidatesPayload] | None,
    top_k: int = 3,
) -> list[list[str]]:
    if not ocr_lines:
        return []
    by_idx: dict[int, list[str]] = {}
    if ocr_candidates:
        for line in ocr_candidates:
            idx = max(1, line.lineIndex)
            entries: list[str] = []
            for c in line.candidates[:top_k]:
                text = c.text.strip()
                if text and text not in entries:
                    entries.append(text)
            by_idx[idx] = entries

    result: list[list[str]] = []
    for i, line in enumerate(ocr_lines, start=1):
        variants: list[str] = []
        raw = line.strip()
        if raw:
            variants.append(raw)
        for alt in by_idx.get(i, []):
            if alt not in variants:
                variants.append(alt)
        if not variants:
            variants = [line]
        result.append(variants[:top_k])
    return result


def choose_candidate_sequences(
    ocr_lines: list[str],
    ocr_candidates: list[OcrLineCandidatesPayload] | None,
    beam_width: int = 5,
    top_k: int = 3,
) -> list[SequenceCandidate]:
    candidate_lines = build_candidate_lines(ocr_lines, ocr_candidates, top_k=top_k)
    if not candidate_lines:
        return []
    beams: list[SequenceCandidate] = [
        SequenceCandidate(lines=[], score=0, warning_type=None, warning_message=None, ambiguous_lines=[])
    ]

    for line_idx, options in enumerate(candidate_lines, start=1):
        next_beams: list[SequenceCandidate] = []
        unique_options = list(dict.fromkeys(options))
        ambiguous = len(unique_options) > 1
        for beam in beams:
            for rank, option in enumerate(unique_options):
                score = beam.score + (10 - rank * 3)
                warning_type = beam.warning_type
                warning_message = beam.warning_message
                ambiguous_lines = list(beam.ambiguous_lines)
                norm = normalize_text(option)
                if re.search(r"[sS]", option) and re.search(r"=\s*[sS]\b", option):
                    score -= 3
                if ambiguous and rank > 0:
                    ambiguous_lines.append(line_idx)
                    if warning_type is None:
                        warning_type = "ocr_ambiguous"
                        warning_message = "Hay ambiguedad OCR en al menos una linea."
                if not norm:
                    score -= 5
                next_beams.append(
                    SequenceCandidate(
                        lines=[*beam.lines, option],
                        score=score,
                        warning_type=warning_type,
                        warning_message=warning_message,
                        ambiguous_lines=ambiguous_lines,
                    )
                )
        next_beams.sort(key=lambda b: b.score, reverse=True)
        beams = next_beams[:beam_width]
    return beams
