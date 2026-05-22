## 2024-05-24 - Walrus Operator in List Comprehensions
**Learning:** The walrus operator (`:=`) is highly effective for eliminating redundant function calls within list comprehensions when used for both filtering and generation (e.g., `[stripped for line in f if (stripped := line.strip())]`), often halving execution time for those operations.
**Action:** Use the walrus operator in list comprehensions where the result of a function call is needed for both filtering and the final output to improve performance.
