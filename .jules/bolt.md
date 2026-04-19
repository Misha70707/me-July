## 2024-05-23 - [os.walk vs pathlib rglob]
**Learning:** Using `Path.rglob()` for file finding in large project directories is an anti-pattern because it does not support early directory pruning. Traversing into large directories like `node_modules` or `.venv` wastes significant IO and CPU.
**Action:** Use `os.walk` with in-place directory list mutation (`dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]`) to prune traversal early.
