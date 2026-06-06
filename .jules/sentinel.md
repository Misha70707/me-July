## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2026-06-06 - Memory Exhaustion DoS Prevention
**Vulnerability:** The script reads entire Python files into memory using `f.read()` without validating their size, exposing it to Uncontrolled Resource Consumption (DoS) when analyzing extremely large or malicious `.py` files.
**Learning:** `ast.parse` requires the full file content in memory, making it dangerous on arbitrarily large inputs. Conditionally assigning variables like `tree` based on size checks can cause `UnboundLocalError` if the variable isn't explicitly initialized first before the size check.
**Prevention:** Always enforce a maximum file size limit (e.g., `st_size <= 1MB`) before calling `.read()` on external files. Initialize state variables (like `tree = None`) prior to condition blocks to avoid undefined reference errors.
