## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** DoS risk via Uncontrolled Resource Consumption when reading and parsing arbitrarily large Python files into memory.
**Learning:** Utility scripts that perform expensive operations like AST parsing on files must treat file contents as untrusted input. A massive file can exhaust memory or CPU.
**Prevention:** Always enforce file size limits (e.g., 1MB) before reading files into memory for processing.
