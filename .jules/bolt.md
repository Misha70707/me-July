## 2024-06-04 - Optimize list comprehension with walrus operator
**Learning:** The walrus operator (`:=`) is highly effective for eliminating redundant function calls within list comprehensions when used for both filtering and generation (e.g., `[stripped for line in f if (stripped := line.strip())]`), often halving execution time for those operations.
**Action:** Always consider the walrus operator in list comprehensions when a method is called in both the filter condition and the value expression to improve performance.
