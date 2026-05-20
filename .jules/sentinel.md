## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption
**Vulnerability:** Reading arbitrary files entirely into memory (e.g., via `f.read()`) without size checks risks Denial of Service (DoS) through uncontrolled resource consumption.
**Learning:** File contents must be treated as untrusted input. Even internal repository files can be surprisingly large or maliciously crafted.
**Prevention:** Always enforce a file size limit (e.g., 1MB via `path.stat().st_size > 1048576`) before reading files into memory.
