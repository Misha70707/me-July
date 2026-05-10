## 2024-05-25 - Redundant Method Calls in List Comprehensions
**Learning:** Found a performance anti-pattern in `generate_context.py` where `line.strip()` was called twice per line during dependency parsing.
**Action:** Utilize the walrus operator (`:=`) to cache and reuse evaluated expressions within list comprehensions.
