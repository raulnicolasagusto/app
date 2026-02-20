import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.math_engine import (
    choose_candidate_sequences,
    compare_steps,
    parse_context_substitutions,
    parse_step,
)
from app.schemas import OcrCandidatePayload, OcrLineCandidatesPayload


class MathEngineTest(unittest.TestCase):
    def test_solution_set_equivalent(self) -> None:
        a = parse_step("2x=4")
        b = parse_step("x=2")
        result = compare_steps(a, b, "x")
        self.assertEqual(result.equivalence_mode, "solution_set")
        self.assertTrue(result.equivalent)
        self.assertEqual(result.validation_status, "valid")

    def test_solution_set_invalid(self) -> None:
        a = parse_step("2x=4")
        b = parse_step("2x=5")
        result = compare_steps(a, b, "x")
        self.assertFalse(result.equivalent)
        self.assertEqual(result.validation_status, "invalid")

    def test_multi_root_not_equivalent(self) -> None:
        a = parse_step("x(x-1)=0")
        b = parse_step("x=0")
        result = compare_steps(a, b, "x")
        self.assertFalse(result.equivalent)
        self.assertEqual(result.equivalence_mode, "solution_set")

    def test_algebraic_equivalent(self) -> None:
        a = parse_step("x+1")
        b = parse_step("1+x")
        result = compare_steps(a, b, "x")
        self.assertTrue(result.equivalent)
        self.assertEqual(result.equivalence_mode, "algebraic")

    def test_identity_equivalent(self) -> None:
        a = parse_step("0=0")
        b = parse_step("x=x")
        result = compare_steps(a, b, "x")
        self.assertTrue(result.equivalent)

    def test_contradiction_invalid(self) -> None:
        a = parse_step("0=5")
        b = parse_step("x=1")
        result = compare_steps(a, b, "x")
        self.assertFalse(result.equivalent)

    def test_parse_error(self) -> None:
        a = parse_step("2x=4")
        b = parse_step("x==2")
        result = compare_steps(a, b, "x")
        self.assertEqual(result.reason, "parse_error")

    def test_undetermined(self) -> None:
        a = parse_step("sin(x)=x")
        b = parse_step("sin(x)-x=0")
        result = compare_steps(a, b, "x")
        self.assertEqual(result.validation_status, "undetermined")

    def test_context_substitution(self) -> None:
        subs = parse_context_substitutions("y=4")
        a = parse_step("2x+2y=20")
        b = parse_step("2x+8=20")
        result = compare_steps(a, b, "x", substitutions=subs)
        self.assertTrue(result.equivalent)
        self.assertEqual(result.validation_status, "valid")

    def test_missing_context(self) -> None:
        a = parse_step("2x+2y=20")
        b = parse_step("2x+8=20")
        result = compare_steps(a, b, "x")
        self.assertEqual(result.validation_status, "undetermined")
        self.assertEqual(result.reason, "missing_context")

    def test_candidate_sequences(self) -> None:
        candidates = [
            OcrLineCandidatesPayload(
                lineIndex=1,
                candidates=[
                    OcrCandidatePayload(text="x=S", score=0.2, mathScore=6),
                    OcrCandidatePayload(text="x=5", score=0.5, mathScore=12),
                ],
            ),
        ]
        seqs = choose_candidate_sequences(["x=S"], candidates, top_k=2, beam_width=3)
        self.assertGreaterEqual(len(seqs), 1)
        self.assertIn("x=S", seqs[0].lines[0])


if __name__ == "__main__":
    unittest.main()
