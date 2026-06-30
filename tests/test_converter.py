from types import SimpleNamespace

import pytest

from src.convertir_markitdown import markdown_from_result


def test_markdown_from_text_content() -> None:
    result = SimpleNamespace(text_content="# Title")

    assert markdown_from_result(result) == "# Title"


def test_markdown_from_markdown_attribute() -> None:
    result = SimpleNamespace(markdown="## Subtitle")

    assert markdown_from_result(result) == "## Subtitle"


def test_markdown_from_string() -> None:
    assert markdown_from_result("plain") == "plain"


def test_markdown_from_unknown_result_raises() -> None:
    with pytest.raises(ValueError):
        markdown_from_result(object())

