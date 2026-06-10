## 2026-06-10 - Hoisting Invariants in Hot Loops
**Learning:** In Python, type conversions like `str(path)` inside hot loops such as `os.walk` can add unnecessary overhead. Hoisting invariant variables outside the loop improves execution speed.
**Action:** Always identify variables that do not change during iterations in hot paths, and hoist them outside of the loop.
