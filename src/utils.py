"""Shared utility helpers."""

from __future__ import annotations

from pathlib import Path


def project_root() -> Path:
    """Return the project root directory."""

    return Path(__file__).resolve().parents[1]


def ensure_parent_dir(path: Path) -> None:
    """Create the parent directory for a file path if needed."""

    path.parent.mkdir(parents=True, exist_ok=True)

