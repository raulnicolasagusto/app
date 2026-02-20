import unittest
from pathlib import Path
import sys

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.main import app


class ApiTest(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    def test_correct_solution(self) -> None:
        response = self.client.post(
            "/v1/validate-solution",
            json={
                "equation_prompt": "2x+5=17",
                "expected_final": "x=6",
                "context_hint": None,
                "ocr_lines": ["2x=17-5", "x=12/2", "x=6"],
                "variable": "x",
                "locale": "es",
            },
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["decision"], "correct")
        self.assertTrue(data["final_result_correct"])
        self.assertTrue(data["process_valid"])

    def test_correct_with_warnings_process(self) -> None:
        response = self.client.post(
            "/v1/validate-solution",
            json={
                "equation_prompt": "2x+5=17",
                "expected_final": "x=6",
                "context_hint": None,
                "ocr_lines": ["2x=17-5", "x=12x2", "x=6"],
                "variable": "x",
                "locale": "es",
            },
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["decision"], "correct_with_warnings")
        self.assertTrue(data["final_result_correct"])
        self.assertFalse(data["process_valid"])

    def test_context_hint_used(self) -> None:
        response = self.client.post(
            "/v1/validate-solution",
            json={
                "equation_prompt": "2x+2y=20",
                "expected_final": "x=6",
                "context_hint": "y=4",
                "ocr_lines": ["2x+8=20", "2x=20-8", "x=12/2", "x=6"],
                "variable": "x",
                "locale": "es",
            },
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertTrue(data["final_result_correct"])
        self.assertEqual(data["decision"], "correct")

    def test_ocr_ambiguous_warning(self) -> None:
        response = self.client.post(
            "/v1/validate-solution",
            json={
                "equation_prompt": "x=5",
                "expected_final": "x=5",
                "context_hint": None,
                "ocr_lines": ["x=S"],
                "ocr_candidates": [
                    {
                        "lineIndex": 1,
                        "candidates": [
                            {"text": "x=S", "score": 0.1, "mathScore": 8},
                            {"text": "x=5", "score": 0.2, "mathScore": 12},
                        ],
                    }
                ],
                "variable": "x",
                "locale": "es",
            },
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn(data["decision"], ["correct_with_warnings", "correct"])
        if data["decision"] == "correct_with_warnings":
            self.assertTrue(len(data["warning_lines"]) >= 1)


if __name__ == "__main__":
    unittest.main()

