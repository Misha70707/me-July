import unittest
import tempfile
import shutil
import os
import sys
from pathlib import Path

# Add parent directory to path to import generate_context
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from generate_context import analyze_python_code, scan_project_structure

class TestAnalysis(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.root = Path(self.test_dir)

        # Create src directory with valid python file
        (self.root / "src").mkdir()
        with open(self.root / "src" / "app.py", "w") as f:
            f.write("def main_func(): pass\nclass MainClass: pass")

        # Create node_modules with python file that SHOULD be ignored
        # (simulating a build artifact or weird dependency)
        (self.root / "node_modules").mkdir()
        with open(self.root / "node_modules" / "ignored.py", "w") as f:
            f.write("def ignored_func(): pass")

        # Create .venv with python file that SHOULD be ignored
        (self.root / ".venv").mkdir()
        with open(self.root / ".venv" / "ignored_env.py", "w") as f:
            f.write("def ignored_env_func(): pass")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_analyze_python_code_ignores_directories(self):
        """Test that analyze_python_code ignores node_modules and .venv"""
        elements = analyze_python_code(self.root)

        functions = elements["functions"]
        # classes = elements["classes"] # Unused

        # Should find main_func
        found_main = any("main_func" in f for f in functions)
        self.assertTrue(found_main, "Should find function in src/")

        # Should NOT find ignored_func (in node_modules)
        found_ignored = any("ignored_func" in f for f in functions)
        self.assertFalse(found_ignored, "Should ignore function in node_modules/")

        # Should NOT find ignored_env_func (in .venv)
        found_env_ignored = any("ignored_env_func" in f for f in functions)
        self.assertFalse(found_env_ignored, "Should ignore function in .venv/")

    def test_scan_project_structure_ignores_directories(self):
        """Test that scan_project_structure ignores node_modules and .venv"""
        structure = scan_project_structure(self.root)

        # Helper to flatten keys
        keys = list(structure.keys())

        # Should find src
        self.assertTrue(any("src/" in k for k in keys), "Should find src/")

        # Should NOT find node_modules
        self.assertFalse(any("node_modules/" in k for k in keys), "Should ignore node_modules/")

        # Should NOT find .venv
        self.assertFalse(any(".venv/" in k for k in keys), "Should ignore .venv/")

if __name__ == '__main__':
    unittest.main()
