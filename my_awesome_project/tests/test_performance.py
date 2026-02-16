import unittest
import tempfile
import shutil
import os
import sys
from pathlib import Path

# Add project root to sys.path to allow imports
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from my_awesome_project.generate_context import analyze_python_code

class TestAnalyzePythonCodePerformance(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.root_path = Path(self.test_dir)

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def create_file(self, path, content):
        p = self.root_path / path
        p.parent.mkdir(parents=True, exist_ok=True)
        with open(p, 'w') as f:
            f.write(content)

    def test_pruning_and_discovery(self):
        # Create a structure:
        # /valid.py
        # /src/app.py
        # /node_modules/ignored.py
        # /.venv/lib/ignored_lib.py

        self.create_file("valid.py", "def valid_func(): pass")
        self.create_file("src/app.py", "class App: pass")

        # Files that should be IGNORED
        self.create_file("node_modules/ignored.py", "def ignored_func(): pass")
        self.create_file(".venv/lib/ignored_lib.py", "class IgnoredClass: pass")
        self.create_file("venv/lib/ignored_lib2.py", "class IgnoredClass2: pass")

        result = analyze_python_code(self.root_path)

        # Check functions
        functions = result["functions"]
        found_valid_func = any("valid_func" in f for f in functions)
        found_ignored_func = any("ignored_func" in f for f in functions)

        self.assertTrue(found_valid_func, f"Should find valid_func. Found: {functions}")
        self.assertFalse(found_ignored_func, f"Should NOT find ignored_func in node_modules. Found: {functions}")

        # Check classes
        classes = result["classes"]
        found_app_class = any("App" in c for c in classes)
        found_ignored_class = any("IgnoredClass" in c for c in classes)
        found_ignored_class2 = any("IgnoredClass2" in c for c in classes)

        self.assertTrue(found_app_class, f"Should find App class. Found: {classes}")
        self.assertFalse(found_ignored_class, f"Should NOT find IgnoredClass in .venv. Found: {classes}")
        self.assertFalse(found_ignored_class2, f"Should NOT find IgnoredClass2 in venv. Found: {classes}")

if __name__ == '__main__':
    unittest.main()
