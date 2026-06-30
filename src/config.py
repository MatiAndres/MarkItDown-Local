"""Configuration helpers for MarkItDown Local."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class AppConfig:
    """Runtime configuration loaded from config.json."""

    encoding: str = "utf-8"
    overwrite: bool = True
    create_logs: bool = True
    check_updates: bool = True
    output_folder: str = "output"
    input_folder: str = "input"
    open_after_convert: bool = False
    show_execution_time: bool = True


def load_config(path: Path) -> AppConfig:
    """Load application configuration from a JSON file."""

    if not path.exists():
        return AppConfig()

    raw: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    return AppConfig(
        encoding=str(raw.get("encoding", "utf-8")),
        overwrite=bool(raw.get("overwrite", True)),
        create_logs=bool(raw.get("createLogs", True)),
        check_updates=bool(raw.get("checkUpdates", True)),
        output_folder=str(raw.get("outputFolder", "output")),
        input_folder=str(raw.get("inputFolder", "input")),
        open_after_convert=bool(raw.get("openAfterConvert", False)),
        show_execution_time=bool(raw.get("showExecutionTime", True)),
    )

