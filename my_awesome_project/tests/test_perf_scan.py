import os
import sys
import time
import shutil
import tempfile
import pytest
from pathlib import Path

# Add project root to path so we can import generate_context
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from generate_context import analyze_python_code

@pytest.fixture
def temp_project_structure():
    """Creates a temporary project structure with ignored directories."""
    with tempfile.TemporaryDirectory() as tmpdirname:
        root = Path(tmpdirname)

        # 1. Create a valid Python file
        valid_py = root / "src" / "valid.py"
        valid_py.parent.mkdir(parents=True, exist_ok=True)
        with open(valid_py, "w") as f:
            f.write("class MyClass:\n    pass\n\ndef my_func():\n    pass\n")

        # 2. Create a large ignored directory (node_modules)
        node_modules = root / "node_modules"
        node_modules.mkdir()

        # Create many dummy files to slow down rglob
        # rglob will iterate over these, but filter them out later
        # os.walk with pruning will skip the directory entirely
        for i in range(1000):
            (node_modules / f"ignored_{i}.py").touch()

        # 3. Create another ignored directory (.venv)
        venv = root / ".venv"
        venv.mkdir()
        for i in range(100):
            (venv / f"lib_{i}.py").touch()

        yield root

def test_analyze_python_code_performance(temp_project_structure):
    """Measures performance of analyze_python_code and verifies correctness."""
    root = temp_project_structure

    start_time = time.time()
    result = analyze_python_code(root)
    end_time = time.time()

    duration = end_time - start_time
    print(f"\nExecution time: {duration:.4f} seconds")

    # Verification
    # 1. Should find the class and function in valid.py
    classes = result["classes"]
    functions = result["functions"]

    assert any("MyClass" in c for c in classes), "Failed to find MyClass in valid.py"
    assert any("my_func" in f for f in functions), "Failed to find my_func in valid.py"

    # 2. Should NOT find anything from node_modules or .venv
    # (The current implementation filters them out, so correctness should hold)
    # (The optimization ensures we don't even look at them)
    assert not any("ignored_" in str(c) for c in classes)
    assert not any("lib_" in str(c) for c in classes)

    return duration
