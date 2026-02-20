# Backend (FastAPI + SymPy)

## Setup

```bash
python -m venv .venv
. .venv/Scripts/activate
pip install -r requirements.txt
```

## Run

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Test

```bash
python -m unittest discover -s tests -p "test_*.py"
```

## Env vars

- `GROQ_API_KEY` (optional, for pedagogical feedback)
- `MATHFIGHT_DB_PATH` (optional, defaults to `backend/mathfight.db`)

