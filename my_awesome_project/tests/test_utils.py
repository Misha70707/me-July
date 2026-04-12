import sys
from unittest.mock import MagicMock
sys.modules['jinja2'] = MagicMock()

import os
from pathlib import Path
from my_awesome_project.generate_context import analyze_python_code

def test_analyze_python_code_size_limit(tmp_path, capsys):
    large_file = tmp_path / "large.py"
    large_file.write_text("a" * (1024 * 1024 + 1))

    small_file = tmp_path / "small.py"
    small_file.write_text("def test(): pass")

    result = analyze_python_code(tmp_path)

    captured = capsys.readouterr()
    assert "⚠️ Skipping large.py: file size exceeds 1MB limit." in captured.out
    assert "test() (in small.py)" in result["functions"]
