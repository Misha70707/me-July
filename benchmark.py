import time
from pathlib import Path
import sys
import os
import ast

# mock jinja2 for test if not installed
from unittest.mock import MagicMock
sys.modules['jinja2'] = MagicMock()

def analyze_python_code_old(root_path):
    code_elements = {"classes": [], "functions": []}
    for py_file in root_path.rglob("*.py"):
        if 'venv' in py_file.parts or '__pycache__' in py_file.parts:
            continue
        try:
            with open(py_file, 'r', encoding='utf-8') as f:
                tree = ast.parse(f.read(), filename=str(py_file))
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    code_elements["classes"].append(f"{node.name} (in {py_file.name})")
                if isinstance(node, ast.FunctionDef):
                    code_elements["functions"].append(f"{node.name}() (in {py_file.name})")
        except Exception as e:
            pass
    return code_elements

class ElementVisitor(ast.NodeVisitor):
    def __init__(self, filename):
        self.filename = filename
        self.classes = []
        self.functions = []

    def visit_ClassDef(self, node):
        self.classes.append(f"{node.name} (in {self.filename})")
        self.generic_visit(node)

    def visit_FunctionDef(self, node):
        self.functions.append(f"{node.name}() (in {self.filename})")
        self.generic_visit(node)

def analyze_python_code_new(root_path):
    code_elements = {"classes": [], "functions": []}
    for py_file in root_path.rglob("*.py"):
        if 'venv' in py_file.parts or '__pycache__' in py_file.parts:
            continue
        try:
            with open(py_file, 'r', encoding='utf-8') as f:
                tree = ast.parse(f.read(), filename=str(py_file))
            visitor = ElementVisitor(py_file.name)
            visitor.visit(tree)
            code_elements["classes"].extend(visitor.classes)
            code_elements["functions"].extend(visitor.functions)
        except Exception as e:
            pass
    return code_elements

# Generate a large syntax tree full of non-class/non-function nodes
with open("my_awesome_project/large_test.py", "w") as f:
    f.write("def my_func():\n")
    for i in range(100000):
        f.write(f"    x_{i} = {i} + {i} * {i}\n")
        f.write(f"    y_{i} = [j for j in range({i % 10})] if x_{i} > 10 else []\n")

print("Running baseline benchmark (ast.walk)...")
start_time = time.time()
for _ in range(5):
    res = analyze_python_code_old(Path('my_awesome_project'))
end_time = time.time()
baseline = end_time - start_time
print(f"OLD Time taken: {baseline:.4f} seconds")

print("Running new benchmark (ast.NodeVisitor)...")
start_time = time.time()
for _ in range(5):
    res = analyze_python_code_new(Path('my_awesome_project'))
end_time = time.time()
optimized = end_time - start_time
print(f"NEW Time taken: {optimized:.4f} seconds")

improvement = (baseline - optimized) / baseline * 100
print(f"Improvement: {improvement:.2f}%")

os.remove("my_awesome_project/large_test.py")
