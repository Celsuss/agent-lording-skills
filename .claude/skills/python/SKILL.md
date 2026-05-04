---
name: python
description: Rules and conventions when writing or modifying Python code. Use when editing .py files or pyproject.toml. Enforces declarative pyproject.toml management (no requirements.txt or setup.py), uv/poetry only (no global pip), ruff for lint+format unless project configures otherwise, full type hints with RORO pattern, and pytest in tests/ (no unittest).
---

## Python Development Rules

- **Declarative Management:** All project metadata, dependencies, and tool configurations must be managed strictly and declaratively via `pyproject.toml`. Do not generate, use, or modify `requirements.txt` or `setup.py`.
- **Environment Isolation:** Never suggest or run global `pip install` commands. Always use the project's virtual environment manager (e.g., `uv` or `poetry`) to ensure absolute isolation from the system Python.
- **Code Quality:** Before writing code, inspect the `pyproject.toml` file to understand the current linting and formatting rules. Default to `ruff` for both linting and formatting; do not introduce `black`, `flake8`, or `isort` unless they are already explicitly configured.
- **Type Safety:** All new functions, methods, and classes must include fully qualified type hints. Favor the Receive an Object, Return an Object (RORO) pattern where applicable.
- **Testing:** Write all tests exclusively using `pytest` inside the `tests/` directory. Do not use the standard library `unittest` module.
