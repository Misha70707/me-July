## 2024-05-24 - Optimizing directory traversal
**Learning:** `Path.rglob` traverses the entire directory tree before filtering. For deep or large directories, it's significantly faster to use `os.walk` with in-place list mutation (`dirs[:] = ...`) to skip unnecessary directories entirely.
**Action:** When scanning directories where large branches can be ignored (like `node_modules` or `venv`), prefer `os.walk` with `dirs[:]` filtering over `Path.rglob`.
