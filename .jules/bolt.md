## 2024-05-22 - [Performance: Directory Traversal]
**Learning:** `pathlib.Path.rglob` performs a full directory traversal, entering all subdirectories (including hidden ones or node_modules) before filtering. In deep project structures, this is significantly slower than `os.walk`.
**Action:** Use `os.walk` with in-place list modification (`dirs[:] = [d for d in dirs if d not in ignore]`) to prune traversal branches early. Benchmark showed ~100x speedup on structures with large ignored directories.
