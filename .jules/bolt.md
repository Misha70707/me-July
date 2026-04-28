## 2026-04-28 - Optimize Directory Traversal
**Learning:** Path.rglob('*.py') traverses all subdirectories including ignored ones (like venv) before filtering them out, leading to massive overhead in large projects. Using os.walk with in-place directory pruning (dirs[:] = ...) prevents traversal of unwanted directories, yielding significant performance gains.
**Action:** Use os.walk with in-place pruning instead of rglob for targeted directory traversal when many ignored directories exist.
