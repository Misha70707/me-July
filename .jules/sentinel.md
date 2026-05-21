## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Reading files without size limits in `generate_context.py` can lead to Uncontrolled Resource Consumption.
**Learning:** File contents must be treated as untrusted input. Parsing extremely large files without limits can exhaust system memory.
**Prevention:** Enforce a 1MB file size limit (`path.stat().st_size > 1048576`) before reading files into memory.
