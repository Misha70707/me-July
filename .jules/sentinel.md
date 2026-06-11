## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2026-06-11 - Uncontrolled Resource Consumption (DoS)
**Vulnerability:** Unbounded file reading (`f.read()`) in `analyze_python_code` leading to potential memory exhaustion.
**Learning:** Reading entire file contents into memory without prior size validation exposes the application to resource exhaustion if it encounters unexpectedly large files.
**Prevention:** Always validate file sizes using `Path.stat().st_size` before calling `f.read()` on untrusted or unknown files.
