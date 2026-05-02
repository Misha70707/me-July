## 2024-05-24 - File Traversal Pruning
**Learning:** `Path.rglob()` is slow in Python when directories like `.venv` or `node_modules` are large because it yields everything before we can filter it.
**Action:** Replaced `Path.rglob()` with `os.walk()` to modify the `dirs` list in-place (`dirs[:] = ...`) to prune deep ignored directories early, yielding a massive performance gain.
