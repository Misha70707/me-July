## 2024-05-22 - Jinja2 Autoescape Default
**Vulnerability:** Stored XSS in generated documentation due to disabled autoescaping in Jinja2.
**Learning:** Jinja2's `Environment` defaults to `autoescape=False`. This is dangerous when rendering content from external files (like `requirements.txt`) into HTML/Markdown.
**Prevention:** Always explicitly set `autoescape=True` when initializing `jinja2.Environment`, especially when dealing with untrusted or external input.

## 2026-02-24 - Uncontrolled Resource Consumption (DoS)
**Vulnerability:** `generate_context.py` read files fully into memory without size limits, allowing a large file (e.g., in a malicious repo) to cause Denial of Service.
**Learning:** Utility scripts scanning project structures must treat file contents as untrusted input and impose limits on resource usage (file size, recursion depth).
**Prevention:** Implement `MAX_FILE_SIZE` checks before opening files for analysis or dependency parsing.
