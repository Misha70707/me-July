## 2024-05-24 - [List Comprehension Redundancy]
**Learning:** Using `line.strip()` for both filtering and output generation inside a list comprehension causes redundant method calls, resulting in a measurable performance penalty. The walrus operator (`:=`) is highly effective at eliminating these redundant function calls, often halving execution time for these operations.
**Action:** Use the walrus operator (`:=`) in list comprehensions when a method's return value is needed for both the condition and the resulting element.
