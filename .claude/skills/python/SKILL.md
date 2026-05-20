---
name: python
description: "Rules and conventions when writing or modifying Python code. TRIGGER when: editing .py files or pyproject.toml; adding/removing dependencies; setting up lint/format/test config in a Python project. SKIP when: notebook-only changes that don't touch deps; non-Python repos; pure docs. Enforces declarative pyproject.toml (no requirements.txt/setup.py), uv/poetry only (no global pip in local dev), ruff for lint+format unless project configures otherwise, full type hints with the RORO pattern, pytest in tests/ (no unittest)."
---

## When this applies

Applies when editing `.py` files or `pyproject.toml` in a Python project, including dependency, lint/format, and test-config changes. Does not apply to notebook-only edits that don't touch dependencies, non-Python repos, or pure documentation changes.

## Rules

- Manage all project metadata, dependencies, and tool configuration declaratively via `pyproject.toml`. Do not generate, use, or modify `requirements.txt` or `setup.py`.
- In local development, never run global `pip install`; use the project's virtual environment manager (e.g. `uv` or `poetry`) to keep installs isolated from the system Python. In container builds (Dockerfiles, CI images) `pip install` is acceptable since the container itself is the isolation boundary.
- Inspect `pyproject.toml` for the current lint and format setup before writing code. Default to `ruff` for both lint and format; do not introduce `black`, `flake8`, or `isort` unless already configured.
- Include fully qualified type hints on every new function, method, and class. Favor the Receive an Object, Return an Object (RORO) pattern where applicable.
- Write all tests with `pytest` under `tests/`. Do not use the standard library `unittest` module.

## Examples

**DO:**

```bash
uv add httpx
```

**DON'T:**

```bash
pip install httpx
```
