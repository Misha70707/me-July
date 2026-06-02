## 2024-05-24 - [List Comprehension Walrus Optimization]
**Learning:** Using the walrus operator (`:=`) for both filtering and generation in list comprehensions eliminates redundant method calls (like `.strip()`) and significantly improves performance (~23.7% gain).
**Action:** Apply the walrus operator in list comprehensions where a method result is used for both the filtering condition and the returned element, while strictly maintaining the original logic.
