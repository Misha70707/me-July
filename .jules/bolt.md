
## 2024-05-24 - Hoisting and Walrus optimizations
**Learning:** Hoisting invariant type conversions (like `str(root_path)`) outside of hot loops (`os.walk`) and using the walrus operator (`:=`) in list comprehensions can significantly reduce redundant function calls and improve execution performance in Python scripts.
**Action:** Always look for invariant calculations inside loops and duplicate operations in list comprehensions that can be optimized with these techniques.
