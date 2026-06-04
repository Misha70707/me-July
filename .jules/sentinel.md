## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Uncontrolled resource consumption (DoS) when reading untrusted file contents into memory without size constraints.
**Learning:** Naively using `f.read()` or similar methods on arbitrarily large files can cause memory exhaustion and crash the application.
**Prevention:** Always enforce file size limits (e.g., `path.stat().st_size > 1048576` for 1MB) before reading contents into memory.
