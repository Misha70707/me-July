## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Denial of Service (DoS) risk when parsing arbitrarily large Python files with AST without size limits.
**Learning:** Utility scripts reading files into memory must treat file contents as untrusted input, as unexpectedly large files can consume excessive memory and crash the process.
**Prevention:** Always enforce a file size limit (e.g., `st_size > 1024 * 1024`) before reading files into memory for processing.
