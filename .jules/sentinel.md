## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Denial of Service (DoS) risk due to unbounded file reads into memory during AST parsing.
**Learning:** Utility scripts must treat file contents as untrusted input. Reading large files into memory without limits can cause Uncontrolled Resource Consumption.
**Prevention:** Enforce a maximum file size limit (e.g., `st_size > 1024 * 1024`) before processing external files.
