## 2024-06-02 - Optimize directory traversal in analyze_python_code
**Learning:** Using `Path.rglob` followed by filtering based on `parts` is highly inefficient because it still visits all directories and files under the root. Replacing it with `os.walk` and modifying `dirs` in place prevents traversing into ignored directories, yielding massive performance gains.
**Action:** Use `os.walk` with in-place list modification `dirs[:] = [d for d in dirs if d not in ignore_dirs]` when ignoring large nested directory trees like `venv` or `node_modules`.
