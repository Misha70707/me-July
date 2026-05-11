## 2024-05-24 - List Comprehension Optimization with Walrus Operator
**Learning:** Python's walrus operator (`:=`) is highly effective for eliminating redundant function calls within list comprehensions, particularly in patterns like `[f(x) for x in list if f(x)]`.
**Action:** Next time I encounter repeated method calls on iterations (e.g. `line.strip()`) used both for filtering and generation, I will refactor it using the walrus operator to halve the execution time.
