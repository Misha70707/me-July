## 2025-02-12 - [Python Directory Traversal]
**Learning:** `pathlib.Path.rglob` iterates through ALL files in subdirectories before filtering, which is catastrophic for deep trees like `node_modules` or `.venv`.
**Action:** Use `os.walk` and modify `dirs[:]` in-place to prune ignored directories before traversing them. This achieved a ~65x speedup in this codebase.
