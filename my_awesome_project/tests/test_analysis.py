
import sys
import os
import shutil
from pathlib import Path
import pytest

# Add parent directory to path to import generate_context
sys.path.insert(0, str(Path(__file__).parent.parent))

from generate_context import analyze_python_code

@pytest.fixture
def temp_project_structure():
    """Creates a temporary project structure for testing."""
    base_path = Path("./temp_test_project")
    if base_path.exists():
        shutil.rmtree(base_path)
    base_path.mkdir()

    # Create ignored directories
    (base_path / "node_modules").mkdir()
    (base_path / "node_modules" / "ignored.py").touch()
    with open(base_path / "node_modules" / "ignored.py", "w") as f:
         f.write("def ignored_function(): pass\n")

    (base_path / ".venv").mkdir()
    (base_path / ".venv" / "ignored_env.py").touch()
    with open(base_path / ".venv" / "ignored_env.py", "w") as f:
         f.write("class IgnoredClass: pass\n")

    # Create valid directories and files
    (base_path / "src").mkdir()

    with open(base_path / "src" / "main.py", "w") as f:
        f.write("""
class MainClass:
    def method(self):
        pass

def main_function():
    pass
""")

    with open(base_path / "root_script.py", "w") as f:
        f.write("def root_function(): pass\n")

    yield base_path

    # Cleanup
    if base_path.exists():
        shutil.rmtree(base_path)

def test_analyze_python_code_structure(temp_project_structure):
    """Test that analyze_python_code finds expected elements and ignores others."""
    results = analyze_python_code(temp_project_structure)

    classes = results["classes"]
    functions = results["functions"]

    # Verify classes
    assert any("MainClass" in c for c in classes), "MainClass should be found"
    assert not any("IgnoredClass" in c for c in classes), "IgnoredClass should NOT be found"

    # Verify functions
    assert any("main_function" in f for f in functions), "main_function should be found"
    assert any("root_function" in f for f in functions), "root_function should be found"
    assert not any("ignored_function" in f for f in functions), "ignored_function should NOT be found"

    # Check total counts to ensure no duplicates or extra files
    # MainClass
    # main_function
    # root_function
    # (method inside class is not captured by current AST logic in generate_context.py,
    # checking the implementation: it walks all nodes, so FunctionDef inside ClassDef *will* be visited)

    # Wait, let's check generate_context.py AST walk logic:
    # for node in ast.walk(tree):
    #    if isinstance(node, ast.ClassDef): ...
    #    if isinstance(node, ast.FunctionDef): ...

    # Yes, ast.walk recursively visits all nodes. So 'method' inside 'MainClass' will be found.

    assert any("method" in f for f in functions), "Class method should be found"
