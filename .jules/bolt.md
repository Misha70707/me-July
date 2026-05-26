## 2026-05-26 - Optimize List Comprehension Redundancy
**Learning:** List comprehensions that use the same method for filtering and output generation execute redundantly, causing unnecessary processing overhead. The walrus operator (`:=`) effectively resolves this without sacrificing readability.
**Action:** Use the walrus operator (`:=`) to assign method call results in conditions when that exact result is also needed for the list's elements.
