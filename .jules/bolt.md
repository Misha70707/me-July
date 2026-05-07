## 2024-05-24 - Avoid Path.rglob() for filtered directory traversal
**Learning:** `Path.rglob()` traverses the entire directory tree before any Python-level filtering can be applied. In repositories with large ignored directories (like `venv` or `node_modules`), this creates a massive performance bottleneck.
**Action:** Use `os.walk()` with in-place directory list mutation (`dirs[:] = [d for d in dirs if d not in ignore_dirs]`) to prune the traversal tree early.
