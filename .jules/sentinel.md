## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Uncontrolled resource consumption due to treating file contents as untrusted input.
**Learning:** File contents must be treated as untrusted input. Reading arbitrarily large files entirely into memory without limits can cause memory exhaustion and denial of service.
**Prevention:** Always enforce a file size limit (e.g., 1MB) before reading files into memory.
