from __future__ import annotations

import json
import os
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class DbConfig:
    path: str


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_db_config() -> DbConfig:
    default_path = str(Path(__file__).resolve().parent.parent / "mathfight.db")
    return DbConfig(path=os.getenv("MATHFIGHT_DB_PATH", default_path))


def get_connection(config: DbConfig) -> sqlite3.Connection:
    conn = sqlite3.connect(config.path)
    conn.row_factory = sqlite3.Row
    return conn


def init_db(config: DbConfig) -> None:
    Path(config.path).parent.mkdir(parents=True, exist_ok=True)
    with get_connection(config) as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS rule_memory (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                topic TEXT NOT NULL,
                rule_key TEXT NOT NULL UNIQUE,
                formal_rule TEXT NOT NULL,
                informal_equivalence TEXT NOT NULL,
                examples_json TEXT NOT NULL,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS error_catalog (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                error_type TEXT NOT NULL UNIQUE,
                description TEXT NOT NULL,
                detection_hint TEXT NOT NULL,
                feedback_template TEXT NOT NULL,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS prompt_versions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                system_prompt TEXT NOT NULL,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS validation_runs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                equation_prompt TEXT NOT NULL,
                expected_final TEXT NOT NULL,
                ocr_lines_json TEXT NOT NULL,
                decision TEXT NOT NULL,
                error_type TEXT,
                warning_type TEXT,
                wrong_lines_json TEXT NOT NULL,
                warning_lines_json TEXT NOT NULL DEFAULT '[]',
                final_result_correct INTEGER NOT NULL DEFAULT 0,
                process_valid INTEGER NOT NULL DEFAULT 0,
                latency_ms INTEGER NOT NULL,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS step_diagnostics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                run_id INTEGER NOT NULL,
                step_index INTEGER NOT NULL,
                from_step TEXT NOT NULL,
                to_step TEXT NOT NULL,
                equivalent INTEGER NOT NULL,
                reason TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY(run_id) REFERENCES validation_runs(id)
            );
            """
        )
        _migrate(conn)
        _seed(conn)


def _migrate(conn: sqlite3.Connection) -> None:
    _ensure_column(conn, "validation_runs", "warning_type", "TEXT")
    _ensure_column(
        conn,
        "validation_runs",
        "warning_lines_json",
        "TEXT NOT NULL DEFAULT '[]'",
    )
    _ensure_column(
        conn,
        "validation_runs",
        "final_result_correct",
        "INTEGER NOT NULL DEFAULT 0",
    )
    _ensure_column(
        conn,
        "validation_runs",
        "process_valid",
        "INTEGER NOT NULL DEFAULT 0",
    )
    conn.commit()


def _ensure_column(conn: sqlite3.Connection, table: str, column: str, definition: str) -> None:
    cursor = conn.execute(f"PRAGMA table_info({table})")
    columns = [row["name"] for row in cursor.fetchall()]
    if column in columns:
        return
    conn.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")


def _seed(conn: sqlite3.Connection) -> None:
    now = _utc_now()
    rule_rows = [
        (
            "ecuaciones_lineales",
            "principio_equivalencia",
            "Aplicar la misma operacion en ambos lados conserva el conjunto solucion.",
            "Pasar un termino al otro lado cambiando signo equivale a sumar/restar en ambos lados.",
            json.dumps(
                {
                    "formal": ["2x+3=7", "2x+3-3=7-3", "2x=4"],
                    "informal": ["2x+3=7", "2x=7-3", "2x=4"],
                }
            ),
            now,
        ),
        (
            "ecuaciones_lineales",
            "despeje_x",
            "En ax+b=c, se resta b en ambos lados y luego se divide por a (a!=0).",
            "Mover +b al otro lado con signo contrario es equivalente.",
            json.dumps({"example": ["3x-4=11", "3x=15", "x=5"]}),
            now,
        ),
    ]
    error_rows = [
        ("parse_error", "No se pudo interpretar el paso OCR.", "expresion invalida", "No pude leer ese paso."),
        ("sign_error", "Cambio de signo incorrecto.", "termino movido con signo incorrecto", "Revisa el signo al trasladar terminos."),
        (
            "not_applied_both_sides",
            "Operacion aplicada solo a un lado.",
            "cambio unilateral",
            "Aplica la operacion a ambos lados de la igualdad.",
        ),
        ("distribution_error", "Error de distributiva.", "parentesis mal distribuidos", "Revisa la distributiva."),
        ("fraction_error", "Error con fracciones.", "division/parcial", "Revisa simplificacion y division completa."),
        ("arithmetic_error", "Error aritmetico.", "calculo intermedio incorrecto", "Revisa el calculo numerico."),
        ("domain_error", "Restriccion de dominio rota.", "valor no permitido", "Hay un valor fuera del dominio permitido."),
        ("not_equivalent", "Pasos no equivalentes.", "solucion distinta", "Ese paso no conserva la misma solucion."),
        ("undetermined", "No se pudo decidir equivalencia.", "caso simbolico complejo", "No pude confirmar ese paso."),
    ]

    for row in rule_rows:
        conn.execute(
            """
            INSERT OR IGNORE INTO rule_memory
                (topic, rule_key, formal_rule, informal_equivalence, examples_json, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            row,
        )
    for row in error_rows:
        conn.execute(
            """
            INSERT OR IGNORE INTO error_catalog
                (error_type, description, detection_hint, feedback_template, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (*row, now),
        )
    conn.execute(
        """
        INSERT OR IGNORE INTO prompt_versions (name, system_prompt, created_at)
        VALUES (?, ?, ?)
        """,
        (
            "v1-linear-feedback",
            "Eres un tutor de algebra. Explicas errores, no decides si esta correcto.",
            now,
        ),
    )
    conn.commit()


def save_validation_run(
    config: DbConfig,
    *,
    equation_prompt: str,
    expected_final: str,
    ocr_lines: list[str],
    decision: str,
    error_type: str | None,
    warning_type: str | None,
    wrong_lines: list[int],
    warning_lines: list[int],
    final_result_correct: bool,
    process_valid: bool,
    latency_ms: int,
    step_validations: list[dict[str, Any]],
) -> None:
    with get_connection(config) as conn:
        cursor = conn.execute(
            """
            INSERT INTO validation_runs
                (
                    equation_prompt, expected_final, ocr_lines_json, decision, error_type, warning_type,
                    wrong_lines_json, warning_lines_json, final_result_correct, process_valid, latency_ms, created_at
                )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                equation_prompt,
                expected_final,
                json.dumps(ocr_lines),
                decision,
                error_type,
                warning_type,
                json.dumps(wrong_lines),
                json.dumps(warning_lines),
                1 if final_result_correct else 0,
                1 if process_valid else 0,
                latency_ms,
                _utc_now(),
            ),
        )
        run_id = cursor.lastrowid
        for i, item in enumerate(step_validations):
            conn.execute(
                """
                INSERT INTO step_diagnostics
                    (run_id, step_index, from_step, to_step, equivalent, reason, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    run_id,
                    i,
                    item.get("from_step", ""),
                    item.get("to_step", ""),
                    1 if item.get("equivalent") else 0,
                    item.get("reason", ""),
                    _utc_now(),
                ),
            )
        conn.commit()
