## 2024-06-09 - Hoisting invariant type conversions out of loops
**Learning:** Hoisting invariant type conversions (e.g., `str(root_path)`) outside of hot loops (like `os.walk`) reduces redundant overhead and improves execution performance.
**Action:** When working with loops, identify operations whose results do not change per iteration and move them outside the loop.
