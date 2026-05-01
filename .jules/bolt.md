## 2024-05-24 - [Optimize AST parsing by pruning directory traversal]
**Learning:** `Path.rglob` is inefficient for searching large codebases if large directories (like `venv` or `node_modules`) are present, as it has no mechanism for early pruning.
**Action:** Replace `Path.rglob` with `os.walk` when filtering out large subdirectories, and mutate the `dirs` list in place (`dirs[:] = ...`) to prevent `os.walk` from descending into them, yielding significant speedups.
