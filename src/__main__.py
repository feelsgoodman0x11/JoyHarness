"""Allow running JoyHarness as `python -m src`."""
from __future__ import annotations

import os
import sys
from pathlib import Path

_RELAUNCH_ENV = "JOYHARNESS_VENV_RELAUNCH"
_MISSING_TK_MODULES = {"tkinter", "_tkinter"}


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _venv_python_candidates() -> tuple[Path, ...]:
    root = _repo_root() / ".venv"
    if os.name == "nt":
        return (root / "Scripts" / "python.exe", root / "Scripts" / "python")
    return (root / "bin" / "python", root / "bin" / "python3")


def _maybe_relaunch_with_repo_venv() -> None:
    if os.environ.get(_RELAUNCH_ENV) == "1":
        return

    current_python = Path(sys.executable).resolve()
    for candidate in _venv_python_candidates():
        if not candidate.exists():
            continue

        if candidate.resolve() == current_python:
            return

        env = os.environ.copy()
        env[_RELAUNCH_ENV] = "1"
        os.execve(
            str(candidate),
            [str(candidate), "-m", "src", *sys.argv[1:]],
            env,
        )


try:
    import tkinter  # noqa: F401
except ModuleNotFoundError as exc:
    if exc.name in _MISSING_TK_MODULES:
        _maybe_relaunch_with_repo_venv()
    raise

from .main import main

main()
