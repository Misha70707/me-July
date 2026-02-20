## 2024-05-22 - [Directory Traversal Optimization]
**Learning:** `pathlib.Path.rglob` cannot efficiently skip deep directory trees because it traverses them before filtering. In contrast, `os.walk` allows modifying the `dirs` list in-place to prune entire subtrees, which is crucial for performance when ignoring large folders like `node_modules`.
**Action:** Always prefer `os.walk` with in-place pruning over `rglob` when traversing directories that may contain large ignored subdirectories.
