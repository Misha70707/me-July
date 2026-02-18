import os
import sys
import pytest
from pathlib import Path

# Add the project root to sys.path so we can import generate_context
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from generate_context import analyze_python_code

def test_analyze_python_code_ignores_venv(tmp_path):
    # Setup
    src_dir = tmp_path / "src"
    venv_dir = tmp_path / ".venv"
    src_dir.mkdir()
    venv_dir.mkdir()

    # Create a valid file
    (src_dir / "main.py").write_text("class ValidClass: pass\ndef valid_func(): pass", encoding='utf-8')

    # Create an ignored file
    (venv_dir / "ignored.py").write_text("class IgnoredClass: pass\ndef ignored_func(): pass", encoding='utf-8')

    # Run analysis
    result = analyze_python_code(tmp_path)

    # Assertions
    classes = result["classes"]
    functions = result["functions"]

    # Verify we found the valid ones
    assert any("ValidClass" in c for c in classes), f"Classes found: {classes}"
    assert any("valid_func" in f for f in functions), f"Functions found: {functions}"

    # Verify we ignored the ones in .venv
    assert not any("IgnoredClass" in c for c in classes), f"Classes found: {classes}"
    assert not any("ignored_func" in f for f in functions), f"Functions found: {functions}"
