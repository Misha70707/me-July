## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Denial of Service (DoS) risk due to reading arbitrarily large Python files into memory for AST parsing.
**Learning:** Utility scripts often assume local files are safe, but large auto-generated or malicious files can cause memory exhaustion when read entirely.
**Prevention:** Always enforce strict file size limits (e.g., 1MB) before reading file contents, treating even local files as potentially untrusted input.
