import os
import shutil
import tempfile
from pathlib import Path
import pytest
from generate_context import analyze_python_code

@pytest.fixture
def temp_project_structure():
    """Creates a temporary directory structure for testing."""
    temp_dir = tempfile.mkdtemp()
    root = Path(temp_dir)

    # Create valid src
    (root / "src").mkdir()
    with open(root / "src" / "valid.py", "w") as f:
        f.write("def valid_function(): pass\n")

    # Create ignored directory with python file inside
    (root / "node_modules").mkdir()
    (root / "node_modules" / "deep").mkdir()
    with open(root / "node_modules" / "deep" / "ignored.py", "w") as f:
        f.write("def ignored_function(): pass\n")

    yield root
    shutil.rmtree(temp_dir)

def test_analyze_python_code_skips_ignored(temp_project_structure):
    """Verifies that analyze_python_code skips ignored directories."""
    code_elements = analyze_python_code(temp_project_structure)

    # Should find valid_function
    found_functions = code_elements["functions"]
    assert any("valid_function" in func for func in found_functions), "Should find valid_function"

    # Should NOT find ignored_function
    assert not any("ignored_function" in func for func in found_functions), "Should skip ignored directories like node_modules"
