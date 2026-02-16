## 2024-05-22 - [Optimizing Directory Traversal]
**Learning:** `pathlib.Path.rglob` recursively traverses all subdirectories, even those you intend to ignore. For large projects with deep `node_modules` or `.venv` directories, this is a significant performance bottleneck.
**Action:** Use `os.walk` with in-place modification of `dirs[:]` to prune ignored directories *before* entering them. This prevents unnecessary filesystem traversal and speeds up scans significantly (e.g., 150x in some cases).
