## 2024-05-17 - [List Comprehension Redundancy]
**Learning:** Using the walrus operator (`:=`) in list comprehensions when the same method result (like `.strip()`) is needed for both filtering and generation is highly effective for eliminating redundant function calls.
**Action:** Always prefer the walrus operator in list comprehensions where a transformed item is both evaluated in the condition and yielded, to halve execution time for those operations.
