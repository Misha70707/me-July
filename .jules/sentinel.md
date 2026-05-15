## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Uncontrolled resource consumption (DoS risk) when reading arbitrary files into memory using f.read().
**Learning:** File contents must be treated as untrusted input. Reading very large files into memory at once can exhaust system resources.
**Prevention:** Enforce a maximum file size limit (e.g., 1MB via path.stat().st_size > 1048576) before reading files into memory.
