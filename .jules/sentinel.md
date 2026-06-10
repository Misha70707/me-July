## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2026-06-10 - Uncontrolled Resource Consumption in File Read
**Vulnerability:** Reading entire files into memory without size validation (DoS risk).
**Learning:** Operations like `f.read()` can exhaust memory if the target file is unexpectedly large.
**Prevention:** Always check `py_file.stat().st_size` against a reasonable threshold (e.g., 1MB) before reading contents into memory.
