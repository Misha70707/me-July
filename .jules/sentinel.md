## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Reading files entirely into memory (`f.read()`) without checking file size could lead to DoS if a huge file is encountered.
**Learning:** `Path.rglob` or checking `exists()` does not limit file size. Reading large untrusted files (like user-uploaded code or large logs) can consume all available memory.
**Prevention:** Always verify `path.stat().st_size` against a reasonable limit (e.g., 1MB) before reading contents into memory.
