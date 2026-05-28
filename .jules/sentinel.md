## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Uncontrolled Resource Consumption (DoS) risk from reading arbitrary files without size limits.
**Learning:** Reading file contents into memory using `f.read()` without prior size validation can lead to application crashes and memory exhaustion if a user places abnormally large files in the project directory. The need to treat file contents as untrusted input is emphasized.
**Prevention:** Always verify file sizes against a reasonable threshold (e.g., 1MB via `path.stat().st_size > 1048576`) before reading them into memory.
