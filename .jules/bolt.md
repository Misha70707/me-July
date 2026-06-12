## 2026-06-12 - Hoisting Invariant Type Conversions
**Learning:** Hoisting invariant type conversions (e.g., `str(root_path)`) outside of hot loops (like `os.walk`) reduces redundant overhead and improves execution performance.
**Action:** Always hoist invariant string casting or path conversions outside of recursive/iterative functions like `os.walk` to prevent unnecessary performance penalties.
