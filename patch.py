import ast

with open('my_awesome_project/generate_context.py', 'r') as f:
    content = f.read()

visitor_code = """
class _ElementVisitor(ast.NodeVisitor):
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

def analyze_python_code(root_path):"""

old_code = """def analyze_python_code(root_path):
    \"\"\"Uses AST to find classes and functions in Python files.\"\"\"
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
            print(f"Could not parse {py_file}: {e}")
    return code_elements"""

new_code = """def analyze_python_code(root_path):
    \"\"\"Uses AST to find classes and functions in Python files.\"\"\"
    code_elements = {"classes": [], "functions": []}
    for py_file in root_path.rglob("*.py"):
        if 'venv' in py_file.parts or '__pycache__' in py_file.parts:
            continue
        try:
            with open(py_file, 'r', encoding='utf-8') as f:
                tree = ast.parse(f.read(), filename=str(py_file))
            visitor = _ElementVisitor(py_file.name)
            visitor.visit(tree)
            code_elements["classes"].extend(visitor.classes)
            code_elements["functions"].extend(visitor.functions)
        except Exception as e:
            print(f"Could not parse {py_file}: {e}")
    return code_elements"""

if old_code in content:
    content = content.replace(old_code, visitor_code + new_code[len("def analyze_python_code(root_path):"):])
    with open('my_awesome_project/generate_context.py', 'w') as f:
        f.write(content)
    print("Patch successful!")
else:
    print("Could not find old code in file.")
