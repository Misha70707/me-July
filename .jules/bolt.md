## 2024-05-28 - [List Comprehension Redundancy]
**Learning:** Redundant string operations (like `line.strip()`) in list comprehension conditionals and outputs cause significant performance overhead.
**Action:** Use the walrus operator (`:=`) in list comprehensions to assign and evaluate simultaneously (e.g., `[stripped for line in f if (stripped := line.strip())]`).
