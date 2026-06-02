## 2024-06-02 - Hoist string conversions
**Learning:** Calling `str()` on a `pathlib.Path` object inside a hot loop like `os.walk` adds redundant overhead.
**Action:** Always hoist invariant type conversions outside of loops.
