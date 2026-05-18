## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Unbounded file reads in `generate_context.py` could lead to Uncontrolled Resource Consumption (DoS) via excessively large files.
**Learning:** File contents must be treated as untrusted input. Reading arbitrarily large files into memory or AST parsers exposes the system to DoS attacks.
**Prevention:** Enforce a strict 1MB file size limit (`path.stat().st_size > 1048576`) before reading files into memory to mitigate unbounded memory allocation.
