"""Version helpers for the installed MarkItDown package."""

from __future__ import annotations

from importlib.metadata import PackageNotFoundError, version


def installed_markitdown_version() -> str:
    """Return the installed MarkItDown version, or a fallback label."""

    try:
        return version("markitdown")
    except PackageNotFoundError:
        return "unknown"

