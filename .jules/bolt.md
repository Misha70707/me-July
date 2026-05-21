## 2024-05-23 - [Walrus Operator in List Comprehensions]
**Learning:** Using the walrus operator (`:=`) to capture the result of a method call (like `.strip()`) in the condition of a list comprehension prevents redundant calls when that same result is needed for the generated item.
**Action:** Use the walrus operator for filtering and generation in list comprehensions to halve execution time for those operations.
