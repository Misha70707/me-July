import sys
from unittest.mock import MagicMock
sys.modules['jinja2'] = MagicMock()
from my_awesome_project.generate_context import analyze_python_code
from pathlib import Path

def test_analyze_python_code(tmp_path):
    # Create a dummy python file
    d = tmp_path / "src"
    d.mkdir()
    p = d / "dummy.py"
    p.write_text("class DummyClass:\n    pass\n\ndef dummy_func():\n    pass")

    # Create an ignored directory with a python file
    venv = tmp_path / "venv"
    venv.mkdir()
    p2 = venv / "ignore_me.py"
    p2.write_text("class IgnoredClass:\n    pass")

    result = analyze_python_code(tmp_path)
    assert "DummyClass (in dummy.py)" in result["classes"]
    assert "dummy_func() (in dummy.py)" in result["functions"]
    assert "IgnoredClass (in ignore_me.py)" not in result["classes"]
