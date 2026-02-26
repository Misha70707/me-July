## 2026-02-25 - [Directory Traversal Optimization]
**Learning:** `pathlib.Path.rglob("*.py")` is significantly slower than `os.walk` when large ignored directories (like `node_modules` or `venv`) exist in the tree, because `rglob` traverses everything before filtering. In-place pruning with `os.walk` (`dirs[:] = ...`) prevents entering those directories entirely.
**Action:** Use `os.walk` with manual pruning for file scanning tasks in projects that may contain deep dependency trees.
