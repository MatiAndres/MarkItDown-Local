"""Convert supported files to Markdown using Microsoft MarkItDown."""

from __future__ import annotations

import argparse
import logging
import time
from datetime import datetime
from pathlib import Path

try:
    from .config import load_config
    from .utils import ensure_parent_dir, project_root
    from .version import installed_markitdown_version
except ImportError:
    from config import load_config
    from utils import ensure_parent_dir, project_root
    from version import installed_markitdown_version


def build_parser() -> argparse.ArgumentParser:
    """Create the command-line parser."""

    parser = argparse.ArgumentParser(
        description="Convierte un archivo a Markdown usando Microsoft MarkItDown."
    )
    parser.add_argument("--source", required=True, help="Ruta del archivo origen.")
    parser.add_argument("--output", required=True, help="Ruta del archivo Markdown destino.")
    parser.add_argument(
        "--config",
        default=str(project_root() / "config" / "config.json"),
        help="Ruta del archivo config.json.",
    )
    return parser


def configure_logging(enabled: bool) -> None:
    """Configure conversion logging."""

    if not enabled:
        logging.disable(logging.CRITICAL)
        return

    log_path = project_root() / "logs" / "conversion.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        filename=log_path,
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s",
        encoding="utf-8",
    )


def markdown_from_result(result: object) -> str:
    """Extract Markdown text from a MarkItDown conversion result."""

    text_content = getattr(result, "text_content", None)
    if isinstance(text_content, str):
        return text_content

    markdown = getattr(result, "markdown", None)
    if isinstance(markdown, str):
        return markdown

    if isinstance(result, str):
        return result

    raise ValueError("MarkItDown no devolvio contenido Markdown reconocible.")


def convert_file(source: Path, output: Path, encoding: str) -> dict[str, object]:
    """Convert a source file to Markdown and write it using the requested encoding."""

    from markitdown import MarkItDown

    if not source.exists():
        raise FileNotFoundError(f"No existe el archivo origen: {source}")
    if not source.is_file():
        raise ValueError(f"La ruta origen no es un archivo: {source}")

    started = time.perf_counter()
    result = MarkItDown().convert(str(source))
    markdown = markdown_from_result(result)

    ensure_parent_dir(output)
    output.write_text(markdown, encoding=encoding, newline="\n")

    duration = time.perf_counter() - started
    return {
        "source": str(source),
        "output": str(output),
        "duration": duration,
        "version": installed_markitdown_version(),
        "characters": len(markdown),
    }


def main() -> int:
    """Run a single conversion."""

    parser = build_parser()
    args = parser.parse_args()

    source = Path(args.source).expanduser().resolve()
    output = Path(args.output).expanduser().resolve()
    config = load_config(Path(args.config).expanduser().resolve())
    configure_logging(config.create_logs)

    try:
        stats = convert_file(source, output, config.encoding)
    except Exception as exc:
        logging.exception("Conversion fallida | source=%s | output=%s", source, output)
        print(f"ERROR: {exc}")
        return 1

    logging.info(
        "Conversion OK | source=%s | output=%s | duration=%.3fs | version=%s | characters=%s",
        stats["source"],
        stats["output"],
        stats["duration"],
        stats["version"],
        stats["characters"],
    )

    print("Conversion realizada")
    print(f"Fecha: {datetime.now().isoformat(timespec='seconds')}")
    print(f"Origen: {stats['source']}")
    print(f"Destino: {stats['output']}")
    print(f"Duracion: {stats['duration']:.2f}s")
    print(f"MarkItDown: {stats['version']}")
    print(f"Caracteres: {stats['characters']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
