# generate_context.py
import os
import ast
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

# --- 1. ANALYSIS FUNCTIONS ---

def find_project_root():
    """Finds the root of the project by looking for .git or a common file."""
    current_dir = Path.cwd()
    while current_dir != current_dir.parent:
        if (current_dir / '.git').is_dir() or (current_dir / 'package.json').is_file() or (current_dir / 'requirements.txt').is_file():
            return current_dir
        current_dir = current_dir.parent
    return Path.cwd() # Fallback to current directory

def scan_project_structure(root_path):
    """Scans the directory and returns a structured representation."""
    structure = {}
    ignore_dirs = {'.git', '__pycache__', 'node_modules', '.venv', 'venv', '.vscode'}
    for root, dirs, files in os.walk(root_path):
        dirs[:] = [d for d in dirs if d not in ignore_dirs]
        level = root.replace(str(root_path), '').count(os.sep)
        indent = ' ' * 2 * level
        structure[f"{indent}{os.path.basename(root)}/"] = [f for f in files if not f.startswith('.')]
    return structure

def parse_dependencies(root_path):
    """Parses common dependency files to find the tech stack."""
    dependencies = []
    tech_stack = []

    req_file = root_path / 'requirements.txt'
    if req_file.exists():
        tech_stack.append("Python")
        with open(req_file, 'r') as f:
            dependencies = [line.strip() for line in f if line.strip() and not line.startswith('#')]

    pkg_file = root_path / 'package.json'
    if pkg_file.exists():
        tech_stack.append("Node.js / JavaScript")
        # You could add a JSON parser here to get more details

    return tech_stack, dependencies

def analyze_python_code(root_path):
    """Uses AST to find classes and functions in Python files."""
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
    return code_elements

# --- 2. MAIN EXECUTION ---

def main():
    """Main function to generate the context files."""
    project_root = find_project_root()
    project_name = project_root.name

    # ANSI colors
    BOLD = '\033[1m'
    GREEN = '\033[92m'
    BLUE = '\033[94m'
    RESET = '\033[0m'

    print(f"\n{BOLD}🔍 Scanning project context from:{RESET} {project_root}")

    # --- Gather Context ---
    print(f"   {BLUE}📂 Analyzing directory structure...{RESET}")
    structure = scan_project_structure(project_root)

    print(f"   {BLUE}📦 Parsing dependencies...{RESET}")
    tech_stack, dependencies = parse_dependencies(project_root)

    print(f"   {BLUE}🧠 Analyzing Python code...{RESET}")
    code_elements = analyze_python_code(project_root)

    # --- Template Rendering ---
    # Use the directory where the script is located to find templates
    script_dir = Path(__file__).resolve().parent
    env = Environment(loader=FileSystemLoader(script_dir))

    # Define some default rules and workflow
    mandatory_rules = [
        "All code must be commented.",
        "New features require corresponding tests.",
        "Use conventional commit messages.",
    ]
    workflow = [
        "Create a new branch for your feature or fix.",
        "Write your code and tests.",
        "Run `pytest` to ensure all tests pass.",
        "Format your code using an autoformatter like Black.",
        "Submit a pull request for review.",
    ]

    # --- Generate Agents.md ---
    agent_template = env.get_template('agents_template.md')
    agent_context = {
        "project_name": project_name,
        "tech_stack": tech_stack,
        "mandatory_rules": mandatory_rules,
        "workflow": workflow,
        "structure": structure,
        "code_elements": code_elements,
        "dependencies": dependencies,
    }
    # Use safer filenames to prevent overwriting existing documentation
    output_agents = project_root / "Agents_generated.md"
    with open(output_agents, "w") as f:
        f.write(agent_template.render(agent_context))

    # --- Generate Readme.md ---
    readme_template = env.get_template('readme_template.md')
    readme_context = {
        "project_name": project_name,
        "tech_stack": tech_stack,
        "structure": structure
    }
    output_readme = project_root / "Readme_generated.md"
    with open(output_readme, "w") as f:
        f.write(readme_template.render(readme_context))

    print(f"\n{GREEN}✨ Documentation generated successfully!{RESET}")
    print(f"   - {BOLD}{output_readme.name}{RESET}")
    print(f"   - {BOLD}{output_agents.name}{RESET}")

    # Summary
    class_count = len(code_elements.get("classes", []))
    func_count = len(code_elements.get("functions", []))
    dep_count = len(dependencies)
    print(f"\n{BOLD}📊 Project Summary:{RESET}")
    print(f"   - Found {class_count} classes and {func_count} functions")
    print(f"   - Identified {dep_count} dependencies")
    print(f"   - Tech Stack: {', '.join(tech_stack) if tech_stack else 'Unknown'}")

if __name__ == "__main__":
    main()
