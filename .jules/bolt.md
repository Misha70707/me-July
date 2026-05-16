## 2024-05-16 - Walrus operator in list comprehensions
**Learning:** The walrus operator (`:=`) is highly effective for eliminating redundant function calls within list comprehensions when used for both filtering and generation (e.g., `[stripped for line in f if (stripped := line.strip())]`), often halving execution time for those operations.
**Action:** Use the walrus operator in list comprehensions to avoid redundant calls like `.strip()` when the result is needed for both the condition and the output.
