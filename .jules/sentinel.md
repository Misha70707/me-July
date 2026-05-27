## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Uncontrolled Resource Consumption (DoS) when reading files into memory without size limits.
**Learning:** Reading user-controlled or dynamically discovered files entirely into memory (e.g., using `f.read()`) without checking their size can lead to Denial of Service by exhausting memory.
**Prevention:** Always check `path.stat().st_size` against a reasonable limit (e.g., 1MB) before reading files into memory.
