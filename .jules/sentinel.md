## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Unbounded file reading in `generate_context.py` can cause excessive memory usage or crashes (DoS) when scanning large untrusted files.
**Learning:** File contents must be treated as untrusted input. Reading them without size validation leads to uncontrolled resource consumption.
**Prevention:** Always enforce a file size limit (e.g., `< 1MB`) using `path.stat().st_size` before reading files into memory.
