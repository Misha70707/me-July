## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Uncontrolled resource consumption (DoS) when parsing arbitrarily large files.
**Learning:** `f.read()` and similar file operations load the entire file into memory. Without file size limits, analyzing a massive file (e.g., generated code or data dumps) can exhaust system memory.
**Prevention:** Enforce a maximum file size limit (e.g., 1MB via `path.stat().st_size > 1048576`) before reading untrusted or unknown files into memory.
