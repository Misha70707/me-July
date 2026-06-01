## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2024-05-23 - Uncontrolled Resource Consumption (DoS)
**Vulnerability:** The script reads file contents entirely into memory (e.g., `f.read()`) without checking file sizes, risking a Denial of Service (DoS) due to memory exhaustion on unusually large files.
**Learning:** File contents must always be treated as untrusted input. Even local utility scripts can be vulnerable to uncontrolled resource consumption if they process arbitrarily large files in a single operation.
**Prevention:** Always enforce a reasonable file size limit (e.g., `path.stat().st_size > 1048576` for 1MB) before reading files into memory, skipping or aborting gracefully if the limit is exceeded.
