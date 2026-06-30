from pathlib import Path

from src.config import AppConfig, load_config


def test_load_config_returns_defaults_when_file_is_missing(tmp_path: Path) -> None:
    config = load_config(tmp_path / "missing.json")

    assert config == AppConfig()


def test_load_config_maps_json_names(tmp_path: Path) -> None:
    config_path = tmp_path / "config.json"
    config_path.write_text(
        """
        {
          "encoding": "utf-8",
          "overwrite": false,
          "createLogs": false,
          "checkUpdates": false,
          "outputFolder": "out",
          "inputFolder": "in",
          "openAfterConvert": true,
          "showExecutionTime": false
        }
        """,
        encoding="utf-8",
    )

    config = load_config(config_path)

    assert config.encoding == "utf-8"
    assert config.overwrite is False
    assert config.create_logs is False
    assert config.check_updates is False
    assert config.output_folder == "out"
    assert config.input_folder == "in"
    assert config.open_after_convert is True
    assert config.show_execution_time is False

